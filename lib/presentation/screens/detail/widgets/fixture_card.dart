import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_image.dart';

/// Port `item_team_fixture.xml`: thẻ `bg_border_top_green` — nền `color_item_bg`
/// bo 16dp với dải accent 4dp trên cùng — padding 16sdp, marginBottom 16sdp.
/// Hàng đầu: ngày • trạng thái bên trái, chuông 20sdp bên phải.
/// Hàng dưới: hai đội logo 38sdp, giữa là viên giờ/tỉ số nền `#D2E3FF`.
class FixtureCard extends StatelessWidget {
  const FixtureCard({
    super.key,
    required this.homeName,
    required this.awayName,
    required this.centerText,
    required this.dateState,
    this.homeLogo,
    this.awayLogo,
    this.isNotified = false,
    this.onTap,
    this.onToggleNotification,
  });

  final String homeName;
  final String awayName;

  /// "02:00" khi chưa đá, "2 - 1" khi đã có tỉ số.
  final String centerText;

  /// `txtDateState` — bản gốc ghép "4/30 • TBD".
  final String dateState;
  final String? homeLogo;
  final String? awayLogo;
  final bool isNotified;
  final VoidCallback? onTap;
  final VoidCallback? onToggleNotification;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: EdgeInsets.only(bottom: AppDimens.sdp(16)),
          padding: EdgeInsets.all(AppDimens.sdp(16)),
          decoration: BoxDecoration(
            color: AppColors.itemBg,
            borderRadius: BorderRadius.circular(16),
            border: const Border(
              top: BorderSide(color: AppColors.brandAccent, width: 4),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateState,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.regular(
                        size: AppDimens.ssp(10),
                        color: AppColors.text200,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onToggleNotification,
                    child: SvgPicture.asset(
                      'assets/icons/ic_notification.svg',
                      width: AppDimens.sdp(20),
                      height: AppDimens.sdp(20),
                      colorFilter: isNotified
                          ? const ColorFilter.mode(
                              AppColors.brandAccent,
                              BlendMode.srcIn,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimens.sdp(16)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Side(name: homeName, logo: homeLogo)),
                  Padding(
                    padding: EdgeInsets.only(top: AppDimens.sdp(6)),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDimens.sdp(12),
                        vertical: AppDimens.sdp(5),
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD2E3FF),
                        borderRadius:
                            BorderRadius.circular(AppDimens.sdp(12)),
                      ),
                      child: Text(
                        centerText,
                        style: AppTextStyles.bold(
                          size: AppDimens.ssp(15),
                          color: AppColors.brandAccent,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _Side(name: awayName, logo: awayLogo)),
                ],
              ),
            ],
          ),
        ),
      );
}

class _Side extends StatelessWidget {
  const _Side({required this.name, required this.logo});

  final String name;
  final String? logo;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          AppImage(
            source: logo,
            width: AppDimens.sdp(38),
            height: AppDimens.sdp(38),
            placeholderAsset: 'assets/icons/ic_ball.svg',
          ),
          SizedBox(height: AppDimens.sdp(6)),
          Text(
            name,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.regular(
              size: AppDimens.ssp(12),
              color: AppColors.text500,
            ),
          ),
        ],
      );
}

/// Port `item_player.xml`: ảnh 38sdp nền `#e6e6e6`, tên 12ssp `text100`,
/// vị trí 10ssp `text200`, gạch dưới 1sdp `#2A2E2A`, paddingH 10sdp.
class SquadPlayerRow extends StatelessWidget {
  const SquadPlayerRow({
    super.key,
    required this.name,
    required this.position,
    this.avatarUrl,
    this.onTap,
  });

  final String name;
  final String position;
  final String? avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(10)),
          child: Column(
            children: [
              SizedBox(height: AppDimens.sdp(10)),
              Row(
                children: [
                  Container(
                    width: AppDimens.sdp(38),
                    height: AppDimens.sdp(38),
                    color: const Color(0xFFE6E6E6),
                    child: AppImage(source: avatarUrl, fit: BoxFit.cover),
                  ),
                  SizedBox(width: AppDimens.sdp(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.medium(
                            size: AppDimens.ssp(12),
                            color: AppColors.text100,
                          ),
                        ),
                        Text(
                          position,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.regular(
                            size: AppDimens.ssp(10),
                            color: AppColors.text200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimens.sdp(10)),
              Container(height: AppDimens.sdp(1), color: const Color(0xFF2A2E2A)),
            ],
          ),
        ),
      );
}
