import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../domain/entities/match_entities.dart';

/// Port 1:1 `item_live_match.xml` + `LiveMatchAdapter`:
/// thẻ 210x130sdp, nền `iv_bg_live_match`, logo 53sdp hai bên,
/// tỉ số 18ssp ở giữa, badge phút nền xanh `bg_radius_16_0f`,
/// và nút "Details" nền cam `bg_tv_details` cao 32sdp.
class LiveMatchCard extends StatelessWidget {
  const LiveMatchCard({super.key, required this.match, required this.onTap});

  final LiveMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      width: AppDimens.sdp(210),
      height: AppDimens.sdp(130),
      margin: EdgeInsets.only(right: AppDimens.sdp(10)),
      child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.sdp(16)),
            image: const DecorationImage(
              image: AssetImage('assets/images/iv_bg_live_match.webp'),
              fit: BoxFit.fill,
            ),
            color: AppColors.itemBg,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Competitor(name: match.teamHome, logo: match.homeLogoUrl),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${match.scoreHome} - ${match.scoreAway}',
                            style: AppTextStyles.bold(
                              size: AppDimens.ssp(18),
                              color: AppColors.text500,
                            ),
                          ),
                          SizedBox(height: AppDimens.sdp(6)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppDimens.sdp(4),
                              vertical: AppDimens.sdp(1),
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.liveTimeBadge,
                              borderRadius:
                                  BorderRadius.circular(AppDimens.sdp(30)),
                            ),
                            child: Text(
                              match.matchTime,
                              style: AppTextStyles.regular(
                                size: AppDimens.ssp(7),
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Competitor(name: match.teamAway, logo: match.awayLogoUrl),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    height: AppDimens.sdp(32),
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brandAccent,
                      borderRadius: BorderRadius.circular(AppDimens.sdp(20)),
                    ),
                    child: Text(
                      s.details,
                      style: AppTextStyles.semiBold(
                        size: AppDimens.ssp(12),
                        color: AppColors.text500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

/// `ivTeamHome` 53sdp (padding 8/4) + `tvTeamHome` rộng 52sdp, cỡ 7ssp.
class _Competitor extends StatelessWidget {
  const _Competitor({required this.name, required this.logo});

  final String name;
  final String? logo;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: AppDimens.sdp(53),
        child: Column(
          children: [
            SizedBox(
              width: AppDimens.sdp(53),
              height: AppDimens.sdp(53),
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
            SizedBox(
              width: AppDimens.sdp(52),
              child: Text(
                name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(7),
                  color: AppColors.text500,
                ),
              ),
            ),
          ],
        ),
      );
}
