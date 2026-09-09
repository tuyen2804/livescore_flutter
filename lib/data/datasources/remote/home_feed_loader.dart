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
