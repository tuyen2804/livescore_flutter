import 'dart:convert';
import 'dart:developer' as dev;

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/sofascore/sofascore_models.dart';
import 'sofascore_remote_data_source.dart';

/// Nối hai hệ ID: đội/giải bóng đá trong app đánh số theo **Sportmonks**
/// (SQLite đóng gói: 2.367 giải, 64.452 đội), Sofascore dùng hệ riêng. Không có
/// bảng ánh xạ nào tồn tại, nên phải dò bằng `search/all` rồi nhớ kết quả lại.
///
/// ## Cách dò đã được đo, không phải đoán
///
/// Thử trên 14 trận thật ngày 16/09/2026, tỷ lệ khớp **12/14**. Ba điều rút ra
/// từ các ca hỏng:
///
/// - **Phải so cả `slug`.** "CRB" có `name` = "Clube De Regatas Brasil" và
///   `nameCode` = "BRA" (!), chỉ `slug` = "crb" là khớp. Bỏ `slug` thì mất
///   nguyên một nhóm CLB Nam Mỹ.
/// - **Phiên âm hai nguồn khác nhau** — "Lokomotiv Moskva" ↔ "Lokomotiv
///   Moscow". Khớp chuỗi con thất bại, phải chấm theo **trùng token**.
/// - **Giữ nhiều ứng viên.** Một tên có thể ra 4 đội ("CRB" ra cả CRB Adrar
///   bên Algeria). Thay vì cố chọn đúng ngay, thử lần lượt và để **bước khớp
///   trận** làm trọng tài: chỉ nhận khi **cả hai đội** cùng khớp trong ±1 ngày.
///
/// Dò theo **tên giải** thì tệ hơn hẳn (2/12) vì tên giải đụng nhau khắp nơi —
/// "Premier League" của Nga ra giải Anh, "La Liga" ra một giải hạng dưới. Nên
/// tuyến chính luôn là **đội**, không phải giải.
class SofascoreIdResolver {
  SofascoreIdResolver(this._api);

  final SofascoreRemoteDataSource _api;

  static const String _keyPrefix = 'sofa_id_v3_';
  static const Duration _negativeTtl = Duration(days: 3);

  /// Số ứng viên thử tối đa cho mỗi lần dò trận.
  static const int _maxCandidates = 4;

  /// Hai nguồn có thể lệch múi giờ, nên nới ±1 ngày quanh giờ bóng lăn.
  static const int _dayWindowSeconds = 86400;

  final Map<String, List<int>> _memory = <String, List<int>>{};

  // ---------------------------------------------------------------- công khai

  /// Tên đội → `teamId` Sofascore khớp nhất.
  Future<int?> resolveTeam(String name, {String? country}) async {
    final list = await _teamCandidates(name, country: country);
    return list.isEmpty ? null : list.first;
  }

  /// Tên giải → `uniqueTournamentId`.
  ///
  /// Chỉ dùng cho màn chi tiết giải, nơi người dùng đã tự chọn giải nên nhầm
  /// lẫn ít hơn. Đừng dùng để dò trận — xem ghi chú ở đầu lớp.
  Future<int?> resolveTournament(String name, {String? country}) async {
    final list = await _search(
      kind: 'uniqueTournament',
      query: name,
      country: country,
    );
    return list.isEmpty ? null : list.first;
  }

  /// Tìm `eventId` Sofascore cho một trận của app.
  ///
  /// Đi vòng vì không có cách tra thẳng: dò đội nhà → duyệt lịch đã đá và sắp
  /// đá của đội đó → nhận trận cùng khung thời gian mà **đối thủ cũng khớp**.
  /// Yêu cầu khớp cả hai đội chính là thứ cho phép bước dò đội được nới lỏng.
  Future<int?> resolveEvent({
    required String homeName,
    required String awayName,
    required int kickoffEpochSeconds,
    String? country,
  }) async {
    final cacheKey = _eventKey(homeName, awayName, kickoffEpochSeconds);
    final cached = await _readCache(cacheKey);
    if (cached != null) return cached.ids.isEmpty ? null : cached.ids.first;

    // Đội nhà hỏng thì thử đội khách — vẫn khớp được vì bước sau không phân
    // biệt sân nhà / sân khách.
    for (final anchor in <String>[homeName, awayName]) {
      final opponent = anchor == homeName ? awayName : homeName;
      final teams = await _teamCandidates(anchor, country: country);

      for (final teamId in teams) {
        final events = await _teamEvents(teamId);
        final hit = _pickEvent(events, opponent, kickoffEpochSeconds);
        if (hit != null) {
          await _writeCache(cacheKey, <int>[hit]);
          dev.log('$homeName vs $awayName → event#$hit', name: 'SofaResolver');
          return hit;
        }
      }
    }

    dev.log('không dò được: $homeName vs $awayName', name: 'SofaResolver');
    await _writeCache(cacheKey, const <int>[]);
    return null;
  }

  // ------------------------------------------------------------------ nội bộ

  /// Lịch đã đá **trước**, rồi mới tới lịch sắp đá.
  ///
  /// Thứ tự này quan trọng: màn Prediction hay mở trận vừa kết thúc, mà những
  /// trận đó chỉ nằm ở `events/last`.
  Future<List<SofascoreEvent>> _teamEvents(int teamId) async {
    final out = <SofascoreEvent>[];
    for (final fetch in <Future<Map<String, dynamic>> Function()>[
      () => _api.getTeamLastEvents(teamId),
      () => _api.getTeamNextEvents(teamId),
    ]) {
      try {
        out.addAll(SofascoreResponses.events(await fetch()));
      } catch (e) {
        dev.log('lịch đội $teamId lỗi: $e', name: 'SofaResolver');
      }
    }
    return out;
  }

  int? _pickEvent(List<SofascoreEvent> events, String opponent, int epoch) {
    if (opponent.trim().isEmpty) return null;
    final want = _normalize(opponent);

    int? best;
    var bestGap = _dayWindowSeconds + 1;
    for (final e in events) {
      final gap = (e.startTimestamp - epoch).abs();
      if (gap > _dayWindowSeconds || gap >= bestGap) continue;
      // Không phân biệt nhà/khách: hai nguồn thỉnh thoảng đảo phía với trận
      // trên sân trung lập.
      final home = _normalize(e.homeTeam?.name ?? '');
      final away = _normalize(e.awayTeam?.name ?? '');
      if (_score(want, home) < 60 && _score(want, away) < 60) continue;
      bestGap = gap;
      best = e.id;
    }
    return best;
  }

  Future<List<int>> _teamCandidates(String name, {String? country}) =>
      _search(kind: 'team', query: name, country: country);

  Future<List<int>> _search({
    required String kind,
    required String query,
    String? country,
  }) async {
    final clean = query.trim();
    if (clean.length < 2) return const [];

    final key = '${kind}_'
        '${_normalize(clean, stripClub: kind == 'team')}_'
        '${_normalize(country ?? '', stripClub: false)}';
    final remembered = _memory[key];
    if (remembered != null) return remembered;

    final cached = await _readCache(key);
    if (cached != null) {
      _memory[key] = cached.ids;
      return cached.ids;
    }

    Map<String, dynamic> body;
    try {
      body = await _api.searchAll(clean);
    } catch (e) {
      // Lỗi mạng thì KHÔNG ghi cache âm — lần sau còn thử lại.
      dev.log('search "$clean" lỗi: $e', name: 'SofaResolver');
      return const [];
    }

    final ids = _rank(body, kind: kind, query: clean, country: country);
    _memory[key] = ids;
    await _writeCache(key, ids);
    return ids;
  }

  /// Xếp hạng ứng viên, trả tối đa [_maxCandidates] id theo điểm giảm dần.
  List<int> _rank(
    Map<String, dynamic> body, {
    required String kind,
    required String query,
    String? country,
  }) {
    final results = body['results'];
    if (results is! List) return const [];

    // Chỉ tên đội mới rút gọn hậu tố CLB; tên giải giữ nguyên.
    final stripClub = kind == 'team';
    String norm(String v) => _normalize(v, stripClub: stripClub);

    final want = norm(query);
    final wantCountry = _normalize(country ?? '', stripClub: false);
    final wantYouth = _youth.hasMatch(query.toLowerCase());

    // (điểm, số token thừa so với truy vấn, id)
    final scored = <(int, int, int)>[];

    for (final raw in results) {
      if (raw is! Map) continue;
      final row = Map<String, dynamic>.from(raw);
      if (row['type'] != kind) continue;

      final entity = row['entity'];
      if (entity is! Map) continue;
      final e = Map<String, dynamic>.from(entity);

      final id = e['id'];
      if (id is! int) continue;

      final sportSlug = _sportSlugOf(e);
      if (sportSlug.isNotEmpty && sportSlug != 'football') continue;

      final rawName = (e['name'] ?? '').toString();
      if (!wantYouth && _youth.hasMatch(rawName.toLowerCase())) continue;

      // Bốn cách viết tên, lấy cách nào khớp nhất. `slug` là quan trọng nhất
      // với CLB Nam Mỹ — `name` là tên đầy đủ dài ngoằng, `nameCode` có thể
      // sai hẳn (CRB có nameCode "BRA").
      var score = _score(want, norm(rawName));
      for (final field in const ['shortName', 'nameCode', 'slug']) {
        final value = e[field];
        if (value == null) continue;
        final s = _score(want, norm(value.toString()));
        if (s > score) score = s;
      }
      if (score < 40) continue;

      if (wantCountry.isNotEmpty) {
        final gotCountry = _normalize(_countryOf(e), stripClub: false);
        if (gotCountry.isNotEmpty) {
          score += gotCountry == wantCountry ? 40 : -45;
        }
      }
      if (score < 40) continue;

      scored.add((score, _extraTokens(want, norm(rawName)), id));
    }

    // Hoà điểm thì ưu tiên tên ít chữ thừa hơn. "Champions League" khớp 65
    // điểm cùng lúc với UEFA, CAF, OFC và "UEFA Women's Champions League";
    // cái cuối thừa 3 chữ nên rơi xuống. UEFA với CAF hoà nốt (đều thừa 1),
    // lúc đó `sort` ổn định của Dart giữ thứ tự Sofascore trả về — vốn xếp
    // theo độ phổ biến nên UEFA đứng trước.
    scored.sort((a, b) {
      final byScore = b.$1.compareTo(a.$1);
      return byScore != 0 ? byScore : a.$2.compareTo(b.$2);
    });
    return scored.take(_maxCandidates).map((e) => e.$3).toList(growable: false);
  }

  /// Số chữ trong tên ứng viên mà truy vấn không có.
  static int _extraTokens(String want, String got) {
    final a = want.split(' ').where((e) => e.isNotEmpty).toSet();
    final b = got.split(' ').where((e) => e.isNotEmpty).toSet();
    return b.difference(a).length;
  }

  /// Chấm độ giống giữa hai tên đã chuẩn hoá, 0–100.
  ///
  /// Nhánh cuối (trùng token) là thứ cứu các ca phiên âm lệch:
  /// "lokomotiv moskva" ∩ "lokomotiv moscow" = {lokomotiv} → 20 điểm,
  /// đủ để lọt vào danh sách ứng viên rồi để bước khớp trận quyết định.
  static int _score(String want, String got) {
    if (want.isEmpty || got.isEmpty) return 0;
    if (want == got) return 100;
    if (got.startsWith(want) || want.startsWith(got)) return 80;
    if (want.contains(got) || got.contains(want)) return 65;
    final a = want.split(' ').toSet();
    final b = got.split(' ').toSet();
    final union = a.union(b).length;
    if (union == 0) return 0;
    return (60 * a.intersection(b).length / union).round();
  }

  String _sportSlugOf(Map<String, dynamic> e) {
    final sport = e['sport'];
    if (sport is Map && sport['slug'] != null) {
      return _normalize(sport['slug'].toString());
    }
    final category = e['category'];
    if (category is Map && category['sport'] is Map) {
      final slug = (category['sport'] as Map)['slug'];
      if (slug != null) return _normalize(slug.toString());
    }
    return '';
  }

  String _countryOf(Map<String, dynamic> e) {
    final country = e['country'];
    if (country is Map && country['name'] != null) {
      return country['name'].toString();
    }
    final category = e['category'];
    if (category is Map) {
      final nested = category['country'];
      if (nested is Map && nested['name'] != null) {
        return nested['name'].toString();
      }
      if (category['name'] != null) return category['name'].toString();
    }
    return '';
  }

  // ------------------------------------------------------------------ cache

  /// Gộp theo **ngày** chứ không theo giây: giờ bóng lăn hai nguồn lệch nhau
  /// vài phút là chuyện thường, cache theo giây sẽ không bao giờ trúng.
  String _eventKey(String home, String away, int epoch) =>
      'event_${_normalize(home)}_${_normalize(away)}_${epoch ~/ 86400}';

  Future<_CacheHit?> _readCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$key');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ids = (map['ids'] as List?)?.whereType<int>().toList() ?? const [];
      if (ids.isNotEmpty) return _CacheHit(ids);

      // Kết quả rỗng chỉ giữ vài ngày: đội mới thăng hạng, giải mới mở sẽ xuất
      // hiện trên Sofascore sau đó.
      final at = map['at'];
      if (at is int) {
        final age = DateTime.now().millisecondsSinceEpoch - at;
        if (age < _negativeTtl.inMilliseconds) return const _CacheHit(<int>[]);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix$key',
      jsonEncode(<String, dynamic>{
        'ids': ids,
        'at': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  // ------------------------------------------------------------ chuẩn hoá tên

  static final RegExp _youth = RegExp(r'\bu-?\d{2}\b|\breserves?\b');

  /// Bỏ hậu tố loại hình CLB và giới từ. Không bỏ `b` đứng một mình — nhiều
  /// CLB Nam Mỹ có tên thật chứa chữ đó.
  static final RegExp _noise = RegExp(
    r'\b(fc|afc|cf|sc|ac|sv|cd|ud|as|ss|ssc|bk|if|aif|fk|nk|hk|club|team|de|of|the)\b',
  );
  static final RegExp _nonWord = RegExp(r'[^a-z0-9]+');

  /// Bỏ dấu, bỏ hậu tố, gộp khoảng trắng.
  ///
  /// Hai nguồn viết khác nhau ở mọi mức: `Mjällby` ↔ `Mjallby AIF`,
  /// `Atl. Madrid` ↔ `Atlético Madrid`, `CRB` ↔ `Clube De Regatas Brasil`.
  /// [stripClub] chỉ bật cho **tên đội**.
  ///
  /// [_noise] là danh sách hậu tố loại hình câu lạc bộ — `FC`, `AFC`
  /// (Association Football Club), `SC`, `CD`… Với tên **giải** thì đúng những
  /// chữ đó lại mang nghĩa khác hẳn: `AFC` là Liên đoàn bóng đá châu Á, `CAF`
  /// châu Phi, `OFC` châu Đại Dương. Đó chính là chữ phân biệt các giải trùng
  /// tên, cắt đi là chọn nhầm giải — xem ghi chú ở [_rank].
  static String _normalize(String input, {bool stripClub = true}) {
    var s = input.toLowerCase();
    _diacritics.forEach((from, to) => s = s.replaceAll(from, to));
    s = s.replaceAll(_nonWord, ' ');
    if (stripClub) s = s.replaceAll(_noise, ' ');
    return s.split(' ').where((e) => e.isNotEmpty).join(' ');
  }

  static const Map<String, String> _diacritics = <String, String>{
    'á': 'a', 'à': 'a', 'ả': 'a', 'ã': 'a', 'ạ': 'a', 'â': 'a', 'ă': 'a',
    'ä': 'a', 'å': 'a', 'æ': 'ae', 'ā': 'a',
    'é': 'e', 'è': 'e', 'ẻ': 'e', 'ẽ': 'e', 'ẹ': 'e', 'ê': 'e', 'ë': 'e',
    'ē': 'e',
    'í': 'i', 'ì': 'i', 'ỉ': 'i', 'ĩ': 'i', 'ị': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ỏ': 'o', 'õ': 'o', 'ọ': 'o', 'ô': 'o', 'ơ': 'o',
    'ö': 'o', 'ø': 'o', 'ō': 'o',
    'ú': 'u', 'ù': 'u', 'ủ': 'u', 'ũ': 'u', 'ụ': 'u', 'û': 'u', 'ü': 'u',
    'ư': 'u', 'ū': 'u',
    'ý': 'y', 'ỳ': 'y', 'ỷ': 'y', 'ỹ': 'y', 'ỵ': 'y', 'ÿ': 'y',
    'đ': 'd', 'ð': 'd', 'ñ': 'n', 'ç': 'c', 'ß': 'ss', 'š': 's', 'ś': 's',
    'ž': 'z', 'ź': 'z', 'ż': 'z', 'č': 'c', 'ć': 'c', 'ř': 'r', 'ł': 'l',
    'ğ': 'g', 'ı': 'i', 'ş': 's', 'ť': 't', 'ň': 'n', 'ě': 'e', 'ů': 'u',
  };
}

class _CacheHit {
  const _CacheHit(this.ids);
  final List<int> ids;
}
