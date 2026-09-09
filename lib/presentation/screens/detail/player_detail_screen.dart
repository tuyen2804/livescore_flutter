import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../widgets/settings_toolbar.dart';

/// Port `presentation/detail/PlayerDetailFragment.kt` +
/// `fragment_detail_player.xml`: toolbar 74sdp chỉ có nút back, ảnh 90sdp
/// nền `#e6e6e6`, tên 20ssp bold, rồi một thẻ `bg_league_grid_item` chứa
/// 8 dòng thông tin. Dữ liệu đến qua arguments, thiếu thì hiện "-".
class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({
    super.key,
    required this.playerName,
    required this.playerPos,
    required this.teamName,
    this.playerImg,
    this.playerHeight,
    this.playerWeight,
    this.playerAge,
    this.playerNumber,
    this.playerNationality,
  });

  final String playerName;
  final String playerPos;
  final String teamName;
  final String? playerImg;
  final String? playerHeight;
  final String? playerWeight;
  final String? playerAge;
  final String? playerNumber;
  final String? playerNationality;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Column(
        children: [
          const SettingsToolbar(title: ''),
          SizedBox(height: AppDimens.sdp(16)),
          Container(
            width: AppDimens.sdp(90),
            height: AppDimens.sdp(90),
            color: const Color(0xFFE6E6E6),
            child: AppImage(source: playerImg, fit: BoxFit.cover),
          ),
          SizedBox(height: AppDimens.sdp(14)),
          Text(
            playerName.isEmpty ? s.unknown : playerName,
            style: AppTextStyles.bold(
              size: AppDimens.ssp(20),
              color: AppColors.text500,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(
                left: AppDimens.sdp(14),
                right: AppDimens.sdp(14),
                top: AppDimens.sdp(20),
                bottom: AppDimens.sdp(10),
              ),
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.sdp(20),
                    vertical: AppDimens.sdp(18),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.itemBg,
                    borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
                  ),
                  child: Column(
                    children: [
                      _Row(label: s.club, value: teamName, isFirst: true),
                      _Row(label: s.position, value: playerPos),
                      _Row(label: s.height, value: playerHeight),
                      _Row(label: s.age, value: playerAge),
                      _Row(label: s.shirt, value: playerNumber),
                      _Row(label: s.preferFoot, value: null),
                      _Row(label: s.weight, value: playerWeight),
                      _Row(label: s.nationality, value: playerNationality),
                    ],
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

/// Nhãn 13ssp `text200` bên trái, giá trị 13ssp `text500` bên phải
/// cách 10sdp; các dòng sau cách dòng trước 20sdp.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.isFirst = false});

  final String label;
  final String? value;
  final bool isFirst;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: isFirst ? 0 : AppDimens.sdp(20)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(13),
                color: AppColors.text200,
              ),
            ),
            SizedBox(width: AppDimens.sdp(10)),
            Expanded(
              child: Text(
                (value == null || value!.isEmpty) ? '-' : value!,
                textAlign: TextAlign.end,
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(13),
                  color: AppColors.text500,
                ),
              ),
            ),
          ],
        ),
      );
}
