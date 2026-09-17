import '../../core/error/failures.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/datasources/local/league_db_helper.dart';
import '../../data/models/football/football_models.dart';
import '../../data/models/sofascore/match_prediction.dart';
import '../../data/repositories/football_sofascore_repository.dart';
import '../../domain/entities/match_entities.dart';
import 'base_provider.dart';

/// BXH + lịch thi đấu của một giải.
///
/// **Nguồn đã đổi sang Sofascore.** Backend cũ nhận `league_id` hệ Sportmonks;
/// Sofascore không biết hệ đó nên phải dò theo **tên giải + quốc gia** —
/// xem [SofascoreIdResolver]. Quốc gia là bắt buộc khi có, vì "Serie B" tồn
/// tại ở cả Brazil lẫn Ý.
class LeagueDetailProvider extends BaseProvider {
  LeagueDetailProvider(this._sofa);

  final FootballSofascoreRepository _sofa;

  List<StandingTeamDto> _standings = const [];
  List<UpcomingFixtureDto> _fixtures = const [];
  bool _isLoading = false;
  Failure? _failure;

  List<StandingTeamDto> get standings => _standings;
  List<UpcomingFixtureDto> get fixtures => _fixtures;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;

  Future<void> load(String leagueName, {String? countryName}) async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final result = await _sofa.getLeagueDetail(
      leagueName: leagueName,
      country: countryName,
    );
    result.fold(
      (f) => _failure = f,
      (bundle) {
        _standings = bundle.standings;
        _fixtures = bundle.fixtures;
      },
    );

    setState(() => _isLoading = false);
  }
}

/// Lịch thi đấu + đội hình của một đội.
///
/// **Nguồn đã đổi sang Sofascore.** Được thêm `playerId` thật trong đội hình —
/// thứ `list-player` của backend cũ không trả, nên trước đây màn chi tiết cầu
/// thủ chỉ là thẻ tĩnh. Mất `weight` vì Sofascore không có cân nặng.
class TeamDetailProvider extends BaseProvider {
  TeamDetailProvider(this._sofa, this._db);

  final FootballSofascoreRepository _sofa;
  final LeagueDbHelper _db;

  List<FixtureListItem> _items = const [];
  List<SquadPlayerDto> _squad = const [];
  bool _isLoading = false;
  bool _isFavorite = false;
  String _teamName = '';
  String? _teamLogo;
  Failure? _failure;

  List<FixtureListItem> get items => _items;
  List<SquadPlayerDto> get squad => _squad;
  bool get isLoading => _isLoading;
  bool get isFavorite => _isFavorite;
  String get teamName => _teamName;
  String? get teamLogo => _teamLogo;
  Failure? get failure => _failure;

  Future<void> load(int teamId) async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    // Tên đội vẫn lấy từ SQLite đóng gói (hệ Sportmonks) — đó là thứ duy nhất
    // nối được `teamId` của app với Sofascore, vì hai hệ ID không chung nhau.
    final team = await _db.getTeamById(teamId);
    if (team != null) {
      _teamName = team.name;
      _teamLogo = team.imagePath;
      _isFavorite = team.isFavourite;
    }

    if (_teamName.isEmpty) {
      setState(() {
        _isLoading = false;
        _failure = const ServerFailure('Không tìm thấy đội trong dữ liệu app');
      });
      return;
    }

    final result = await _sofa.getTeamDetail(teamName: _teamName);
    result.fold(
      (f) => _failure = f,
      (bundle) {
        _items = _group(bundle.fixtures);
        _squad = bundle.squad;
        // Logo Sofascore nét hơn và luôn có; giữ logo cũ làm dự phòng.
        _teamLogo = bundle.logoUrl;
      },
    );

    setState(() => _isLoading = false);
  }

  /// Gom theo giải, chèn header — port `FixtureListItem` của bản gốc.
  List<FixtureListItem> _group(List<FavoriteFixtureDto> list) {
    final byLeague = <String, List<FavoriteFixtureDto>>{};
    final logos = <String, String?>{};
    for (final f in list) {
      byLeague.putIfAbsent(f.leagueName, () => <FavoriteFixtureDto>[]).add(f);
      logos[f.leagueName] ??= f.leagueLogoUrl;
    }

    final items = <FixtureListItem>[];
    for (final entry in byLeague.entries) {
      items.add(FixtureHeaderItem(entry.key, logos[entry.key]));
      for (final f in entry.value) {
        items.add(FixtureRowItem(Fixture(
          id: '${f.id}',
          homeTeamName: f.homeName,
          homeTeamLogo: f.homeLogoUrl ?? '',
          awayTeamName: f.awayName,
          awayTeamLogo: f.awayLogoUrl ?? '',
          time: DateTimeUtils.convertUtcToLocalTime(f.startingAt),
          date: DateTimeUtils.convertUtcToLocalDate(f.startingAt),
          leagueName: f.leagueName,
        )));
      }
    }
    return items;
  }

  Future<void> toggleFavorite(int teamId) async {
    await _db.toggleTeamFavourite(teamId);
    final team = await _db.getTeamById(teamId);
    setState(() => _isFavorite = team?.isFavourite ?? false);
  }
}

/// Màn dự đoán trận.
///
/// **Nguồn đã đổi sang Sofascore.** `match-forecast-new` của backend cũ hỏng
/// 100% (xem `docs/API_dang_su_dung.md` §1.6), thay bằng ba nguồn tách bạch:
/// bình chọn cộng đồng, xác suất suy từ kèo, và phân tích AI sau trận.
class MatchForecastProvider extends BaseProvider {
  MatchForecastProvider(this._sofa);

  final FootballSofascoreRepository _sofa;

  MatchPrediction? _prediction;
  bool _isLoading = false;
  Failure? _failure;

  MatchPrediction? get prediction => _prediction;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;

  /// [matchId] chính là `eventId` Sofascore — feed Home đã đổi nguồn nên
  /// không còn phải dò theo tên đội.
  Future<void> load({
    required int matchId,
    String languageCode = 'en',
  }) async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    final result = await _sofa.getMatchBundleByEvent(
      matchId,
      languageCode: languageCode,
      withStandings: false,
    );
    result.fold(
      (f) => _failure = f,
      (bundle) => _prediction = bundle.prediction,
    );

    setState(() => _isLoading = false);
  }
}

/// Hồ sơ cầu thủ từ Sofascore.
///
/// Màn cũ chỉ dựng thẻ tĩnh từ arguments vì `list-player` của backend cũ không
/// trả id cầu thủ — dòng "Prefer foot" vì thế luôn là "-". Có `playerId` rồi
/// thì lấy được chân thuận, giá trị chuyển nhượng, hạn hợp đồng, CLB hiện tại.
///
/// Không có `playerId` (đội hình đến từ nguồn cũ) thì provider im lặng không
/// gọi gì, màn hình vẫn hiện đúng như trước.
class PlayerDetailProvider extends BaseProvider {
  PlayerDetailProvider(this._sofa);

  final FootballSofascoreRepository _sofa;

  PlayerProfile? _profile;
  bool _isLoading = false;

  PlayerProfile? get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> load(int? playerId) async {
    if (playerId == null || playerId <= 0) return;
    setState(() => _isLoading = true);
    final result = await _sofa.getPlayerProfile(playerId);
    result.fold(
      (_) {},
      (data) => _profile = data,
    );
    setState(() => _isLoading = false);
  }
}
