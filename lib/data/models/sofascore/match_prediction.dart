import 'dart:developer' as dev;

/// Dữ liệu màn Prediction, lấy từ Sofascore.
///
/// Thay cho `match-forecast-new` của backend cũ — endpoint đó hỏng hoàn toàn
/// (xem `docs/API_dang_su_dung.md` §1.6). Ba nguồn, ba mức tin cậy khác nhau và
/// **hiển thị tách bạch**, không trộn vào nhau:
///
/// | Nguồn | Endpoint | Có trước trận? |
/// |---|---|---|
/// | Cộng đồng bình chọn | `event/{id}/votes` | có, mọi trận |
/// | Xác suất theo nhà cái | `event/{id}/odds/1/all` | có, phần lớn trận |
/// | Phân tích AI | `event/{id}/ai-insights-postmatch/{lang}` | **không** — chỉ sau trận |
///
/// Bản AI trước trận (`ai-insights/{lang}`) trả 403 `jwt:token-not-present`,
/// cần tài khoản Sofascore nên không dùng được.
class MatchPrediction {
  const MatchPrediction({
    this.communityVote,
    this.firstGoalVote,
    this.bothTeamsToScoreVote,
    this.odds,
    this.markets = const [],
    this.ai,
  });

  /// `votes.vote` — thắng / hoà / thua theo phiếu người dùng Sofascore.
  final VoteSplit? communityVote;

  /// `votes.firstTeamToScoreVote` — nhà / không bàn nào / khách.
  final VoteSplit? firstGoalVote;

  /// `votes.bothTeamsToScoreVote`.
  final YesNoVote? bothTeamsToScoreVote;

  /// Suy từ kèo 1X2, đã chuẩn hoá về tổng 100%.
  final OddsProbability? odds;

  /// Các kèo còn lại, đã quy về phần trăm.
  ///
  /// `event/{id}/odds/1/all` trả **17 market** cho một trận sắp đá: kèo châu Á,
  /// tài xỉu bàn thắng 8 mức, thẻ phạt, phạt góc, đội ghi bàn trước… Trước đây
  /// chỉ đọc mỗi 1X2 nên màn dự đoán gần như trống trước giờ bóng lăn, trong
  /// khi đó chính là lúc người ta vào xem.
  final List<OddsMarket> markets;

  /// Chỉ có khi trận đã đá xong.
  final AiInsight? ai;

  bool get isEmpty =>
      communityVote == null &&
      firstGoalVote == null &&
      bothTeamsToScoreVote == null &&
      odds == null &&
      markets.isEmpty &&
      ai == null;

  factory MatchPrediction.from({
    Map<String, dynamic>? votes,
    Map<String, dynamic>? odds,
    Map<String, dynamic>? aiInsights,
  }) =>
      MatchPrediction(
        communityVote: VoteSplit.fromVote(_obj(votes?['vote'])),
        firstGoalVote:
            VoteSplit.fromFirstGoal(_obj(votes?['firstTeamToScoreVote'])),
        bothTeamsToScoreVote:
            YesNoVote.fromJson(_obj(votes?['bothTeamsToScoreVote'])),
        odds: OddsProbability.fromMarkets(odds?['markets']),
        ai: AiInsight.fromJson(aiInsights),
      );
}

/// Ba lựa chọn, giữ **số phiếu thật** chứ không chỉ phần trăm — màn hình hiện
/// cả tổng lượt bình chọn để người đọc tự đánh giá độ tin.
class VoteSplit {
  const VoteSplit({
    required this.home,
    required this.middle,
    required this.away,
  });

  final int home;

  /// Hoà (ở `communityVote`) hoặc "không đội nào ghi bàn" (ở `firstGoalVote`).
  final int middle;
  final int away;

  int get total => home + middle + away;

  /// Làm tròn sao cho ba số cộng lại đúng 100 — chia thẳng rồi round sẽ ra
  /// 33/33/33 hoặc 34/33/34 tuỳ số, nhìn là thấy sai.
  List<int> get percents {
    final t = total;
    if (t == 0) return const [0, 0, 0];
    final h = (home * 100 / t).round();
    final m = (middle * 100 / t).round();
    return [h, m, 100 - h - m];
  }

  static VoteSplit? fromVote(Map<String, dynamic>? j) {
    if (j == null) return null;
    final v = VoteSplit(
      home: _int(j['vote1']) ?? 0,
      middle: _int(j['voteX']) ?? 0,
      away: _int(j['vote2']) ?? 0,
    );
    return v.total == 0 ? null : v;
  }

  static VoteSplit? fromFirstGoal(Map<String, dynamic>? j) {
    if (j == null) return null;
    final v = VoteSplit(
      home: _int(j['voteHome']) ?? 0,
      middle: _int(j['voteNoGoal']) ?? 0,
      away: _int(j['voteAway']) ?? 0,
    );
    return v.total == 0 ? null : v;
  }
}

class YesNoVote {
  const YesNoVote({required this.yes, required this.no});

  final int yes;
  final int no;

  int get total => yes + no;
  int get yesPercent => total == 0 ? 0 : (yes * 100 / total).round();

  static YesNoVote? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final v = YesNoVote(
      yes: _int(j['voteYes']) ?? 0,
      no: _int(j['voteNo']) ?? 0,
    );
    return v.total == 0 ? null : v;
  }
}

/// Xác suất ngầm của nhà cái, đã bỏ phần biên lợi nhuận.
///
/// Sofascore trả kèo dạng **phân số Anh** (`"1/10"`, `"8/1"`), không phải số
/// thập phân. Quy đổi: `decimal = tử/mẫu + 1`, `p = 1/decimal`. Tổng ba p luôn
/// lớn hơn 1 (đó là phần lãi của nhà cái) nên phải chuẩn hoá lại.
class OddsProbability {
  const OddsProbability({
    required this.home,
    required this.draw,
    required this.away,
  });

  final int home;
  final int draw;
  final int away;

  static OddsProbability? fromMarkets(Object? markets) {
    if (markets is! List) return null;

    Map<String, dynamic>? fullTime;
    for (final raw in markets) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      // `marketId == 1` là 1X2 toàn trận; tên hiển thị đổi theo ngôn ngữ nên
      // không so theo `marketName`.
      if (_int(m['marketId']) == 1) {
        fullTime = m;
        break;
      }
    }
    if (fullTime == null) return null;
    if (fullTime['suspended'] == true) return null;

    final choices = fullTime['choices'];
    if (choices is! List) return null;

    final raw = <String, double>{};
    for (final c in choices) {
      if (c is! Map) continue;
      final name = c['name']?.toString();
      final decimal = _fractionalToDecimal(c['fractionalValue']?.toString());
      if (name == null || decimal == null || decimal <= 1.0) continue;
      raw[name] = 1 / decimal;
    }

    final h = raw['1'], d = raw['X'], a = raw['2'];
    if (h == null || d == null || a == null) return null;

    final sum = h + d + a;
    if (sum <= 0) return null;

    final ph = (h / sum * 100).round();
    final pd = (d / sum * 100).round();
    return OddsProbability(home: ph, draw: pd, away: 100 - ph - pd);
  }

  /// `"1/10"` → 1.1 · `"8/1"` → 9.0 · `"evens"`/`"1/1"` → 2.0
  static double? _fractionalToDecimal(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.toLowerCase() == 'evens' || value.toLowerCase() == 'evs') {
      return 2.0;
    }
    final parts = value.split('/');
    if (parts.length != 2) return double.tryParse(value);
    final num = double.tryParse(parts[0]);
    final den = double.tryParse(parts[1]);
    if (num == null || den == null || den == 0) return null;
    return num / den + 1;
  }
}

/// Một kèo bất kỳ, đã quy từ tỷ lệ phân số sang phần trăm.
class OddsMarket {
  const OddsMarket({
    required this.id,
    required this.name,
    required this.choices,
    this.group,
  });

  /// `marketId` của Sofascore — ổn định hơn `marketName` vốn đổi theo ngôn ngữ.
  final int id;
  final String name;

  /// Mức của kèo, ví dụ `"2.5"` với tài xỉu bàn thắng.
  final String? group;
  final List<OddsChoice> choices;

  /// Cửa có xác suất cao nhất.
  OddsChoice? get best => choices.isEmpty
      ? null
      : choices.reduce((a, b) => a.percent >= b.percent ? a : b);

  static List<OddsMarket> listFrom(Object? raw) {
    if (raw is! List) return const [];
    final out = <OddsMarket>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      if (m['suspended'] == true) continue;

      final id = _int(m['marketId']);
      final choices = m['choices'];
      if (id == null || choices is! List) continue;

      final raws = <String, double>{};
      for (final c in choices) {
        if (c is! Map) continue;
        final name = c['name']?.toString();
        final decimal =
            OddsProbability._fractionalToDecimal(c['fractionalValue']?.toString());
        if (name == null || decimal == null || decimal <= 1.0) continue;
        raws[name] = 1 / decimal;
      }
      if (raws.length < 2) continue;

      final sum = raws.values.reduce((a, b) => a + b);
      if (sum <= 0) continue;

      out.add(OddsMarket(
        id: id,
        name: m['marketName']?.toString() ?? '',
        group: m['choiceGroup']?.toString(),
        choices: [
          for (final e in raws.entries)
            OddsChoice(name: e.key, percent: (e.value / sum * 100).round()),
        ],
      ));
    }
    return out;
  }

  /// Tìm kèo theo id, kèm mức nếu cần (`"2.5"` cho tài xỉu bàn thắng).
  static OddsMarket? find(List<OddsMarket> all, int id, {String? group}) {
    for (final m in all) {
      if (m.id != id) continue;
      if (group != null && m.group != group) continue;
      return m;
    }
    return null;
  }
}

class OddsChoice {
  const OddsChoice({required this.name, required this.percent});

  final String name;
  final int percent;
}

/// `ai-insights-postmatch/{lang}` — chỉ tồn tại sau khi trận kết thúc.
class AiInsight {
  const AiInsight({
    this.winProbability,
    this.homeScore,
    this.awayScore,
    this.corners,
    this.yellowCards,
    this.bothTeamsToScore,
    this.sections = const [],
  });

  final OddsProbability? winProbability;
  final int? homeScore;
  final int? awayScore;

  /// **Tổng** phạt góc của cả trận, không tách theo đội — khác backend cũ
  /// vốn trả `corner {home, away}`.
  final int? corners;
  final int? yellowCards;
  final bool? bothTeamsToScore;

  /// Các đoạn phân tích, đã dịch theo `{lang}` gọi kèm.
  final List<AiSection> sections;

  int? get totalGoals =>
      homeScore == null || awayScore == null ? null : homeScore! + awayScore!;

  bool get isEmpty =>
      winProbability == null &&
      homeScore == null &&
      corners == null &&
      sections.isEmpty;

  static AiInsight? fromJson(Map<String, dynamic>? j) {
    if (j == null || j.isEmpty) return null;
    final p = _obj(j['predictions']);
    final wp = _obj(p?['winningProbability']);

    final insight = AiInsight(
      winProbability: wp == null
          ? null
          : OddsProbability(
              home: _int(wp['home']) ?? 0,
              draw: _int(wp['draw']) ?? 0,
              away: _int(wp['away']) ?? 0,
            ),
      homeScore: _int(p?['homeNormaltimeScore']),
      awayScore: _int(p?['awayNormaltimeScore']),
      corners: _int(p?['corners']),
      yellowCards: _int(p?['yellowCards']),
      bothTeamsToScore: p?['bothTeamsToScore'] is bool
          ? p!['bothTeamsToScore'] as bool
          : null,
      sections: AiSection.listFrom(j['sections']),
    );
    return insight.isEmpty ? null : insight;
  }
}

class AiSection {
  const AiSection({required this.subtitle, required this.text});

  final String subtitle;
  final String text;

  static List<AiSection> listFrom(Object? raw) {
    if (raw is! List) return const [];
    final out = <AiSection>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final text = item['text']?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      out.add(AiSection(
        subtitle: item['subtitle']?.toString().trim() ?? '',
        text: text,
      ));
    }
    return out;
  }
}

/// Ngôn ngữ app → mã Sofascore chấp nhận cho `ai-insights-postmatch`.
///
/// Thử thật: `en`, `vi`, `es` đều trả 200 và **dịch thật** (bản `vi` dài 13.249
/// byte so với `en` 7.472). Mã lạ thì server trả 404 nên phải lọc trước.
String sofascoreInsightLanguage(String appLanguageCode) {
  const supported = <String>{
    'en', 'vi', 'es', 'pt', 'fr', 'de', 'it', 'tr', 'ru', 'id', 'th',
    'ar', 'hi', 'ja', 'ko', 'pl', 'nl',
  };
  final code = appLanguageCode.toLowerCase().split(RegExp('[_-]')).first;
  if (supported.contains(code)) return code;
  dev.log('ngôn ngữ "$appLanguageCode" không có bản dịch, dùng en',
      name: 'Prediction');
  return 'en';
}

Map<String, dynamic>? _obj(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

int? _int(Object? v) =>
    v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));
