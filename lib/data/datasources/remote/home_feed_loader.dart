import 'dart:developer' as dev;

import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/sport_presentation.dart';
import '../../../domain/entities/event_list_item.dart';
import '../../models/sofascore/sofascore_models.dart';
import '../local/app_prefs.dart';
import 'sofascore_remote_data_source.dart';

/// Port 1:1 của `data/sofascore/HomeFeedLoader.kt`.
/// Gom nhiều lời gọi Sofascore thành một danh sách phẳng cho RecyclerView/ListView.
class HomeFeedLoader {
  HomeFeedLoader(this._api, this._prefs, {this.userCountryCode = 'VN'});

  final SofascoreRemoteDataSource _api;
  final AppPrefs _prefs;
  final String userCountryCode;

  static const String _tag = 'SOFASCORE_LOG';
  static const Duration _primaryTimeout = Duration(milliseconds: 5000);
  static const Duration _optionalTimeout = Duration(milliseconds: 3000);
  static const Duration _categoryEventsTimeout = Duration(milliseconds: 5000);
  static const Duration _tournamentEventsTimeout = Duration(milliseconds: 5000);
  static const Duration _cyclingExtendedTimeout = Duration(milliseconds: 12000);
  static const int _maxPinnedFallbackTournaments = 8;
  static const int _maxInitialCategoryRequests = 8;

  /// Hạn mức trang cho feed ngày.
  ///
  /// Ngày thường 4 trang, thứ Bảy lên tới 35. Mỗi trang ~700 KB nên 12 trang là
  /// khoảng 8 MB — mức chấp nhận được, và giải lớn đã có đường riêng.
  static const int _maxDayPages = 12;

  /// Danh sách gợi ý theo quốc gia gần như không đổi, gọi một lần mỗi phiên.
  final Map<String, Set<int>> _regionalCache = <String, Set<int>>{};
  static const Set<String> _stageBasedSports = {'motorsport'};
  static const int _mmaCategoryId = 1708;

  /// `withTimeoutOrNull` + `runCatching` của bản Kotlin gộp làm một.
  Future<T> _guard<T>(
    Future<T> Function() body,
    T fallback, {
    Duration timeout = _primaryTimeout,
    String? label,
  }) async {
    try {
      return await body().timeout(timeout);
    } catch (e) {
      if (label != null) dev.log('$label failed: $e', name: _tag);
      return fallback;
    }
  }

  Future<Map<String, SportEventCount>> loadSportEventCounts([
    String? timezoneOffset,
  ]) =>
      _api.getSportEventCounts(timezoneOffset);

  /// Nạp danh sách giải ghim mặc định lần đầu chạy.
  Future<void> ensureDefaultPinsInitialized() async {
    if (_prefs.pinnedInitialized) return;
    final defaults = await _guard(
      () => _api.getDefaultUniqueTournaments(userCountryCode),
      const <UniqueTournament>[],
      label: 'Default pins',
    );
    if (defaults.isEmpty) {
      dev.log('[Default Pins] Empty response; initialization will retry',
          name: _tag);
      return;
    }
    final bySport = <String, List<int>>{};
    for (final t in defaults) {
      final sport = t.category?.sport?.slug;
      if (sport == null || sport.isEmpty) continue;
      bySport.putIfAbsent(sport, () => <int>[]).add(t.id);
    }
    await _prefs.initializePinned(bySport);
    dev.log('[Default Pins] Seeded ${defaults.length} tournaments', name: _tag);
  }

  Future<void> warmSuggestionsLog() async {
    final teams = await _guard(
      () => _api.getDefaultSuggestedTeams(userCountryCode),
      const <Team>[],
      label: 'Team suggestions',
    );
    dev.log(
      '[Team Suggestions] ${teams.take(5).map((t) => t.name).toList()}',
      name: _tag,
    );
  }

  /// Điểm vào chính — trả về danh sách item đã cấu trúc cho một môn + một ngày.
  Future<List<EventListItem>> loadFeed({
    required String sportSlug,
    required String date,
    required bool liveOnly,
    String? timezoneOffset,
    int cyclingUniqueStageId = SportPresentation.cyclingMenUniqueStageId,
    String? cyclingYear,
  }) async {
    final tz = timezoneOffset ?? DateTimeUtils.timezoneOffsetSeconds;

    if (sportSlug == 'cycling') {
      return _loadCyclingFeed(
        uniqueStageId: cyclingUniqueStageId,
        year: cyclingYear ?? date.substring(0, 4),
        liveOnly: liveOnly,
      );
    }
    if (_stageBasedSports.contains(sportSlug)) {
      return _loadStageFeed(
        sportSlug: sportSlug,
        date: date,
        liveOnly: liveOnly,
        timezoneOffset: tz,
      );
    }
    if (sportSlug == 'mma') {
      return _loadMmaFeed(date: date, liveOnly: liveOnly);
    }
    if (sportSlug == 'football') {
      return _loadPagedDayFeed(
        sportSlug: sportSlug,
        date: date,
        liveOnly: liveOnly,
      );
    }

    final pinnedTournamentIds = _prefs.getPinnedIds(sportSlug);

    // Chạy song song đúng như `async { }` của bản gốc.
    final categoriesFuture = _guard(
      () => _api.getCategoriesForDate(sportSlug, date, tz),
      const <CategoryItem>[],
      label: 'Categories-for-date',
    );

    final popularFuture = () async {
      final localized = await _guard<List<SofascoreEvent>?>(
        () async => (await _api.getPopularEventsForDate(
          sportSlug,
          userCountryCode,
          date,
        ))
            .where((e) => _occursOn(e, date))
            .toList(),
        null,
        label: 'Localized popular events',
      );
      if (localized != null) return localized;
      // Bản gốc: chỉ fallback khi lỗi là HttpException.
      return _guard<List<SofascoreEvent>>(
        () async => (await _api.getPopularEvents(sportSlug))
            .where((e) => _occursOn(e, date))
            .toList(),
        const [],
        label: 'Popular events fallback',
      );
    }();

    final categories = await categoriesFuture;

    final categoryEventsFuture = Future.wait(
      _prioritizeForFastFirstPaint(categories)
          .where((c) => c.totalEvents > 0 && c.category != null)
          .take(_maxInitialCategoryRequests)
          .map((item) async {
        final category = item.category!;
        return _guard<List<SofascoreEvent>>(
          () async => (await _api.getCategoryEventsForDate(category.id, date))
              .where((e) => _occursOn(e, date))
              .toList(),
          const [],
          timeout: _categoryEventsTimeout,
          label: 'Category events for ${category.name}',
        );
      }),
    ).then((lists) => lists.expand((e) => e).toList());

    final popular = await popularFuture;
    final datedCategoryEvents = await categoryEventsFuture;

    final fallbackTournamentIds = datedCategoryEvents.isEmpty && popular.isEmpty
        ? pinnedTournamentIds.take(_maxPinnedFallbackTournaments).toList()
        : const <int>[];

    final fetchedEvents = (await Future.wait(
      fallbackTournamentIds.map((id) => _fetchTournamentEvents(id, date)),
    ))
        .expand((e) => e)
        .toList();

    final allEvents = _distinctById(
      [...datedCategoryEvents, ...popular, ...fetchedEvents]
          .where((e) => _occursOn(e, date)),
    );

    return _buildStructuredList(
      popularEvents: _applyLiveFilter(popular, liveOnly),
      categoryEvents: _applyLiveFilter(allEvents, liveOnly),
      categoriesInfo: categories,
      orderedPinnedTournamentIds: pinnedTournamentIds,
    );
  }

  // ---- Bóng đá: feed ngày theo trang ----

  /// Lấy **trọn** một ngày bằng `sport/{slug}/{date}/events/{page}`.
  ///
  /// Nhánh chung ở trên đi theo khu vực và bị chặn ở
  /// [_maxInitialCategoryRequests] = 8 khu vực, nên bóng đá — môn có hơn 100
  /// khu vực mỗi ngày — luôn thiếu trận. Đường phân trang này lấy đủ 784 trận
  /// của ngày 17/09/2026 chỉ với 1 + 4 request.
  ///
  /// Trận đang đá lấy riêng từ `sport/{slug}/events/live`: feed ngày cập nhật
  /// chậm hơn, mà đây đúng là chỗ người dùng nhìn nhiều nhất.
  Future<List<EventListItem>> _loadPagedDayFeed({
    required String sportSlug,
    required String date,
    required bool liveOnly,
  }) async {
    final pageCount = await _guard(
      () => _api.getSportDayPageCount(sportSlug, date),
      1,
      label: 'Day page count for $sportSlug $date',
    );

    final regionalIds = await _regionalTournamentIds(sportSlug);

    // Giải lớn phải **luôn** có mặt, không phụ thuộc nó rơi vào trang nào.
    //
    // Trang được chia theo khung giờ: thứ Bảy 19/09/2026 có **35 trang**, trang
    // 1 chỉ phủ 00:00–07:00 UTC. Lấy N trang đầu thì Ngoại hạng Anh, LaLiga,
    // Serie A — đá buổi chiều tối châu Âu — không bao giờ lọt vào.
    //
    // Nên gọi thẳng từng giải trong danh sách gợi ý theo quốc gia. Giải không
    // đá hôm đó trả 404 và bị `_guard` nuốt, coi như rỗng.
    final featuredFuture = Future.wait(
      regionalIds.map(
        (id) => _guard<List<SofascoreEvent>>(
          () => _api.getUniqueTournamentEvents(id, date),
          const [],
          timeout: _categoryEventsTimeout,
          label: 'Featured tournament $id',
        ),
      ),
    ).then((lists) => lists.expand((e) => e).toList());

    final pagesFuture = Future.wait(
      _pickPages(pageCount).map(
        (page) => _guard<List<SofascoreEvent>>(
          () => _api.getSportDayEventsPage(sportSlug, date, page),
          const [],
          timeout: _categoryEventsTimeout,
          label: 'Day page $page',
        ),
      ),
    ).then((lists) => lists.expand((e) => e).toList());

    final liveFuture = _guard<List<SofascoreEvent>>(
      () => _api.getSportLiveEvents(sportSlug),
      const [],
      label: 'Live events for $sportSlug',
    );

    // Thứ tự gộp có ý nghĩa: `_distinctById` giữ bản gặp trước, nên bản live
    // (tỷ số mới hơn) phải đứng trước bản trong feed ngày.
    final live = (await liveFuture).where((e) => _occursOn(e, date)).toList();
    final featured = await featuredFuture;
    final paged = await pagesFuture;

    final all = _distinctById([...live, ...featured, ...paged])
        .where((e) => _occursOn(e, date))
        .toList();

    return _buildFootballList(
      events: _applyLiveFilter(all, liveOnly),
      orderedPinnedTournamentIds: _prefs.getPinnedIds(sportSlug),
      regionalTournamentIds: regionalIds,
    );
  }

  /// Chọn trang nào trong [total] để tải.
  ///
  /// Ít hơn hạn mức thì lấy hết. Nhiều hơn thì **rải đều khắp ngày** thay vì
  /// lấy N trang đầu — trang xếp theo khung giờ nên lấy đầu là chỉ có rạng sáng.
  ///
  /// Đây là chỗ cắt bớt có chủ đích: ngày đông nhất trong tuần lên tới 35 trang
  /// (~7.000 trận, phần lớn là giải nghiệp dư), tải hết tốn khoảng 25 MB. Giải
  /// lớn đã được bảo đảm bằng đường `featured` ở trên, nên phần bị bỏ chỉ là
  /// các giải nhỏ ngoài danh sách gợi ý.
  List<int> _pickPages(int total) {
    if (total <= _maxDayPages) {
      return List<int>.generate(total, (i) => i + 1);
    }
    final step = total / _maxDayPages;
    final pages = <int>{};
    for (var i = 0; i < _maxDayPages; i++) {
      pages.add((i * step).floor() + 1);
    }
    dev.log(
      'Ngày có $total trang, chỉ tải ${pages.length}: ${pages.join(",")}',
      name: _tag,
    );
    return pages.toList()..sort();
  }

  /// Hệ số nhân theo mức liên quan tới người dùng.
  ///
  /// Xếp thuần theo `userCount` thì giải trong nước biến mất: V-League 1 có
  /// 4.603 người theo dõi, thua vài trăm giải ngoại. Nhưng **nâng cứng** mọi
  /// giải trong danh sách gợi ý lên trên cũng sai — danh sách VN của Sofascore
  /// có cả **Kolmonen** (hạng ba Phần Lan, 2.005 người), đo thật thì sáu bảng
  /// Kolmonen nhảy lên trên Libertadores và EFL Cup.
  ///
  /// Nên dùng hệ số nhân, giữ được cả hai đầu:
  ///
  /// | Mức | Hệ số | Ví dụ với mã VN |
  /// |---|---:|---|
  /// | Cùng quốc gia | ×50 | V-League 4.603 → 230.150 |
  /// | Cùng châu lục | ×3 | AFC Champions League Two 20.777 → 62.331 |
  /// | Trong danh sách gợi ý | ×2 | ASEAN Championship 14.564 → 29.128 |
  /// | Còn lại | ×1 | LaLiga 961.799 giữ nguyên, vẫn đứng đầu |
  ///
  /// Kolmonen ×2 = 4.010, vẫn nằm đáy. Đúng như mong muốn.
  double _regionWeight(
    Category? category,
    int? uniqueTournamentId,
    Set<int> suggested,
  ) {
    if (category == null) return 1;
    if (category.alpha2?.toUpperCase() == userCountryCode.toUpperCase()) {
      return 50;
    }
    if (category.id == _continentCategoryId[userCountryCode.toUpperCase()]) {
      return 3;
    }
    if (uniqueTournamentId != null && suggested.contains(uniqueTournamentId)) {
      return 2;
    }
    return 1;
  }

  /// Châu lục của từng thị trường, theo `category.id` của Sofascore.
  ///
  /// Chỉ liệt kê các nước app thật sự phát hành; nước không có trong bảng thì
  /// bỏ qua hệ số châu lục, danh sách vẫn xếp theo `userCount` bình thường.
  static const Map<String, int> _continentCategoryId = <String, int>{
    // Asia = 1467
    'VN': 1467, 'TH': 1467, 'ID': 1467, 'MY': 1467, 'PH': 1467,
    'SG': 1467, 'KH': 1467, 'MM': 1467, 'LA': 1467,
    'JP': 1467, 'KR': 1467, 'CN': 1467, 'IN': 1467,
    // Europe = 1465
    'GB': 1465, 'EN': 1465, 'ES': 1465, 'DE': 1465, 'FR': 1465,
    'IT': 1465, 'PT': 1465, 'NL': 1465, 'RU': 1465, 'TR': 1465,
    // South America = 1470
    'BR': 1470, 'AR': 1470, 'CO': 1470, 'CL': 1470, 'PE': 1470,
  };

  /// Giải Sofascore gợi ý cho quốc gia người dùng, nhớ lại cho cả phiên.
  ///
  /// Đây là mảnh ghép mà xếp theo `userCount` không thay được: với mã VN, danh
  /// sách gồm **V-League 1** (4.603 người theo dõi) và **ASEAN Championship**
  /// (14.564) nằm cùng chiếu với Ngoại hạng Anh (1.346.325). Xếp thuần theo số
  /// người theo dõi thì giải trong nước bị đẩy xuống dưới hàng trăm giải ngoại.
  ///
  /// Hỏng thì trả tập rỗng — danh sách lại xếp thuần theo `userCount`, kém
  /// chính xác nhưng vẫn dùng được.
  Future<Set<int>> _regionalTournamentIds(String sportSlug) async {
    final cached = _regionalCache[sportSlug];
    if (cached != null) return cached;

    final list = await _guard(
      () => _api.getFollowSuggestedTournaments(userCountryCode, sportSlug),
      const <UniqueTournament>[],
      label: 'Follow suggestions for $userCountryCode',
    );
    final ids = list.map((e) => e.id).toSet();
    _regionalCache[sportSlug] = ids;
    return ids;
  }

  /// Danh sách bóng đá: gom theo **giải**, không theo quốc gia.
  ///
  /// [_buildStructuredList] dùng cho các môn khác gom theo quốc gia rồi mới tới
  /// giải — đúng với Sofascore nhưng khác hẳn bản bóng đá cũ, nơi người dùng
  /// quen thấy giải lớn nằm trên cùng.
  ///
  /// Thứ tự giải, lần lượt:
  /// 1. giải đã ghim (theo đúng thứ tự người dùng ghim);
  /// 2. **điểm = `userCount` × hệ số khu vực** giảm dần — xem [_regionWeight];
  /// 3. `tournament.priority` giảm dần, phá hoà;
  /// 4. trận sớm nhất trong giải.
  ///
  /// Ban đầu tôi xếp theo `priority` trước, nhưng đo trên feed thật ngày
  /// 17/09/2026 thì **chỉ 7/118 giải có `priority` khác 0**, và giá trị không
  /// phản ánh tầm vóc: "Club Friendly Games" để 0 trong khi "Turkiye Kupasi,
  /// Qualification" được 474 — cao hơn cả EFL Cup. Xếp theo `priority` đẩy
  /// Libertadores lên trên Europa League dù Europa đông người theo dõi gấp đôi.
  ///
  /// `userCount` thì là số đếm thật và bám sát cảm nhận người dùng:
  /// LaLiga 961.799 · Europa League 466.125 · Libertadores 236.524 ·
  /// EFL Cup 172.263 · Liga DIMAYOR 27.457.
  ///
  /// Trong một giải: trận **đang đá lên trước**, rồi tới giờ bóng lăn tăng dần —
  /// giữ nguyên quy tắc của [_appendTournament].
  List<EventListItem> _buildFootballList({
    required List<SofascoreEvent> events,
    required List<int> orderedPinnedTournamentIds,
    Set<int> regionalTournamentIds = const <int>{},
  }) {
    final result = <EventListItem>[];
    final pinned = orderedPinnedTournamentIds;

    // Gom theo **id giải**, không theo tên.
    //
    // "Premier League" là tên giải vô địch của Anh, Kenya, Azerbaijan, Nga…
    // Gom theo tên thì Bournemouth–Liverpool nằm chung nhóm với Migori Youth–
    // Kenya Police, và logo lấy theo trận đầu nên hiện nhầm luôn huy hiệu giải
    // Kenya.
    final groups = _groupBy(
      _distinctById(events),
      (e) =>
          e.tournament?.uniqueTournament?.id ??
          e.tournament?.id ??
          -1,
    ).entries.toList();

    int pinIndex(List<SofascoreEvent> list) {
      final id = list.isEmpty
          ? null
          : list.first.tournament?.uniqueTournament?.id;
      final idx = pinned.indexOf(id ?? -1);
      return idx >= 0 ? idx : 1 << 30;
    }

    int priority(List<SofascoreEvent> list) =>
        list.isEmpty ? 0 : (list.first.tournament?.priority ?? 0);

    int userCount(List<SofascoreEvent> list) =>
        list.isEmpty ? 0 : (list.first.tournament?.uniqueTournament?.userCount ?? 0);

    int score(List<SofascoreEvent> list) {
      if (list.isEmpty) return 0;
      final tournament = list.first.tournament;
      final weight = _regionWeight(
        tournament?.category,
        tournament?.uniqueTournament?.id,
        regionalTournamentIds,
      );
      return (userCount(list) * weight).round();
    }

    groups.sort((a, b) {
      final byPin = pinIndex(a.value).compareTo(pinIndex(b.value));
      if (byPin != 0) return byPin;
      final byScore = score(b.value).compareTo(score(a.value));
      if (byScore != 0) return byScore;
      final byPriority = priority(b.value).compareTo(priority(a.value));
      if (byPriority != 0) return byPriority;
      return _minStart(a.value).compareTo(_minStart(b.value));
    });

    for (final entry in groups) {
      final tournament = entry.value.first.tournament;
      final name = tournament?.uniqueTournament?.name ?? tournament?.name ?? '';
      _appendTournament(
        result,
        name,
        entry.value,
        isPinned: pinIndex(entry.value) != 1 << 30,
      );
    }
    return result;
  }

  // ---- Cycling ----

  Future<List<String>> loadCyclingYears(int uniqueStageId) async {
    final seasons = await _guard(
      () => _api.getUniqueStageSeasons(uniqueStageId),
      const <SofascoreStage>[],
      label: 'Cycling seasons for $uniqueStageId',
    );
    final years = <String>{};
    for (final s in seasons) {
      final y = s.year;
      if (y != null && y.isNotEmpty) years.add(y);
    }
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  Future<List<EventListItem>> _loadCyclingFeed({
    required int uniqueStageId,
    required String year,
    required bool liveOnly,
  }) async {
    final seasons = await _guard(
      () => _api.getUniqueStageSeasons(uniqueStageId),
      const <SofascoreStage>[],
      label: 'Cycling seasons for $uniqueStageId',
    );

    SofascoreStage? selectedSeason;
    for (final s in seasons) {
      if (s.year == year) {
        selectedSeason = s;
        break;
      }
    }
    if (selectedSeason == null) return const [];

    final seasonStage = await _guard<SofascoreStage?>(
      () => _api.getStageDetailsExtended(selectedSeason!.id),
      null,
      timeout: _cyclingExtendedTimeout,
      label: 'Cycling season extended for ${selectedSeason.id}',
    );
    if (seasonStage == null) return const [];

    int earliest(SofascoreStage s) {
      if (s.startDateTimestamp != null) return s.startDateTimestamp!;
      final children = s.substages;
      if (children == null || children.isEmpty) return 1 << 62;
      return children
          .map((c) => c.startDateTimestamp ?? (1 << 62))
          .reduce((a, b) => a < b ? a : b);
    }

    final substages = (seasonStage.substages ?? const <SofascoreStage>[])
        .where((s) =>
            !liveOnly || (s.status?.type?.toLowerCase() == 'inprogress'))
        .toList()
      ..sort((a, b) {
        final byTime = earliest(a).compareTo(earliest(b));
        if (byTime != 0) return byTime;
        return (a.name ?? '').compareTo(b.name ?? '');
      });

    return substages.map<EventListItem>(CyclingRaceItem.new).toList();
  }

  // ---- Motorsport (stage feed) ----

  Future<List<EventListItem>> _loadStageFeed({
    required String sportSlug,
    required String date,
    required bool liveOnly,
    required String timezoneOffset,
  }) async {
    final stageCategoriesFuture = _guard(
      () => _api.getSportStageCategories(sportSlug),
      const <StageCategory>[],
      label: 'Stage categories for $sportSlug',
    );

    final stageCalendarFuture = _guard(
      () => _api.getStageCalendar(
        date.substring(0, 7),
        sportSlug,
        timezoneOffset,
      ),
      const <DailyStage>[],
      label: 'Stage calendar for $sportSlug',
    );

    // Bản gốc gọi nhưng không dùng kết quả — giữ để hành vi mạng giống hệt.
    final categoryFiltersFuture = _guard(
      () => _api.getAvailableCategoryFilters(sportSlug),
      const <String, dynamic>{},
      timeout: _optionalTimeout,
      label: 'Stage category filters for $sportSlug',
    );

    final scheduledStagesFuture = _guard(
      () => _api.getScheduledStages(sportSlug, date),
      const <SofascoreStage>[],
      label: 'Scheduled stages for $sportSlug',
    );

    final stageCategories = await stageCategoriesFuture;
    final weekDates = _stageWeekDates(date);
    final calendarStageIds = (await stageCalendarFuture)
        .where((d) => weekDates.contains(d.date))
        .expand((d) => d.stageIds ?? const <int>[])
        .toSet();
    await categoryFiltersFuture;

    final stages = (await scheduledStagesFuture)
        .where((s) => !liveOnly || s.substage?.status?.type == 'inprogress')
        .toList();

    return _buildStageStructuredList(
      stages: stages,
      stageCategories: stageCategories,
      calendarStageIds: calendarStageIds,
    );
  }

  // ---- MMA ----

  Future<List<EventListItem>> _loadMmaFeed({
    required String date,
    required bool liveOnly,
  }) async {
    final eventsFuture = _guard(
      () => _api.getMmaMainEvents(date),
      const <SofascoreEvent>[],
      label: 'MMA main events',
    );
    final orgsFuture = _guard(
      () => _api.getCategoryUniqueTournaments(_mmaCategoryId),
      const <UniqueTournament>[],
      label: 'MMA organisations',
    );

    final events = await eventsFuture;
    final allOrgs = await orgsFuture;

    final filteredEvents = events
        .where((e) =>
            !liveOnly || (e.status?.type?.toLowerCase() == 'inprogress'))
        .toList();

    final result = <EventListItem>[];

    if (filteredEvents.isNotEmpty) {
      final hasUpcoming =
          filteredEvents.any((e) => e.status?.type == 'notstarted');
      result.add(
        SectionHeaderItem(sectionTitle: hasUpcoming ? 'Upcoming' : 'Events'),
      );
      result.addAll(filteredEvents.map(MatchItem.new));
    }

    final featuredUtIds = filteredEvents
        .map((e) => e.tournament?.uniqueTournament?.id)
        .whereType<int>()
        .toSet();
    final remainingOrgs =
        allOrgs.where((o) => !featuredUtIds.contains(o.id)).toList();

    if (remainingOrgs.isNotEmpty) {
      result.add(const SectionHeaderItem(sectionTitle: 'Organisations'));
      result.addAll(remainingOrgs.map(OrganisationItem.new));
    }

    return result;
  }

  // ---- Hàm phụ ----

  Future<List<SofascoreEvent>> _fetchTournamentEvents(
    int tournamentId,
    String date,
  ) =>
      _guard<List<SofascoreEvent>>(
        () async => (await _api.getUniqueTournamentEvents(tournamentId, date))
            .where((e) => _occursOn(e, date))
            .toList(),
        const [],
        timeout: _tournamentEventsTimeout,
        label: 'Pinned tournament events for $tournamentId',
      );

  bool _occursOn(SofascoreEvent event, String date) {
    if (event.startTimestamp <= 0) return false;
    return DateTimeUtils.apiDate(event.startTime) == date;
  }

  List<SofascoreEvent> _applyLiveFilter(
    List<SofascoreEvent> events,
    bool liveOnly,
  ) =>
      liveOnly
          ? events.where((e) => e.status?.type == 'inprogress').toList()
          : events;

  List<SofascoreEvent> _distinctById(Iterable<SofascoreEvent> events) {
    final seen = <int>{};
    final out = <SofascoreEvent>[];
    for (final e in events) {
      if (seen.add(e.id)) out.add(e);
    }
    return out;
  }

  /// Ưu tiên quốc gia người dùng → khu vực → priority → số trận.
  List<CategoryItem> _prioritizeForFastFirstPaint(List<CategoryItem> items) {
    int countryRank(CategoryItem item) {
      final c = item.category;
      final isHome = (c?.alpha2?.toLowerCase() == userCountryCode.toLowerCase()) ||
          (c?.slug?.toLowerCase() == 'vietnam');
      return isHome ? 0 : 1;
    }

    int regionRank(CategoryItem item) => switch (item.category?.slug?.toLowerCase()) {
          'international' || 'world' => 0,
          'asia' ||
          'europe' ||
          'south-america' ||
          'north-central-america' ||
          'africa' ||
          'oceania' =>
            1,
          _ => 2,
        };

    return items.toList()
      ..sort((a, b) {
        var r = countryRank(a).compareTo(countryRank(b));
        if (r != 0) return r;
        r = regionRank(a).compareTo(regionRank(b));
        if (r != 0) return r;
        r = (b.category?.priority ?? 0).compareTo(a.category?.priority ?? 0);
        if (r != 0) return r;
        return b.totalEvents.compareTo(a.totalEvents);
      });
  }

  List<EventListItem> _buildStructuredList({
    required List<SofascoreEvent> popularEvents,
    required List<SofascoreEvent> categoryEvents,
    required List<CategoryItem> categoriesInfo,
    required List<int> orderedPinnedTournamentIds,
  }) {
    final result = <EventListItem>[];
    final pinnedIdSet = orderedPinnedTournamentIds.toSet();

    final pinnedEvents = categoryEvents
        .where((e) => pinnedIdSet.contains(e.tournament?.uniqueTournament?.id))
        .toList();

    final pinnedGroups = _groupBy(
      pinnedEvents,
      (e) => e.tournament?.name ?? 'Other',
    ).entries.toList()
      ..sort((a, b) {
        int pinIndex(List<SofascoreEvent> events) {
          final id = events.isEmpty
              ? null
              : events.first.tournament?.uniqueTournament?.id;
          final idx = orderedPinnedTournamentIds.indexOf(id ?? -1);
          return idx >= 0 ? idx : 1 << 30;
        }

        final r = pinIndex(a.value).compareTo(pinIndex(b.value));
        if (r != 0) return r;
        return _minStart(a.value).compareTo(_minStart(b.value));
      });

    for (final entry in pinnedGroups) {
      _appendTournament(result, entry.key, entry.value, isPinned: true);
    }

    final recommendedEvents = _distinctById(popularEvents);
    if (recommendedEvents.isNotEmpty) {
      result.add(SectionHeaderItem(
        sectionTitle: 'Recommended for you',
        iconText: '★',
        countText: '${recommendedEvents.length}',
      ));
      _groupBy(recommendedEvents, (e) => e.tournament?.name ?? 'Other')
          .forEach((name, events) {
        _appendTournament(result, name, events, isPinned: false);
      });
    }

    _appendCategories(result, _distinctById(categoryEvents), categoriesInfo);
    return result;
  }

  void _appendCategories(
    List<EventListItem> result,
    List<SofascoreEvent> events,
    List<CategoryItem> categoriesInfo,
  ) {
    final eventGroups =
        _groupBy(events, (e) => e.tournament?.category?.name ?? 'Other');

    final categoryPairs = <MapEntry<CategoryItem?, String>>[];
    for (final item in categoriesInfo) {
      final name = item.category?.name;
      if (name == null) continue;
      if (eventGroups.containsKey(name)) {
        categoryPairs.add(MapEntry(item, name));
      }
    }
    for (final name in eventGroups.keys) {
      final exists = categoryPairs
          .any((p) => p.value.toLowerCase() == name.toLowerCase());
      if (!exists) categoryPairs.add(MapEntry(null, name));
    }

    int countryRank(CategoryItem? item) {
      final c = item?.category;
      final isHome = (c?.alpha2?.toLowerCase() == userCountryCode.toLowerCase()) ||
          (c?.slug?.toLowerCase() == 'vietnam');
      return isHome ? 0 : 1;
    }

    categoryPairs.sort((a, b) {
      var r = countryRank(a.key).compareTo(countryRank(b.key));
      if (r != 0) return r;
      r = (b.key?.category?.priority ?? 0).compareTo(a.key?.category?.priority ?? 0);
      if (r != 0) return r;
      return a.value.toLowerCase().compareTo(b.value.toLowerCase());
    });

    for (final pair in categoryPairs) {
      final categoryItem = pair.key;
      final categoryName = pair.value;
      final categoryEvents = eventGroups[categoryName] ?? const <SofascoreEvent>[];
      if (categoryEvents.isEmpty) continue;

      var categoryId = categoryItem?.category?.id;
      if (categoryId == null) {
        for (final e in categoryEvents) {
          final id = e.tournament?.category?.id;
          if (id != null) {
            categoryId = id;
            break;
          }
        }
      }

      result.add(SectionHeaderItem(
        sectionTitle: categoryName,
        categoryId: categoryId ?? 0,
        countText: '${categoryEvents.length}',
      ));

      final serverTournamentOrder =
          categoryItem?.uniqueTournamentIds ?? const <int>[];

      final tournamentGroups =
          _groupBy(categoryEvents, (e) => e.tournament?.name ?? 'Other')
              .entries
              .toList()
            ..sort((a, b) {
              int serverIndex(List<SofascoreEvent> evts) {
                final id = evts.isEmpty
                    ? null
                    : evts.first.tournament?.uniqueTournament?.id;
                final idx = serverTournamentOrder.indexOf(id ?? -1);
                return idx >= 0 ? idx : 1 << 30;
              }

              int priority(List<SofascoreEvent> evts) {
                final p = evts.isEmpty
                    ? null
                    : evts.first.tournament?.uniqueTournament?.priority;
                return (p != null && p > 0) ? p : (1 << 30);
              }

              int userCount(List<SofascoreEvent> evts) =>
                  evts.isEmpty
                      ? 0
                      : (evts.first.tournament?.uniqueTournament?.userCount ?? 0);

              var r = serverIndex(a.value).compareTo(serverIndex(b.value));
              if (r != 0) return r;
              r = priority(a.value).compareTo(priority(b.value));
              if (r != 0) return r;
              r = userCount(b.value).compareTo(userCount(a.value));
              if (r != 0) return r;
              return _minStart(a.value).compareTo(_minStart(b.value));
            });

      for (final entry in tournamentGroups) {
        _appendTournament(result, entry.key, entry.value, isPinned: false);
      }
    }
  }

  void _appendTournament(
    List<EventListItem> result,
    String tournamentName,
    List<SofascoreEvent> events, {
    required bool isPinned,
  }) {
    final sortedEvents = events.toList()
      ..sort((a, b) {
        final la = a.status?.type == 'inprogress' ? 0 : 1;
        final lb = b.status?.type == 'inprogress' ? 0 : 1;
        if (la != lb) return la.compareTo(lb);
        return a.startTimestamp.compareTo(b.startTimestamp);
      });
    if (sortedEvents.isEmpty) return;

    final first = sortedEvents.first;
    result.add(TournamentSubHeaderItem(
      tournamentName: tournamentName,
      categoryName: first.tournament?.category?.name ?? 'International',
      logoUrl: first.tournament?.uniqueTournament?.logoUrl,
      uniqueTournamentId: first.tournament?.uniqueTournament?.id ?? 0,
      isPinned: isPinned,
    ));
    result.addAll(sortedEvents.map(MatchItem.new));
  }

  List<EventListItem> _buildStageStructuredList({
    required List<SofascoreStage> stages,
    required List<StageCategory> stageCategories,
    required Set<int> calendarStageIds,
  }) {
    final result = <EventListItem>[];
    final seenUniqueStageIds = <int>{};

    int stageStart(SofascoreStage s) {
      final sub = s.substage?.startDateTimestamp;
      if (sub != null) return sub;
      final list = s.substageStartDateTimestamps;
      if (list != null && list.isNotEmpty) {
        return list.reduce((a, b) => a < b ? a : b);
      }
      return 1 << 62;
    }

    final orderedStages = stages.toList()
      ..sort((a, b) {
        var r = (calendarStageIds.contains(a.id) ? 0 : 1)
            .compareTo(calendarStageIds.contains(b.id) ? 0 : 1);
        if (r != 0) return r;
        r = stageStart(a).compareTo(stageStart(b));
        if (r != 0) return r;
        r = (-(a.uniqueStage?.category?.priority ?? 0))
            .compareTo(-(b.uniqueStage?.category?.priority ?? 0));
        if (r != 0) return r;
        return (a.uniqueStage?.name ?? a.name ?? '')
            .compareTo(b.uniqueStage?.name ?? b.name ?? '');
      });

    final grouped =
        _groupBy(orderedStages, (s) => s.uniqueStage?.id ?? -s.id);

    for (final group in grouped.values) {
      final firstStage = group.first;
      final uniqueStage = firstStage.uniqueStage;
      if (uniqueStage != null) {
        seenUniqueStageIds.add(uniqueStage.id);
        result.add(StageSeriesItem(uniqueStage: uniqueStage, hasChildren: true));
        for (var i = 0; i < group.length; i++) {
          result.add(StageRaceItem(
            stage: group[i],
            isLastInSeries: i == group.length - 1,
          ));
        }
      } else {
        result.add(StageRaceItem(stage: firstStage, isLastInSeries: true));
      }
    }

    final leftovers = <MapEntry<StageCategory, UniqueStage>>[];
    for (final category in stageCategories) {
      for (final us in category.uniqueStages ?? const <UniqueStage>[]) {
        leftovers.add(MapEntry(category, _withCategory(us, category.resolvedCategory)));
      }
    }

    final filtered = leftovers
        .where((e) => !seenUniqueStageIds.contains(e.value.id))
        .toList()
      ..sort((a, b) {
        final pa = a.key.resolvedCategory?.priority ?? a.key.priority;
        final pb = b.key.resolvedCategory?.priority ?? b.key.priority;
        final r = pb.compareTo(pa);
        if (r != 0) return r;
        return (a.value.name ?? '').compareTo(b.value.name ?? '');
      });

    for (final entry in filtered) {
      result.add(StageSeriesItem(uniqueStage: entry.value, hasChildren: false));
    }

    return result;
  }

  UniqueStage _withCategory(UniqueStage stage, Category? category) {
    if (stage.category != null || category == null) return stage;
    return UniqueStage(
      id: stage.id,
      name: stage.name,
      slug: stage.slug,
      primaryColorHex: stage.primaryColorHex,
      secondaryColorHex: stage.secondaryColorHex,
      category: category,
    );
  }

  /// Bảy ngày kể từ `date` — bản gốc dùng để lọc lịch stage.
  Set<String> _stageWeekDates(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return {date};
    return {
      for (var i = 0; i < 7; i++)
        DateTimeUtils.apiDate(parsed.add(Duration(days: i))),
    };
  }

  int _minStart(List<SofascoreEvent> events) => events.isEmpty
      ? (1 << 62)
      : events.map((e) => e.startTimestamp).reduce((a, b) => a < b ? a : b);

  /// `groupBy` giữ nguyên thứ tự chèn — tương đương Kotlin.
  Map<K, List<V>> _groupBy<K, V>(Iterable<V> items, K Function(V) keyOf) {
    final map = <K, List<V>>{};
    for (final item in items) {
      map.putIfAbsent(keyOf(item), () => <V>[]).add(item);
    }
    return map;
  }
}
