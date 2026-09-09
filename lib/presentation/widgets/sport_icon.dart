import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/sport_presentation.dart';

/// Icon môn thể thao lấy từ vector drawable gốc (đã convert sang SVG).
/// Môn nào không có file riêng thì rơi về icon Material tương đương.
class SportIcon extends StatelessWidget {
  const SportIcon({
    super.key,
    required this.slug,
    this.color = AppColors.brandAccent,
    this.size,
  });

  final String slug;
  final Color color;
  final double? size;

  /// Tên file trong `assets/icons/`, đối chiếu với `drawable/ic_*_dialog.xml`
  /// và các icon môn của bản gốc.
  static const Map<String, String> _assets = {
    'football': 'ic_football_dialog',
    'basketball': 'ic_basketball',
    'tennis': 'ic_tennis',
    'volleyball': 'ic_volleyball',
    'esports': 'ic_esports',
    'mma': 'ic_mma',
    'baseball': 'ic_baseball',
    'cricket': 'ic_cricket_bat',
    'rugby': 'ic_rugby',
    'badminton': 'ic_badminton',
    'snooker': 'ic_snooker',
    'table-tennis': 'ic_table_tennis',
  };

  @override
  Widget build(BuildContext context) {
    final name = _assets[slug.toLowerCase()];
    if (name == null) {
      return Icon(SportPresentation.icon(slug), size: size, color: color);
    }
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      placeholderBuilder: (context) =>
          Icon(SportPresentation.icon(slug), size: size, color: color),
    );
  }
}
