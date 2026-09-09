import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../domain/entities/match_entities.dart';

/// Port 1:1 `item_home_match.xml` + `HomeMatchAdapter.bind`.
///
/// Quy tắc của bản gốc:
/// - state ∈ {1, 26, 13, 19} (chưa đá / TBD): ẩn tỉ số, cột giữa hiện giờ +
///   ngày, và HIỆN nút chuông.
/// - còn lại: cột giữa hiện `status` (FT/LIVE/HT...), ẩn ngày, ẨN nút chuông.
/// - đội thắng được in đậm (màu vẫn là text500).
class HomeMatchRow extends StatelessWidget {
  const HomeMatchRow({
    super.key,
    required this.fixture,
    required this.onTap,
    required this.onToggleNotification,
    this.showDivider = true,
  });

  final MatchFixture fixture;
  final VoidCallback onTap;
  final VoidCallback onToggleNotification;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final notStarted = fixture.isNotStarted;
    final home = fixture.scoreHome ?? 0;
    final away = fixture.scoreAway ?? 0;
    final homeWins = !notStarted && home > away;
    final awayWins = !notStarted && away > home;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.sdp(10),
          vertical: AppDimens.sdp(10),
        ),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TeamLine(
                          name: fixture.teamHome,
                          logo: fixture.homeLogoUrl,
                          score: notStarted ? '' : '$home',
                          bold: homeWins,
                        ),
                        SizedBox(height: AppDimens.sdp(8)),
                        _TeamLine(
                          name: fixture.teamAway,
                          logo: fixture.awayLogoUrl,
                          score: notStarted ? '' : '$away',
                          bold: awayWins,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppDimens.sdp(12)),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),
                  SizedBox(width: AppDimens.sdp(12)),
                  SizedBox(
                    width: AppDimens.sdp(36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          notStarted ? fixture.matchTime : fixture.status,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.regular(
                            size: AppDimens.ssp(10),
                            color: AppColors.text100,
                          ),
                        ),
                        if (notStarted &&
                            (fixture.matchDate?.isNotEmpty ?? false))
                          Text(
                            fixture.matchDate!,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.regular(
                              size: AppDimens.ssp(8),
                              color: AppColors.text100,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppDimens.sdp(8)),
                  // Bản gốc chỉ hiện chuông cho trận chưa đá; trận đang/đã đá
                  // thì view bị GONE nhưng vẫn giữ chỗ để các cột thẳng hàng.
                  SizedBox(
                    width: AppDimens.sdp(18),
                    child: notStarted
                        ? GestureDetector(
                            onTap: onToggleNotification,
                            child: SvgPicture.asset(
                              fixture.isNotified
                                  ? 'assets/icons/ic_noti_select.svg'
                                  : 'assets/icons/ic_noti_unselect.svg',
                              width: AppDimens.sdp(18),
                              height: AppDimens.sdp(18),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            if (showDivider) ...[
              SizedBox(height: AppDimens.sdp(10)),
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  const _TeamLine({
    required this.name,
    required this.logo,
    required this.score,
    required this.bold,
  });

  final String name;
  final String? logo;
  final String score;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? AppTextStyles.bold(
            size: AppDimens.ssp(11),
            color: AppColors.text500,
          )
        : AppTextStyles.regular(
            size: AppDimens.ssp(11),
            color: AppColors.text500,
          );

    return Row(
      children: [
        AppImage(
          source: logo,
          width: AppDimens.sdp(16),
          height: AppDimens.sdp(16),
          placeholderAsset: 'assets/icons/ic_ball.svg',
        ),
        SizedBox(width: AppDimens.sdp(8)),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        SizedBox(width: AppDimens.sdp(8)),
        Text(score, style: style),
      ],
    );
  }
}
