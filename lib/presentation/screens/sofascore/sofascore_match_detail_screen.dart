import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/sport_presentation.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/sofascore/sofascore_models.dart';
import '../../providers/sofascore_match_detail_provider.dart';
import 'widgets/sofa_cards.dart';
import 'widgets/sofa_widgets.dart';

/// Port `presentation/SofascoreMatchDetailActivity.kt` +
/// `activity_sofascore_match_detail.xml` — dùng đúng khung của màn bóng đá
/// (toolbar 74sdp, thẻ `ctrMatch` nền `iv_bg_live_match`, tab không gạch).
/// Tab được dựng động: chỉ hiện khi payload tương ứng có dữ liệu.
class SofascoreMatchDetailScreen extends StatelessWidget {
  const SofascoreMatchDetailScreen({
    super.key,
    required this.eventId,
    required this.sportSlug,
  });

  final int eventId;
  final String sportSlug;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => SofascoreMatchDetailProvider(sl())..load(eventId),
        child: _View(eventId: eventId, sportSlug: sportSlug),
      );
}

class _View extends StatefulWidget {
  const _View({required this.eventId, required this.sportSlug});

  final int eventId;
  final String sportSlug;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  SofaTab _tab = SofaTab.info;

  String _label(S s, SofaTab tab) => switch (tab) {
        SofaTab.info => s.infor,
        SofaTab.lineup => s.lineup,
        SofaTab.stats => s.stats,
        SofaTab.h2h => s.h2h,
        SofaTab.table => s.table,
      };

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<SofascoreMatchDetailProvider>();
    final tabs = provider.availableTabs;
    final selected = tabs.contains(_tab) ? _tab : tabs.first;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Column(
        children: [
          _Toolbar(
            title: s.liveScore,
            onRefresh: () => provider.load(widget.eventId),
          ),
          Expanded(
            child: provider.event == null
                ? (provider.failure != null
                    ? AppErrorView(
                        failure: provider.failure!,
                        onRetry: () => provider.load(widget.eventId),
                      )
                    : const AppLoading())
                : Column(
                    children: [
                      SofaScoreboardCard(
                        event: provider.event!,
                        sportSlug: widget.sportSlug,
                      ),
                      SizedBox(height: AppDimens.sdp(10)),
                      SofaTabBar(
                        labels: [for (final t in tabs) _label(s, t)],
                        selected: tabs.indexOf(selected),
                        onSelect: (i) => setState(() => _tab = tabs[i]),
                      ),
                      SizedBox(height: AppDimens.sdp(6)),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppDimens.sdp(16),
                          ),
                          child: _TabContent(tab: selected),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Port `renderSelectedTab()`.
class _TabContent extends StatelessWidget {
  const _TabContent({required this.tab});

  final SofaTab tab;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SofascoreMatchDetailProvider>();
    return switch (tab) {
      SofaTab.info => _InfoTab(provider: provider),
      SofaTab.lineup => SofaLineupsCard(provider: provider),
      SofaTab.stats => SofaStatisticsList(rows: provider.statisticRows),
      SofaTab.h2h => SofaMatchesCard(events: provider.h2hEvents),
      SofaTab.table => SofaStandingsCard(rows: provider.standingRows),
    };
  }
}

/// Port `renderInfoTab()` — đúng thứ tự thẻ của bản gốc.
class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.provider});

  final SofascoreMatchDetailProvider provider;

  @override
  Widget build(BuildContext context) {
    final event = provider.event;
    if (event == null) return const SizedBox.shrink();

    return ListView(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
      children: [
        SofaTournamentHeaderCard(event: event),
        if (!provider.isEsports)
          SofaPeriodScoresCard(
            rows: provider.periodScores,
            homeName: event.homeTeam?.displayName ?? '',
            awayName: event.awayTeam?.displayName ?? '',
          ),
        SofaEsportsGamesCard(games: provider.esportsGames),
        SofaPointByPointCard(sets: provider.pointByPointSets),
        SofaIncidentsCard(
          incidents: provider.incidents,
          homeTeamId: event.homeTeam?.id,
        ),
        SofaVotesCard(
          vote: provider.votes,
          homeName: event.homeTeam?.displayName ?? '',
          awayName: event.awayTeam?.displayName ?? '',
        ),
        SofaStandingsCard(rows: provider.standingRows, compact: true),
        SofaMatchInfoCard(event: event),
        SofaTvChannelsCard(channels: provider.tvChannels),
      ],
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.title, required this.onRefresh});

  final String title;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Container(
        height: AppDimens.sdp(74),
        color: AppColors.itemBg,
        padding: EdgeInsets.only(
          top: AppDimens.sdp(25),
          left: AppDimens.sdp(14),
          right: AppDimens.sdp(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: AppDimens.sdp(30),
                height: AppDimens.sdp(30),
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.sdp(2)),
                  child: SvgPicture.asset('assets/icons/ic_arrow_back.svg'),
                ),
              ),
            ),
            SizedBox(width: AppDimens.sdp(10)),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.medium(
                  size: AppDimens.ssp(18),
                  color: AppColors.text500,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRefresh,
              child: SvgPicture.asset(
                'assets/icons/ic_refresh.svg',
                width: AppDimens.sdp(22),
                height: AppDimens.sdp(22),
              ),
            ),
          ],
        ),
      );
}

/// Port `ctrMatch` cho nhánh Sofascore: tên trận + giải, hai bên logo 52sdp
/// (tennis dùng cờ), tỉ số 30ssp, badge nền xanh, vạch accent 20%,
/// dòng dưới hiện sân + ngày giờ.
class SofaScoreboardCard extends StatelessWidget {
  const SofaScoreboardCard({
    super.key,
    required this.event,
    required this.sportSlug,
  });

  final SofascoreEvent event;
  final String sportSlug;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final slug = event.sportSlug.isNotEmpty ? event.sportSlug : sportSlug;
    final started = SportPresentation.usesStartedEventPresentation(
      event.statusType,
    );
    final useFlag = SportPresentation.homeCompetitorImage(slug) ==
        HomeCompetitorImage.countryFlag;

    return Container(
      margin: EdgeInsets.only(
        left: AppDimens.sdp(16),
        right: AppDimens.sdp(16),
        top: AppDimens.sdp(10),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.sdp(16),
        vertical: AppDimens.sdp(10),
      ),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/iv_bg_live_match.webp'),
          fit: BoxFit.fill,
        ),
        color: AppColors.itemBg,
        borderRadius: BorderRadius.circular(AppDimens.sdp(16)),
      ),
      child: Column(
        children: [
          if (event.name?.isNotEmpty ?? false)
            Text(
              event.name!,
              textAlign: TextAlign.center,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(11),
                color: AppColors.text500,
              ),
            ),
          Text(
            event.tournament?.name ?? '',
            textAlign: TextAlign.center,
            style: AppTextStyles.regular(
              size: AppDimens.ssp(11),
              color: AppColors.brandAccent,
            ),
          ),
          SizedBox(height: AppDimens.sdp(10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Side(team: event.homeTeam, useFlag: useFlag),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      started
                          ? '${event.homeScore?.current ?? 0} - ${event.awayScore?.current ?? 0}'
                          : DateTimeUtils.formatEpochToLocalTime(
                              event.startTimestamp,
                            ),
                      style: AppTextStyles.medium(
                        size: AppDimens.ssp(30),
                        color: AppColors.text500,
                      ),
                    ),
                    SizedBox(height: AppDimens.sdp(2)),
                    Container(
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimens.sdp(10),
                        vertical: AppDimens.sdp(4),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.liveTimeBadge,
                        borderRadius: BorderRadius.circular(AppDimens.sdp(30)),
                      ),
                      child: Text(
                        event.status?.description ?? '',
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.regular(
                          size: AppDimens.ssp(10),
                          color: AppColors.color010103,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _Side(team: event.awayTeam, useFlag: useFlag),
            ],
          ),
          SizedBox(height: AppDimens.sdp(16)),
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(horizontal: AppDimens.sdp(8)),
            color: AppColors.brandAccent20,
          ),
          SizedBox(height: AppDimens.sdp(12)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(8)),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/ic_pin.svg',
                  width: AppDimens.sdp(12),
                  height: AppDimens.sdp(12),
                  colorFilter: const ColorFilter.mode(
                    AppColors.brandAccent,
                    BlendMode.srcIn,
                  ),
                ),
                SizedBox(width: AppDimens.sdp(6)),
                Expanded(
                  child: Text(
                    event.venue?.name ?? s.matchInfoTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.regular(
                      size: AppDimens.ssp(10),
                      color: AppColors.brandAccent,
                    ),
                  ),
                ),
                SizedBox(width: AppDimens.sdp(10)),
                Text(
                  DateTimeUtils.formatEpochToLocalDate(event.startTimestamp),
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(10),
                    color: AppColors.text500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `llHome` / `llAway`: logo 52sdp, tên rộng 70sdp tối đa 2 dòng, 10ssp.
class _Side extends StatelessWidget {
  const _Side({required this.team, required this.useFlag});

  final Team? team;
  final bool useFlag;

  @override
  Widget build(BuildContext context) {
    final logo = team == null
        ? null
        : (useFlag ? (team!.country?.flagUrl ?? team!.logoUrl) : team!.logoUrl);
    return SizedBox(
      width: AppDimens.sdp(86),
      child: Padding(
        padding: EdgeInsets.all(AppDimens.sdp(8)),
        child: Column(
          children: [
            SizedBox(
              width: AppDimens.sdp(52),
              height: AppDimens.sdp(52),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.sdp(8),
                  vertical: AppDimens.sdp(4),
                ),
                child: AppImage(
                  source: logo,
                  placeholderAsset: 'assets/icons/ic_ball.svg',
                ),
              ),
            ),
            SizedBox(height: AppDimens.sdp(2)),
            SizedBox(
              width: AppDimens.sdp(70),
              child: Text(
                team?.name ?? '',
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(10),
                  color: AppColors.text100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
