import 'dart:async';

import '../../core/error/failures.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/match_status.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/sport_presentation.dart';
import '../../data/datasources/local/app_prefs.dart';
import '../../data/datasources/local/league_db_helper.dart';
import '../../data/mappers/sofascore_mapper.dart';
import '../../data/models/local/db_entities.dart';
import '../../data/models/sofascore/sofascore_models.dart';
import '../../data/repositories/sofascore_repository_impl.dart';
import '../../domain/entities/event_list_item.dart';
import '../../domain/entities/match_entities.dart';
import '../../domain/repositories/football_repository.dart';
import 'base_provider.dart';

/// Port `presentation/home/HomeViewModel.kt`.
/// Bóng đá đi qua [FootballRepository] (API riêng), mọi môn khác đi qua
/// [SofascoreRepositoryImpl] — đúng như bản gốc.
class HomeProvider extends BaseProvider {
  HomeProvider(this._football, this._sofascore, this._prefs, this._db) {
    _selectedSport = _prefs.selectedSport;
    unawaited(loadSportCounts());
    unawaited(fetchDataForSelectedDate());
  }

  final FootballRepository _football;
  final SofascoreRepositoryImpl _sofascore;
  final AppPrefs _prefs;
  final LeagueDbHelper _db;

  /// Cache feed theo (môn, ngày) — port `HomeFeedMemoryCache`.
  final Map<String, List<EventListItem>> _feedCache = {};

  DateTime _selectedDate = DateTime.now();
  String _selectedSport = AppPrefs.defaultSport;
  bool _isLoading = false;
  Failure? _failure;

  List<LeagueSection> _leagueSections = const [];
  List<LiveMatch> _liveMatches = const [];
  List<LiveMatch> _allLiveMatches = const [];
  List<EventListItem> _feedItems = const [];
  Map<String, SportEventCount> _sportEventCounts = const {};
  Set<int> _notifiedIds = const {};

  DateTime get selectedDate => _selectedDate;
  String get selectedSport => _selectedSport;
  bool get isLoading => _isLoading;
  Failure? get failure => _failure;
  List<LeagueSection> get leagueSections => _leagueSections;

  /// Bản gốc chỉ hiện tối đa 5 thẻ live ở carousel.
  List<LiveMatch> get liveMatches => _liveMatches;
  List<LiveMatch> get allLiveMatches => _allLiveMatches;
  List<EventListItem> get feedItems => _feedItems;
  Map<String, SportEventCount> get sportEventCounts => _sportEventCounts;
  Set<int> get notifiedIds => _notifiedIds;

  bool get isFootball => _selectedSport.toLowerCase() == 'football';
  bool get isEmpty => _leagueSections.isEmpty && _feedItems.isEmpty;

  /// Dải 7 ngày quanh ngày đang chọn cho thanh chọn ngày.
  List<DateTime> get dateStrip {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    return [for (var i = -3; i <= 3; i++) base.add(Duration(days: i))];
  }

  Future<void> loadSportCounts() async {
    final result = await _sofascore.getSportEventCounts();
    result.fold(
      (_) {},
      (counts) => setState(() => _sportEventCounts = counts),
    );
  }

  void changeDateByAmount(int amount) {
    _selectedDate = _selectedDate.add(Duration(days: amount));
    notifyListeners();
    unawaited(fetchDataForSelectedDate());
  }

  void setDate(DateTime date) {
    if (DateTimeUtils.isSameDay(date, _selectedDate)) return;
    _selectedDate = date;
    notifyListeners();
    unawaited(fetchDataForSelectedDate());
  }

  Future<void> setSport(String sportSlug) async {
    if (_selectedSport == sportSlug) return;
    _selectedSport = sportSlug;
    await _prefs.setSelectedSport(sportSlug);
    notifyListeners();
    await fetchDataForSelectedDate();
  }

  Future<void> refreshData() => fetchDataForSelectedDate();

  Future<void> fetchDataForSelectedDate() async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    _notifiedIds = await _db.getNotifiedFixtureIds();

    if (isFootball) {
      await _fetchFootball();
    } else {
      await _fetchSofascore();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _fetchFootball() async {
    final result = await _football.getLeagueLive(_selectedDate);
    result.fold(
      (failure) => setState(() {
        _failure = failure;
        _leagueSections = const [];
        _liveMatches = const [];
        _allLiveMatches = const [];
        _feedItems = const [];
      }),
      (sections) {
        final live = _extractFootballLive(sections);
        setState(() {
          _leagueSections = sections;
          _allLiveMatches = live;
          _liveMatches = live.take(5).toList(growable: false);
          _feedItems = const [];
        });
      },
    );
  }

  /// Port đoạn dựng `allLiveList` trong `processMatches`:
  /// nhãn thời gian là HT/AET/PEN, còn lại là `playingTime` kèm dấu phẩy trên.
  List<LiveMatch> _extractFootballLive(List<LeagueSection> sections) {
    final result = <LiveMatch>[];
    for (final section in sections) {
      for (final f in section.fixtures) {
        if (!f.isLive) continue;
        result.add(LiveMatch(
          id: f.id,
          teamHome: f.teamHome,
          teamAway: f.teamAway,
          scoreHome: f.scoreHome ?? 0,
          scoreAway: f.scoreAway ?? 0,
          matchTime: MatchStatus.liveLabel(f.state, f.playingTime),
          leagueName: section.leagueName,
          homeLogoUrl: f.homeLogoUrl,
          awayLogoUrl: f.awayLogoUrl,
          leagueLogoUrl: section.leagueLogoUrl,
          venue: null,
          region: f.categoryName,
        ));
      }
    }
    return result;
  }

  Future<void> _fetchSofascore() async {
    final key = '$_selectedSport@${DateTimeUtils.apiDate(_selectedDate)}';

    // Hiện cache trước cho khỏi trắng màn, đúng như HomeFeedMemoryCache.
    final cached = _feedCache[key];
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _feedItems = cached;
        _leagueSections = SofascoreMapper.toLeagueSections(cached, _selectedSport);
        _allLiveMatches = SofascoreMapper.toLiveMatches(cached);
        _liveMatches = _allLiveMatches.take(5).toList(growable: false);
        _isLoading = false;
      });
    }

    final result = await _sofascore.loadFeed(
      sportSlug: _selectedSport,
      date: _selectedDate,
    );

    result.fold(
      (failure) {
        if (cached != null) return;
        setState(() {
          _failure = failure;
          _feedItems = const [];
          _leagueSections = const [];
          _liveMatches = const [];
          _allLiveMatches = const [];
        });
      },
      (items) {
        _feedCache[key] = items;
        final live = SofascoreMapper.toLiveMatches(items);
        setState(() {
          _feedItems = items;
          _leagueSections =
              SofascoreMapper.toLeagueSections(items, _selectedSport);
          _allLiveMatches = live;
          _liveMatches = live.take(5).toList(growable: false);
        });
      },
    );
  }

  bool isNotificationEnabled(String fixtureId) =>
      _notifiedIds.contains(int.tryParse(fixtureId) ?? -1);

  /// Port `HomeViewModel.toggleNotification`.
  Future<void> toggleNotification(
    MatchFixture match,
    NotificationService notifications, {
    int beforeMatchMinutes = 15,
    bool notifyMatchStart = true,
    bool notifyEndFirstHalf = true,
    bool notifyStartSecondHalf = false,
    bool notifyEndMatch = false,
  }) async {
    final id = int.tryParse(match.id);
    if (id == null) return;

    final item = NotificationDbItem(
      id: id,
      homeName: match.teamHome,
      awayName: match.teamAway,
      homeLogoUrl: match.homeLogoUrl,
      awayLogoUrl: match.awayLogoUrl,
      leagueName: match.leagueName,
      timeStr: match.kickoffUtc,
      status: match.status,
      sportSlug: match.sportSlug,
      beforeMatchMinutes: beforeMatchMinutes,
      notifyMatchStart: notifyMatchStart,
      notifyEndFirstHalf: notifyEndFirstHalf,
      notifyStartSecondHalf: notifyStartSecondHalf,
      notifyEndMatch: notifyEndMatch,
    );

    final wasEnabled = await _db.isNotificationEnabled(id);
    await _db.toggleNotification(item);
    if (wasEnabled) {
      await notifications.cancel(id);
    } else {
      await notifications.schedule(item);
    }

    _notifiedIds = await _db.getNotifiedFixtureIds();
    _applyNotifiedFlags();
    notifyListeners();
  }

  /// Port nhánh `onNotiClick` cho các item Sofascore của `HomeFragment`:
  /// dựng `NotificationItem` từ event / chặng đua / tổ chức rồi bật-tắt.
  Future<void> toggleEventNotification(
    EventListItem item,
    NotificationService notifications, {
    int beforeMatchMinutes = 15,
    bool notifyMatchStart = true,
    bool notifyEndFirstHalf = true,
    bool notifyStartSecondHalf = false,
    bool notifyEndMatch = false,
  }) async {
    final dbItem = switch (item) {
      MatchItem(:final event) => NotificationDbItem(
          id: event.id,
          homeName: event.homeTeam?.name ?? event.name ?? 'Home',
          awayName: event.awayTeam?.name ?? 'Away',
          homeLogoUrl: event.homeTeam?.logoUrl,
          awayLogoUrl: event.awayTeam?.logoUrl,
          leagueName: event.tournament?.name,
          leagueLogoUrl: event.tournament?.uniqueTournament?.logoUrl,
          timeStr: event.startTimestamp.toString(),
          status: event.status?.description,
          sportSlug: _selectedSport,
        ),
      StageSeriesItem(:final uniqueStage) => NotificationDbItem(
          id: uniqueStage.id,
          homeName: uniqueStage.name ?? '',
          awayName: uniqueStage.category?.name ?? 'Series',
          leagueName: uniqueStage.name,
          leagueLogoUrl: uniqueStage.logoUrl,
          sportSlug: _selectedSport,
        ),
      StageRaceItem(:final stage) || CyclingRaceItem(:final stage) =>
        NotificationDbItem(
          id: stage.id,
          homeName: stage.name ?? stage.description ?? '',
          awayName: stage.country?.name ?? 'Race',
          leagueName: stage.uniqueStage?.name,
          timeStr: stage.startDateTimestamp?.toString(),
          sportSlug: _selectedSport,
        ),
      OrganisationItem(:final uniqueTournament) => NotificationDbItem(
          id: uniqueTournament.id,
          homeName: uniqueTournament.name,
          awayName: uniqueTournament.category?.name ?? '',
          leagueName: uniqueTournament.name,
          leagueLogoUrl: uniqueTournament.logoUrl,
          sportSlug: _selectedSport,
        ),
      _ => null,
    };
    if (dbItem == null) return;

    final item2 = NotificationDbItem(
      id: dbItem.id,
      homeName: dbItem.homeName,
      awayName: dbItem.awayName,
      homeLogoUrl: dbItem.homeLogoUrl,
      awayLogoUrl: dbItem.awayLogoUrl,
      leagueName: dbItem.leagueName,
      leagueLogoUrl: dbItem.leagueLogoUrl,
      timeStr: dbItem.timeStr,
      status: dbItem.status,
      sportSlug: dbItem.sportSlug,
      beforeMatchMinutes: beforeMatchMinutes,
      notifyMatchStart: notifyMatchStart,
      notifyEndFirstHalf: notifyEndFirstHalf,
      notifyStartSecondHalf: notifyStartSecondHalf,
      notifyEndMatch: notifyEndMatch,
    );

    final wasEnabled = await _db.isNotificationEnabled(item2.id);
    await _db.toggleNotification(item2);
    if (wasEnabled) {
      await notifications.cancel(item2.id);
    } else {
      await notifications.schedule(item2);
    }

    _notifiedIds = await _db.getNotifiedFixtureIds();
    notifyListeners();
  }

  void _applyNotifiedFlags() {
    _leagueSections = _leagueSections
        .map((s) => s.copyWith(
              fixtures: s.fixtures
                  .map((f) => f.copyWith(isNotified: isNotificationEnabled(f.id)))
                  .toList(growable: false),
            ))
        .toList(growable: false);
  }

  /// Bản gốc hiện đủ danh sách môn cố định, số trận chỉ là nhãn phụ.
  List<String> get availableSports => SportPresentation.sportPickerOrder;

  int liveCountFor(String slug) => _sportEventCounts[slug]?.live ?? 0;
  int totalCountFor(String slug) => _sportEventCounts[slug]?.total ?? 0;
}
