import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/ads/native/native_placements.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/billing/premium_manager.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/sport_presentation.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/sofascore/sofascore_models.dart';
import '../../../domain/entities/event_list_item.dart';
import '../../../domain/entities/match_entities.dart';
import '../../providers/home_provider.dart';
import '../../widgets/notification_dialogs.dart';
import '../../widgets/sport_icon.dart';
import 'widgets/date_strip.dart';
import 'widgets/event_feed_list.dart';
import 'widgets/home_league_card.dart';
import 'widgets/live_match_card.dart';
import 'widgets/sport_picker_sheet.dart';
import '../../widgets/native/native_ad_view.dart';

/// Port `presentation/home/HomeFragment.kt` + `fragment_home.xml`.
/// Bỏ hai khung native ad (`flAdContainer`) và nút Premium trên toolbar.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickSport(BuildContext context, HomeProvider provider) async {
    final slug = await SportPickerSheet.show(
      context,
      sports: provider.availableSports,
      selected: provider.selectedSport,
      liveCount: provider.liveCountFor,
      totalCount: provider.totalCountFor,
    );
    if (slug != null) await provider.setSport(slug);
  }

  Future<void> _pickDate(BuildContext context, HomeProvider provider) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) provider.setDate(picked);
  }

  void _openMatch(BuildContext context, MatchFixture fixture) {
    if (fixture.isFootball) {
      Navigator.of(context).pushNamed(
        AppRoutes.matchDetail,
        arguments: {'matchId': int.tryParse(fixture.id) ?? 0},
      );
    } else {
      Navigator.of(context).pushNamed(
        AppRoutes.sofascoreMatchDetail,
        arguments: {
          'eventId': int.tryParse(fixture.id) ?? 0,
          'sportSlug': fixture.sportSlug,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<HomeProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Toolbar(
              sportSlug: provider.selectedSport,
              onSportTap: () => _pickSport(context, provider),
            ),
            SizedBox(height: AppDimens.sdp(12)),
            DateStrip(
              dates: provider.dateStrip,
              selected: provider.selectedDate,
              onSelect: provider.setDate,
              onPickDate: () => _pickDate(context, provider),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brandAccent,
                backgroundColor: AppColors.itemBg,
                onRefresh: provider.refreshData,
                child: _buildBody(context, provider, s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeProvider provider, S s) {
    // `layoutLoading` của bản gốc phủ kín phần dưới thanh ngày.
    if (provider.isLoading && provider.isEmpty) {
      return const EarthLoadingOverlay(label: 'Loading');
    }

    if (provider.failure != null && provider.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: AppDimens.sdp(60)),
          AppErrorView(
            failure: provider.failure!,
            onRetry: provider.refreshData,
          ),
        ],
      );
    }

    // `layoutNoData`: ic_empty 120sdp + dòng chữ 14ssp text_secondary.
    if (provider.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: AppDimens.sdp(24)),
          AppEmptyView(message: s.theFieldIsQuiteEmpty),
        ],
      );
    }

    final notifications = sl<NotificationService>();
    final liveHeader = _liveCarousel(context, provider, s);

    // Bóng đá dùng `HomeAdapter` (nhóm theo giải), các môn Sofascore dùng
    // `EventAdapter` (danh sách phẳng nhiều loại item) — đúng như bản gốc.
    if (!provider.isFootball) {
      return EventFeedList(
        items: provider.feedItems,
        header: liveHeader,
        notifiedIds: provider.notifiedIds,
        onNotiTap: (item) =>
            _toggleEventNotification(context, provider, notifications, item),
        onEventTap: (event) => _openEvent(context, provider, event),
        onStageSeriesTap: (stage) => Navigator.of(context).pushNamed(
          AppRoutes.motorsportSeries,
          arguments: {
            'uniqueStageId': stage.id,
            'name': stage.name ?? '',
            'sportSlug': provider.selectedSport,
          },
        ),
        onStageRaceTap: (stage) => Navigator.of(context).pushNamed(
          AppRoutes.motorsportStage,
          arguments: {
            'stageId': stage.id,
            'name': stage.name ?? stage.description ?? '',
            'sportSlug': provider.selectedSport,
          },
        ),
        onOrganisationTap: (tournament) => Navigator.of(context).pushNamed(
          provider.selectedSport == 'mma'
              ? AppRoutes.mmaTournament
              : AppRoutes.uniqueTournament,
          arguments: {
            'uniqueTournamentId': tournament.id,
            'name': tournament.name,
            'sportSlug': provider.selectedSport,
          },
        ),
      );
    }

    // `flAdContainer` trong `fragment_home.xml` nằm **bên trong** vùng cuộn
    // của SwipeRefreshLayout, giữa `rcvLiveMatchesHeader` và `rcvFixture` —
    // tức cuộn theo nội dung, không ghim dưới thanh ngày.
    return ListView.builder(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
      itemCount: provider.leagueSections.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) return liveHeader;
        if (index == 1) {
          return NativeAdView(
            placement: NativePlacements.inApp,
            margin: EdgeInsets.symmetric(vertical: AppDimens.sdp(6)),
          );
        }

        final section = provider.leagueSections[index - 2];
        return HomeLeagueCard(
          section: section,
          onMatchTap: (fixture) => _openMatch(context, fixture),
          onToggleNotification: (fixture) =>
              _toggleNotification(context, provider, notifications, fixture),
        );
      },
    );
  }

  /// Port `item_live_match_header.xml` + `LiveMatchHeaderAdapter`: chấm đỏ
  /// `ic_dot_live` + "LIVE MATCHES", nút "See all" mở màn LiveMatches, rồi
  /// mới tới băng thẻ live. Cả khối biến mất khi không có trận nào.
  Widget _liveCarousel(BuildContext context, HomeProvider provider, S s) {
    if (provider.liveMatches.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(
        top: AppDimens.sdp(8),
        left: AppDimens.sdp(16),
        bottom: AppDimens.sdp(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_dot_live.svg',
                width: AppDimens.sdp(20),
                height: AppDimens.sdp(20),
              ),
              SizedBox(width: AppDimens.sdp(8)),
              Text(
                s.liveMatches,
                style: AppTextStyles.medium(
                  size: AppDimens.ssp(12),
                  color: AppColors.text500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.liveMatches),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      s.seeAll,
                      style: AppTextStyles.medium(
                        size: AppDimens.ssp(12),
                        color: AppColors.text100,
                      ),
                    ),
                    SizedBox(width: AppDimens.sdp(2)),
                    Padding(
                      padding: EdgeInsets.only(
                        top: AppDimens.sdp(1),
                        right: AppDimens.sdp(16),
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/ic_see_all.svg',
                        width: AppDimens.sdp(14),
                        height: AppDimens.sdp(14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimens.sdp(8)),
          SizedBox(
            height: AppDimens.sdp(130),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.liveMatches.length,
              itemBuilder: (context, i) {
                final match = provider.liveMatches[i];
                return LiveMatchCard(
                  match: match,
                  onTap: () => Navigator.of(context).pushNamed(
                    provider.isFootball
                        ? AppRoutes.matchDetail
                        : AppRoutes.sofascoreMatchDetail,
                    arguments: provider.isFootball
                        ? {'matchId': int.tryParse(match.id) ?? 0}
                        : {
                            'eventId': int.tryParse(match.id) ?? 0,
                            'sportSlug': provider.selectedSport,
                          },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Port `onNotiClick` của `HomeFragment`: đang bật thì hỏi tắt qua
  /// `TurnOffNotificationDialog`, chưa bật thì mở `MatchNotificationDialog`
  /// để chọn cấu hình trước khi đặt lịch.
  Future<void> _toggleNotification(
    BuildContext context,
    HomeProvider provider,
    NotificationService notifications,
    MatchFixture fixture,
  ) async {
    if (provider.isNotificationEnabled(fixture.id)) {
      final confirmed = await TurnOffNotificationDialog.show(context);
      if (!confirmed) return;
      await provider.toggleNotification(fixture, notifications);
      return;
    }

    final config = await MatchNotificationDialog.show(context);
    if (config == null) return;
    await provider.toggleNotification(
      fixture,
      notifications,
      beforeMatchMinutes: config.beforeMatchMinutes,
      notifyMatchStart: config.notifyMatchStart,
      notifyEndFirstHalf: config.notifyEndFirstHalf,
      notifyStartSecondHalf: config.notifyStartSecondHalf,
      notifyEndMatch: config.notifyEndMatch,
    );
  }

  /// Chuông trên các dòng Sofascore — cùng luồng hỏi/đặt như bóng đá.
  Future<void> _toggleEventNotification(
    BuildContext context,
    HomeProvider provider,
    NotificationService notifications,
    EventListItem item,
  ) async {
    final id = switch (item) {
      MatchItem(:final event) => event.id,
      StageSeriesItem(:final uniqueStage) => uniqueStage.id,
      StageRaceItem(:final stage) || CyclingRaceItem(:final stage) => stage.id,
      OrganisationItem(:final uniqueTournament) => uniqueTournament.id,
      _ => 0,
    };
    if (id == 0) return;

    if (provider.notifiedIds.contains(id)) {
      final confirmed = await TurnOffNotificationDialog.show(context);
      if (!confirmed) return;
      await provider.toggleEventNotification(item, notifications);
      return;
    }

    final config = await MatchNotificationDialog.show(context);
    if (config == null) return;
    await provider.toggleEventNotification(
      item,
      notifications,
      beforeMatchMinutes: config.beforeMatchMinutes,
      notifyMatchStart: config.notifyMatchStart,
      notifyEndFirstHalf: config.notifyEndFirstHalf,
      notifyStartSecondHalf: config.notifyStartSecondHalf,
      notifyEndMatch: config.notifyEndMatch,
    );
  }

  /// Port `onItemClickListener` của `EventAdapter`: MMA mở màn giải,
  /// còn lại mở chi tiết trận Sofascore.
  void _openEvent(
    BuildContext context,
    HomeProvider provider,
    SofascoreEvent event,
  ) {
    final slug = event.sportSlug.isEmpty ? provider.selectedSport : event.sportSlug;
    if (slug == 'mma') {
      Navigator.of(context).pushNamed(
        AppRoutes.mmaTournament,
        arguments: {
          'uniqueTournamentId': event.tournament?.uniqueTournament?.id ?? 0,
          'tournamentId': event.tournament?.id ?? 0,
          'name': event.tournament?.name ?? '',
        },
      );
      return;
    }
    Navigator.of(context).pushNamed(
      AppRoutes.sofascoreMatchDetail,
      arguments: {'eventId': event.id, 'sportSlug': slug},
    );
  }
}

/// Port khối `toolbar` trong `fragment_home.xml`: pill chọn môn
/// (`bg_sport_selector_pill` — nền 10% cam, viền 1.5dp cam) + 3 icon.
/// Nút Premium của bản gốc đã bỏ theo yêu cầu.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.sportSlug, required this.onSportTap});

  final String sportSlug;
  final VoidCallback onSportTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.sdp(16),
          vertical: AppDimens.sdp(4),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onSportTap,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.sportPillFill,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.brandAccent, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: SportIcon(slug: sportSlug),
                    ),
                    SizedBox(width: AppDimens.sdp(6)),
                    Text(
                      SportPresentation.label(sportSlug),
                      style: AppTextStyles.medium(
                        size: 14,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SvgPicture.asset(
                      'assets/icons/drop_home.svg',
                      width: 10,
                      height: 10,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            _ToolbarIcon(
              asset: 'assets/icons/ic_search.svg',
              size: AppDimens.sdp(25),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.search),
            ),
            _ToolbarIcon(
              asset: 'assets/icons/ic_notihome.svg',
              size: AppDimens.sdp(25),
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.notification),
            ),
            _ToolbarIcon(
              asset: 'assets/icons/ic_setting.svg',
              size: AppDimens.sdp(24),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
            ),
            // `ivPremium` 22sdp — chỉ hiện khi bật tính năng và chưa mua gói.
            if (PremiumManager.featureEnabled)
              ValueListenableBuilder<bool>(
                valueListenable: sl<PremiumManager>().isPremiumNotifier,
                builder: (context, premium, _) => premium
                    ? const SizedBox.shrink()
                    : _ToolbarIcon(
                        asset: 'assets/icons/ic_premium_no_ads.svg',
                        size: AppDimens.sdp(22),
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.premium),
                      ),
              ),
          ],
        ),
      );
}

class _ToolbarIcon extends StatelessWidget {
  const _ToolbarIcon({
    required this.asset,
    required this.size,
    required this.onTap,
  });

  final String asset;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: AppDimens.sdp(16)),
        child: GestureDetector(
          onTap: onTap,
          child: SvgPicture.asset(asset, width: size, height: size),
        ),
      );
}
