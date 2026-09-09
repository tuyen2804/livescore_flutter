import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/sport_presentation.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../data/models/sofascore/sofascore_models.dart';
import '../../../../domain/entities/event_list_item.dart';
import 'event_rows.dart';

/// Bo góc theo vị trí trong "thẻ" — port `bg_card_single/top/middle/bottom`.
enum _CardSlot { single, top, middle, bottom }

BorderRadius _radiusOf(_CardSlot slot) => switch (slot) {
      _CardSlot.single => BorderRadius.circular(16),
      _CardSlot.top => const BorderRadius.vertical(top: Radius.circular(16)),
      _CardSlot.bottom =>
        const BorderRadius.vertical(bottom: Radius.circular(16)),
      _CardSlot.middle => BorderRadius.zero,
    };

/// Port `presentation/home/EventAdapter.kt`: danh sách phẳng của màn Home cho
/// các môn Sofascore, 7 loại item. Bản gốc cho thu gọn theo section và theo
/// giải nên trạng thái đó nằm ở đây, và mỗi dòng tự chọn nền theo vị trí.
class EventFeedList extends StatefulWidget {
  const EventFeedList({
    super.key,
    required this.items,
    required this.onEventTap,
    required this.onStageSeriesTap,
    required this.onStageRaceTap,
    required this.onOrganisationTap,
    this.header,
    this.notifiedIds = const {},
    this.onNotiTap,
  });

  final List<EventListItem> items;
  final ValueChanged<SofascoreEvent> onEventTap;
  final ValueChanged<UniqueStage> onStageSeriesTap;
  final ValueChanged<SofascoreStage> onStageRaceTap;
  final ValueChanged<UniqueTournament> onOrganisationTap;
  final Widget? header;
  final Set<int> notifiedIds;
  final ValueChanged<EventListItem>? onNotiTap;

  @override
  State<EventFeedList> createState() => _EventFeedListState();
}

class _EventFeedListState extends State<EventFeedList> {
  final Set<String> _collapsedSections = {};
  final Set<String> _collapsedTournaments = {};

  static String _sectionKey(SectionHeaderItem item) => item.sectionTitle;

  static String _tournamentKey(TournamentSubHeaderItem item) =>
      '${item.categoryName}:${item.tournamentName}:'
      '${item.logoUrl ?? ''}:${item.isPinned}';

  /// Port `rebuildVisibleItems()`.
  List<EventListItem> get _visible {
    final out = <EventListItem>[];
    var sectionCollapsed = false;
    var tournamentCollapsed = false;

    for (final item in widget.items) {
      switch (item) {
        case SectionHeaderItem():
          sectionCollapsed = _collapsedSections.contains(_sectionKey(item));
          tournamentCollapsed = false;
          out.add(item.copyWith(isExpanded: !sectionCollapsed));
        case TournamentSubHeaderItem():
          if (!sectionCollapsed) {
            tournamentCollapsed =
                _collapsedTournaments.contains(_tournamentKey(item));
            out.add(item.copyWith(isExpanded: !tournamentCollapsed));
          }
        case MatchItem():
          if (!sectionCollapsed && !tournamentCollapsed) out.add(item);
        case StageSeriesItem():
          if (!sectionCollapsed) out.add(item);
        case StageRaceItem():
          if (!sectionCollapsed && !tournamentCollapsed) out.add(item);
        case CyclingRaceItem():
          if (!sectionCollapsed) out.add(item);
        case OrganisationItem():
          if (!sectionCollapsed) out.add(item);
      }
    }
    return out;
  }

  void _toggleSection(SectionHeaderItem item) => setState(() {
        final key = _sectionKey(item);
        if (!_collapsedSections.remove(key)) _collapsedSections.add(key);
      });

  void _toggleTournament(TournamentSubHeaderItem item) => setState(() {
        final key = _tournamentKey(item);
        if (!_collapsedTournaments.remove(key)) _collapsedTournaments.add(key);
      });

  /// Port `viewTypeFor(event)` — mỗi họ môn một layout dòng trận riêng.
  Widget _matchRow(SofascoreEvent event, _CardSlot slot) {
    final isNotified = widget.notifiedIds.contains(event.id);
    void onTap() => widget.onEventTap(event);
    void onNoti() => widget.onNotiTap?.call(MatchItem(event));

    return switch (SportPresentation.homeEventFamily(event.sportSlug)) {
      HomeEventFamily.tennis || HomeEventFamily.basketball => PeriodEventRow(
          event: event,
          family: SportPresentation.homeEventFamily(event.sportSlug),
          borderRadius: _radiusOf(slot),
          isNotified: isNotified,
          onTap: onTap,
          onNoti: onNoti,
        ),
      HomeEventFamily.cricket => CricketEventRow(
          event: event,
          borderRadius: _radiusOf(slot),
          isNotified: isNotified,
          onTap: onTap,
          onNoti: onNoti,
        ),
      HomeEventFamily.mmaFight => MmaEventRow(
          event: event,
          isNotified: isNotified,
          onTap: onTap,
          onNoti: onNoti,
        ),
      _ => GenericEventRow(
          event: event,
          borderRadius: _radiusOf(slot),
          isNotified: isNotified,
          onTap: onTap,
          onNoti: onNoti,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final hasSectionHeaders = visible.any((e) => e is SectionHeaderItem);
    final headerOffset = widget.header == null ? 0 : 1;

    return ListView.builder(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
      itemCount: visible.length + headerOffset,
      itemBuilder: (context, rawIndex) {
        if (widget.header != null && rawIndex == 0) return widget.header!;
        final index = rawIndex - headerOffset;
        final item = visible[index];
        final next = index + 1 < visible.length ? visible[index + 1] : null;

        // Port đoạn tính isFirstInCard/isLastInCard trong onBindViewHolder.
        final isFirstInCard = hasSectionHeaders
            ? item is SectionHeaderItem || index == 0
            : index == 0 || item is TournamentSubHeaderItem;
        final isLastInCard = hasSectionHeaders
            ? next == null || next is SectionHeaderItem
            : next == null || next is TournamentSubHeaderItem;

        final slot = isFirstInCard && isLastInCard
            ? _CardSlot.single
            : isFirstInCard
                ? _CardSlot.top
                : isLastInCard
                    ? _CardSlot.bottom
                    : _CardSlot.middle;

        return switch (item) {
          SectionHeaderItem() => _SectionHeaderRow(
              item: item,
              slot: slot,
              onTap: () => _toggleSection(item),
            ),
          TournamentSubHeaderItem() => _TournamentSubHeaderRow(
              item: item,
              slot: slot,
              onTap: () => _toggleTournament(item),
            ),
          MatchItem(:final event) => Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(6)),
              child: _matchRow(event, slot),
            ),
          StageSeriesItem() => _StageSeriesRow(
              item: item,
              slot: item.hasChildren ? _CardSlot.top : slot,
              isNotified: widget.notifiedIds.contains(item.uniqueStage.id),
              onTap: () => widget.onStageSeriesTap(item.uniqueStage),
              onNoti: () => widget.onNotiTap?.call(item),
            ),
          StageRaceItem() => _StageRaceRow(
              stage: item.stage,
              slot: item.isLastInSeries ? _CardSlot.bottom : _CardSlot.middle,
              onTap: () => widget.onStageRaceTap(item.stage),
            ),
          CyclingRaceItem(:final stage) => _CyclingRaceRow(
              stage: stage,
              onTap: () => widget.onStageRaceTap(stage),
            ),
          OrganisationItem(:final uniqueTournament) => _OrganisationRow(
              tournament: uniqueTournament,
              isNotified: widget.notifiedIds.contains(uniqueTournament.id),
              onTap: () => widget.onOrganisationTap(uniqueTournament),
              onNoti: () => widget.onNotiTap?.call(item),
            ),
        };
      },
    );
  }
}

/// Port `category_header_cell.xml` + `SectionHeaderViewHolder.bind`.
/// Tiêu đề dạng `Tên (Mô tả)` được tách làm hai dòng; viên đếm luôn ẩn.
class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.item,
    required this.slot,
    required this.onTap,
  });

  final SectionHeaderItem item;
  final _CardSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.sectionTitle;
    final hasDescription = title.contains(' (');
    final name = hasDescription ? title.split(' (').first.trim() : title;
    final description = hasDescription
        ? title.split(' (').skip(1).join(' (').replaceAll(')', '').trim()
        : '';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(
          left: AppDimens.sdp(6),
          right: AppDimens.sdp(6),
          top: 10,
        ),
        padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: _radiusOf(slot),
        ),
        child: Row(
          children: [
            AppImage(
              source: item.categoryId > 0
                  ? ApiConstants.categoryLogo(item.categoryId)
                  : null,
              width: 24,
              height: 24,
              placeholderAsset: 'assets/icons/ic_league.svg',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bold(
                      size: 15,
                      color: AppColors.text500,
                    ),
                  ),
                  if (hasDescription) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.regular(
                        size: 12,
                        color: AppColors.text200,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 24,
              height: 24,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedRotation(
                  turns: item.isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: SvgPicture.asset(
                    'assets/icons/ic_expand.svg',
                    colorFilter: const ColorFilter.mode(
                      AppColors.text500,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Port `item_tournament_sub_header.xml` + `TournamentHeaderViewHolder.bind`.
class _TournamentSubHeaderRow extends StatelessWidget {
  const _TournamentSubHeaderRow({
    required this.item,
    required this.slot,
    required this.onTap,
  });

  final TournamentSubHeaderItem item;
  final _CardSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: AppDimens.sdp(6)),
          decoration: BoxDecoration(
            color: AppColors.itemBg,
            borderRadius: _radiusOf(slot),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(height: 1, color: AppColors.divider),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      AppImage(
                        source: item.logoUrl,
                        width: 24,
                        height: 24,
                        placeholderAsset: 'assets/icons/ic_league.svg',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.tournamentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bold(
                                size: 13,
                                color: AppColors.text500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.regular(
                                size: 11,
                                color: AppColors.text200,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.isPinned) ...[
                        SvgPicture.asset(
                          'assets/icons/ic_pin_on_no_padding.svg',
                          width: 16,
                          height: 16,
                          colorFilter: const ColorFilter.mode(
                            AppColors.text500,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Port `item_stage_series.xml` + `StageSeriesViewHolder.bind`.
class _StageSeriesRow extends StatelessWidget {
  const _StageSeriesRow({
    required this.item,
    required this.slot,
    required this.isNotified,
    required this.onTap,
    required this.onNoti,
  });

  final StageSeriesItem item;
  final _CardSlot slot;
  final bool isNotified;
  final VoidCallback onTap;
  final VoidCallback onNoti;

  @override
  Widget build(BuildContext context) {
    final stage = item.uniqueStage;
    final logo = stage.category == null
        ? stage.logoUrl
        : ApiConstants.categoryLogo(stage.category!.id);
    final name = (stage.name ?? '').trim();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppDimens.sdp(6)),
        constraints: const BoxConstraints(minHeight: 48),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: _radiusOf(slot),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            AppImage(source: logo, width: 54, height: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name.isEmpty ? 'Series' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bold(size: 16, color: AppColors.text500),
              ),
            ),
            Container(
              width: 1,
              height: 36,
              margin: const EdgeInsets.only(right: 4),
              color: AppColors.divider,
            ),
            GestureDetector(
              onTap: onNoti,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset(
                    'assets/icons/ic_bell_outline.svg',
                    colorFilter: ColorFilter.mode(
                      isNotified ? AppColors.brandAccent : AppColors.text200,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Port `item_stage_series_sub.xml` + `StageRaceViewHolder.bind`.
class _StageRaceRow extends StatelessWidget {
  const _StageRaceRow({
    required this.stage,
    required this.slot,
    required this.onTap,
  });

  final SofascoreStage stage;
  final _CardSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timestamps = stage.substageStartDateTimestamps ?? const <int>[];
    final timestamp = stage.substage?.startDateTimestamp ??
        (timestamps.isEmpty ? 0 : timestamps.reduce((a, b) => a < b ? a : b));

    final session = _firstNotBlank([
      stage.substage?.name,
      stage.substage?.type?.name,
      stage.type?.name,
    ]);
    final info = [
      _formatStageDateTime(timestamp),
      ?session,
    ].where((e) => e.isNotEmpty).join(' • ');

    final live = stage.substage?.status?.type == 'inprogress';
    final alpha2 = (stage.country?.alpha2 ?? '').toUpperCase();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppDimens.sdp(6)),
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: _radiusOf(slot),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: alpha2.length == 2 ? 1 : 0,
              child: AppImage(
                source:
                    alpha2.length == 2 ? ApiConstants.countryFlag(alpha2) : null,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stageTitle(stage),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bold(
                      size: 15,
                      color: AppColors.text500,
                    ),
                  ),
                  if (info.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      info,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.regular(
                        size: 13,
                        color: AppColors.text200,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (live) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.sofaLiveRed),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'LIVE',
                  style: AppTextStyles.regular(
                    size: 11,
                    color: AppColors.sofaLiveRed,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Port `item_cycling_race.xml` + `CyclingRaceViewHolder.bind`.
class _CyclingRaceRow extends StatelessWidget {
  const _CyclingRaceRow({required this.stage, required this.onTap});

  final SofascoreStage stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final children = [...?stage.substages]..sort((a, b) =>
        (a.startDateTimestamp ?? 1 << 62)
            .compareTo(b.startDateTimestamp ?? 1 << 62));
    final finalSession = children.isEmpty ? null : children.last;
    final sessionTimestamp =
        finalSession?.startDateTimestamp ?? stage.startDateTimestamp ?? 0;
    final sessionName =
        _firstNotBlank([finalSession?.name, stage.type?.name]) ?? 'Race';

    final latestSession = [
      _formatCyclingDateTime(sessionTimestamp),
      sessionName,
    ].where((e) => e.isNotEmpty).join(' • ');

    final showRange = children.length > 1 &&
        stage.startDateTimestamp != null &&
        stage.endDateTimestamp != null;
    final dateRange = showRange
        ? _formatDayMonthRange(
            stage.startDateTimestamp!,
            stage.endDateTimestamp!,
          )
        : '';

    final winner =
        _firstNotBlank([stage.winner?.name, stage.winner?.shortName]) ?? '';

    final status = (stage.substage?.status?.type ?? '').toLowerCase();
    final showBell = status == 'notstarted' || status == 'scheduled';
    final alpha2 = (stage.country?.alpha2 ?? '').toUpperCase();

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(
          left: AppDimens.sdp(6),
          right: AppDimens.sdp(6),
          bottom: 8,
        ),
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Opacity(
                        opacity: alpha2.length == 2 ? 1 : 0,
                        child: AppImage(
                          source: alpha2.length == 2
                              ? ApiConstants.countryFlag(alpha2)
                              : null,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _stageTitle(stage, fallback: 'Cycling'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bold(
                                size: 16,
                                color: AppColors.text500,
                              ),
                            ),
                            if (dateRange.isNotEmpty)
                              Text(
                                dateRange,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.regular(
                                  size: 13,
                                  color: AppColors.text200,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const SizedBox(width: 28),
                      SvgPicture.asset(
                        'assets/icons/ic_small_dot.svg',
                        width: 8,
                        height: 8,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          latestSession,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.regular(
                            size: 13,
                            color: AppColors.text200,
                          ),
                        ),
                      ),
                      if (winner.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 156),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                'assets/icons/ic_trophy_sofa.svg',
                                width: 14,
                                height: 14,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  winner,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.regular(
                                    size: 13,
                                    color: AppColors.text200,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(width: 10),
                    ],
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 48, color: AppColors.divider),
            if (showBell)
              SizedBox(
                width: 48,
                height: 48,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SvgPicture.asset(
                    'assets/icons/ic_bell_outline.svg',
                    colorFilter: const ColorFilter.mode(
                      AppColors.text200,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Port `createOrganisationCardView` + `OrganisationViewHolder.bind`:
/// view dựng bằng code, nền phẳng `color_item_bg`, gạch 1dp phía trên.
class _OrganisationRow extends StatelessWidget {
  const _OrganisationRow({
    required this.tournament,
    required this.isNotified,
    required this.onTap,
    required this.onNoti,
  });

  final UniqueTournament tournament;
  final bool isNotified;
  final VoidCallback onTap;
  final VoidCallback onNoti;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: AppDimens.sdp(6)),
          child: Column(
            children: [
              Container(height: 1, color: AppColors.divider),
              Container(
                color: AppColors.itemBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    AppImage(
                      source: tournament.logoUrl,
                      width: 28,
                      height: 28,
                      placeholderAsset: 'assets/icons/ic_league.svg',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tournament.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bold(
                          size: 15,
                          color: AppColors.text500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onNoti,
                      child: SvgPicture.asset(
                        'assets/icons/ic_bell_outline.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          isNotified
                              ? AppColors.brandAccent
                              : AppColors.text200,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

// ---- Helper dùng chung, port các hàm private của EventAdapter ----

final DateFormat _sdfStageDateTime = DateFormat('dd MMM, HH:mm', 'en_US');
final DateFormat _sdfCyclingDateTime = DateFormat('d MMM, HH:mm');
final DateFormat _sdfDayMonth = DateFormat('dd MMM', 'en_US');

String _formatStageDateTime(int timestamp) => timestamp <= 0
    ? ''
    : _sdfStageDateTime
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));

String _formatCyclingDateTime(int timestamp) => timestamp <= 0
    ? ''
    : _sdfCyclingDateTime
        .format(DateTime.fromMillisecondsSinceEpoch(timestamp * 1000));

String _formatDayMonthRange(int start, int end) {
  if (start <= 0 || end <= 0) return '';
  final from =
      _sdfDayMonth.format(DateTime.fromMillisecondsSinceEpoch(start * 1000));
  final to =
      _sdfDayMonth.format(DateTime.fromMillisecondsSinceEpoch(end * 1000));
  return '$from - $to';
}

String? _firstNotBlank(List<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) return value;
  }
  return null;
}

/// `stage.name ?: description ?: slug viết hoa chữ đầu ?: fallback`.
String _stageTitle(SofascoreStage stage, {String fallback = 'Stage'}) {
  final name = stage.name ?? stage.description;
  if (name != null && name.isNotEmpty) return name;
  final slug = stage.slug;
  if (slug != null && slug.isNotEmpty) {
    final spaced = slug.replaceAll('-', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
  return fallback;
}
