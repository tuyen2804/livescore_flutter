import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/ads/native/native_placements.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../providers/match_detail_provider.dart';
import 'tabs/match_h2h_tab.dart';
import 'tabs/match_info_tab.dart';
import 'tabs/match_lineup_tab.dart';
import 'tabs/match_stats_tab.dart';
import 'tabs/match_table_tab.dart';
import '../../widgets/native/native_ad_view.dart';

/// Port `presentation/detail/MatchDetailFragment.kt` + `fragment_match_detail.xml`:
/// toolbar 74sdp (back – tiêu đề – refresh) → thẻ trận nền `iv_bg_live_match`
/// → 5 tab không có gạch chỉ báo (chọn = accent, còn lại = trắng).
class MatchDetailScreen extends StatelessWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final int matchId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) =>
            MatchDetailProvider(sl(), sl(), sl())..loadMatchDetail(matchId),
        child: _MatchDetailView(matchId: matchId),
      );
}

class _MatchDetailView extends StatefulWidget {
  const _MatchDetailView({required this.matchId});

  final int matchId;

  @override
  State<_MatchDetailView> createState() => _MatchDetailViewState();
}

class _MatchDetailViewState extends State<_MatchDetailView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<MatchDetailProvider>();

    final tabs = <String>[s.infor, s.lineup, s.stats, s.h2h, s.table];
    final pages = <Widget>[
      MatchInfoTab(matchId: widget.matchId),
      const MatchLineupTab(),
      const MatchStatsTab(),
      const MatchH2HTab(),
      const MatchTableTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Column(
        children: [
          _Toolbar(
            title: s.liveScore,
            onBack: () => Navigator.of(context).maybePop(),
            onRefresh: () => provider.loadMatchDetail(widget.matchId),
          ),
          // `LiveScore_native_Inapp` — bản gốc dùng chung placement này cho
          // Home, chi tiết trận và danh sách trận live.
          NativeAdView(
            placement: NativePlacements.inApp,
            margin: EdgeInsets.symmetric(horizontal: AppDimens.sdp(12)),
          ),
          Expanded(
            child: provider.isLoading && provider.match == null
                ? const EarthLoadingOverlay(label: 'Loading')
                : provider.failure != null && provider.match == null
                    ? AppErrorView(
                        failure: provider.failure!,
                        onRetry: () => provider.loadMatchDetail(widget.matchId),
                      )
                    : Column(
                        children: [
                          _MatchHeaderCard(provider: provider),
                          SizedBox(height: AppDimens.sdp(10)),
                          _TabBar(
                            tabs: tabs,
                            selected: _tab,
                            onSelect: (i) => setState(() => _tab = i),
                          ),
                          SizedBox(height: AppDimens.sdp(6)),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppDimens.sdp(16),
                              ),
                              child: IndexedStack(
                                index: _tab,
                                children: pages,
                              ),
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

/// Toolbar 74sdp: back 30sdp bên trái, tiêu đề 18ssp căn trái, refresh bên phải.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.title,
    required this.onBack,
    required this.onRefresh,
  });

  final String title;
  final VoidCallback onBack;
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
              onTap: onBack,
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
                style: AppTextStyles.bold(
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

/// Port `ctrMatch`: nền `iv_bg_live_match`, tên trận + tên giải ở trên,
/// hai đội hai bên, tỉ số 30ssp ở giữa, badge phút nền xanh,
/// vạch ngăn `color_brand_accent_20` rồi dòng sân vận động + vòng đấu.
class _MatchHeaderCard extends StatelessWidget {
  const _MatchHeaderCard({required this.provider});

  final MatchDetailProvider provider;

  @override
  Widget build(BuildContext context) {
    final match = provider.match;
    if (match == null) return const SizedBox.shrink();

    final s = S.of(context);

    // Bản gốc: tỉ số lấy nguyên chuỗi `score` (mặc định "0 - 0"); badge hiện
    // phút thi đấu nếu > 0, không thì hiện giờ bóng lăn theo giờ máy.
    final score = match.score ?? '0 - 0';
    final playing = match.playingTime ?? 0;
    final badge = playing > 0
        ? "$playing'"
        : (match.kickoffEpoch != null && match.kickoffEpoch! > 0
            ? DateTimeUtils.formatEpochToLocalTime(match.kickoffEpoch!)
            : DateTimeUtils.convertUtcToLocalTime(match.kickoffUtc));

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
          if (match.name?.isNotEmpty ?? false)
            Text(
              match.name!,
              textAlign: TextAlign.center,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(11),
                color: AppColors.text500,
              ),
            ),
          Text(
            match.leagueName ?? '',
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
              _Side(name: match.homeName ?? '', logo: match.homeTeamLogoUrl),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      score,
                      style: AppTextStyles.bold(
                        size: AppDimens.ssp(30),
                        color: AppColors.text500,
                      ),
                    ),
                    SizedBox(height: AppDimens.sdp(2)),
                    Container(
                      width: AppDimens.sdp(50),
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimens.sdp(10),
                        vertical: AppDimens.sdp(4),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.liveTimeBadge,
                        borderRadius:
                            BorderRadius.circular(AppDimens.sdp(30)),
                      ),
                      child: Text(
                        badge,
                        maxLines: 1,
                        style: AppTextStyles.medium(
                          size: AppDimens.ssp(10),
                          color: AppColors.color010103,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _Side(name: match.awayName ?? '', logo: match.awayTeamLogoUrl),
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
                    // Bản gốc rơi về "TBD" khi API không có sân.
                    (match.nameVenue ?? s.statusTbd).toUpperCase(),
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
                  match.roundName ?? match.groupName ?? '',
                  style: AppTextStyles.medium(
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

/// `llHome` / `llAway`: logo 52sdp (padding 8/4), tên 10ssp `text100`.
class _Side extends StatelessWidget {
  const _Side({required this.name, required this.logo});

  final String name;
  final String? logo;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: AppDimens.sdp(76),
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
              Text(
                name,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.semiBold(
                  size: AppDimens.ssp(10),
                  color: AppColors.text100,
                ),
              ),
            ],
          ),
        ),
      );
}

/// Port `bg_tab_pill.xml` + `color_tab_text.xml`: tab **chưa chọn** là viên
/// nền accent chữ trắng, tab **đang chọn** là viên trắng viền accent chữ accent.
/// Cao 28sdp, chữ 10ssp bold, mỗi viên chừa 4dp hai bên.
class _TabBar extends StatelessWidget {
  const _TabBar({
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: AppDimens.sdp(28),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(16)),
          itemCount: tabs.length,
          itemBuilder: (context, index) {
            final active = index == selected;
            return GestureDetector(
              onTap: () => onSelect(index),
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(10)),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.white : AppColors.brandAccent,
                  borderRadius: BorderRadius.circular(100),
                  border: active
                      ? Border.all(color: AppColors.brandAccent)
                      : null,
                ),
                child: Text(
                  tabs[index],
                  style: AppTextStyles.bold(
                    size: AppDimens.ssp(10),
                    color: active ? AppColors.brandAccent : AppColors.white,
                  ),
                ),
              ),
            );
          },
        ),
      );
}
