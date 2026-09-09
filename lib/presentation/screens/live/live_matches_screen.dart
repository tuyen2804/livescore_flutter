import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../widgets/settings_toolbar.dart';
import '../../../domain/entities/match_entities.dart';
import '../../providers/home_provider.dart';

/// Port `presentation/live/LiveMatchesFragment.kt` +
/// `VerticalLiveMatchAdapter` (`item_live_match_vertical.xml`).
class LiveMatchesScreen extends StatelessWidget {
  const LiveMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<HomeProvider>();
    final matches = provider.allLiveMatches;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Column(
        children: [
          SettingsToolbar(
            title: s.liveS,
            trailing: GestureDetector(
              onTap: provider.refreshData,
              child: SvgPicture.asset(
                'assets/icons/ic_refresh.svg',
                width: AppDimens.sdp(22),
                height: AppDimens.sdp(22),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.brandAccent,
              backgroundColor: AppColors.itemBg,
              onRefresh: provider.refreshData,
              child: provider.isLoading && matches.isEmpty
                  ? const EarthLoadingOverlay(label: 'Loading')
                  : matches.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: AppDimens.sdp(60)),
                            AppEmptyView(message: s.theFieldIsQuiteEmpty),
                          ],
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(
                            left: AppDimens.sdp(12),
                            right: AppDimens.sdp(12),
                            top: AppDimens.sdp(12),
                          ),
                          itemCount: matches.length,
                          itemBuilder: (context, index) => _LiveRow(
                            match: matches[index],
                            onTap: () => Navigator.of(context).pushNamed(
                              provider.isFootball
                                  ? AppRoutes.matchDetail
                                  : AppRoutes.sofascoreMatchDetail,
                              arguments: provider.isFootball
                                  ? {
                                      'matchId':
                                          int.tryParse(matches[index].id) ?? 0,
                                    }
                                  : {
                                      'eventId':
                                          int.tryParse(matches[index].id) ?? 0,
                                      'sportSlug': provider.selectedSport,
                                    },
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Port `item_live_match_page.xml` — layout `VerticalLiveMatchAdapter` thực sự
/// inflate: thẻ cao 160sdp nền `iv_bg_live_match`, marginH 16sdp
/// marginBottom 12sdp. Trong thẻ: tên giải 11ssp bold ở giữa trên, hai logo
/// 58/52sdp hai bên, tỉ số 22ssp bold ở giữa, viên phút 8ssp chữ đen nền
/// `#09CC3D`, vạch 1.5dp `color_brand_accent_20`, rồi dòng sân + khu vực.
class _LiveRow extends StatelessWidget {
  const _LiveRow({required this.match, required this.onTap});

  final LiveMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: AppDimens.sdp(160),
          margin: EdgeInsets.only(
            left: AppDimens.sdp(16),
            right: AppDimens.sdp(16),
            bottom: AppDimens.sdp(12),
          ),
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/images/iv_bg_live_match.webp'),
              fit: BoxFit.fill,
            ),
            color: AppColors.itemBg,
            borderRadius: BorderRadius.circular(AppDimens.sdp(16)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: AppDimens.sdp(8),
              right: AppDimens.sdp(8),
              top: AppDimens.sdp(12),
              bottom: AppDimens.sdp(8),
            ),
            child: Column(
              children: [
                Text(
                  match.leagueName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bold(
                    size: AppDimens.ssp(11),
                    color: AppColors.text500,
                  ),
                ),
                SizedBox(height: AppDimens.sdp(8)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: AppDimens.sdp(16)),
                    _Side(
                      name: match.teamHome,
                      logo: match.homeLogoUrl,
                      logoSize: AppDimens.sdp(58),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox(height: AppDimens.sdp(10)),
                          Text(
                            '${match.scoreHome} - ${match.scoreAway}',
                            style: AppTextStyles.bold(
                              size: AppDimens.ssp(22),
                              color: AppColors.text500,
                            ),
                          ),
                          SizedBox(height: AppDimens.sdp(6)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimens.sdp(4),
                              vertical: AppDimens.sdp(2),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.liveTimeBadge,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.sdp(30)),
                            ),
                            child: Text(
                              match.matchTime,
                              style: AppTextStyles.regular(
                                size: AppDimens.ssp(8),
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Side(
                      name: match.teamAway,
                      logo: match.awayLogoUrl,
                      logoSize: AppDimens.sdp(52),
                    ),
                    SizedBox(width: AppDimens.sdp(16)),
                  ],
                ),
                SizedBox(height: AppDimens.sdp(12)),
                Container(
                  height: 1.5,
                  margin: EdgeInsets.symmetric(horizontal: AppDimens.sdp(6)),
                  color: AppColors.brandAccent20,
                ),
                const Spacer(),
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
                      SizedBox(width: AppDimens.sdp(9)),
                      Expanded(
                        child: Text(
                          (match.venue ?? 'No Stadium').toUpperCase(),
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
                        match.region ?? '',
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
          ),
        ),
      );
}

/// Logo (padding 8/4) rồi tên đội 10ssp viết hoa, khung rộng 52sdp.
class _Side extends StatelessWidget {
  const _Side({
    required this.name,
    required this.logo,
    required this.logoSize,
  });

  final String name;
  final String? logo;
  final double logoSize;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: AppDimens.sdp(52),
        child: Column(
          children: [
            SizedBox(
              width: logoSize,
              height: logoSize,
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
            SizedBox(height: AppDimens.sdp(4)),
            Text(
              name.toUpperCase(),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(10),
                color: AppColors.text500,
              ),
            ),
          ],
        ),
      );
}
