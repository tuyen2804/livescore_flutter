import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// Thay cho Glide: tự phân biệt URL mạng / asset SVG / asset ảnh.
/// [placeholderAsset] đóng vai `.placeholder(R.drawable.x)` của Glide —
/// hiện trong lúc tải và khi tải hỏng.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.source,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.placeholderAsset,
    this.errorWidget,
    this.color,
  });

  final String? source;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? placeholderAsset;
  final Widget? errorWidget;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    var child = _build(context);
    // Bản gốc gọi `ImageView.setColorFilter` nên tint áp cho mọi nguồn ảnh,
    // kể cả ảnh mạng và ảnh dự phòng — không riêng asset.
    if (color != null) {
      child = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: child,
      );
    }
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }

  Widget _build(BuildContext context) {
    final src = source;
    if (src == null || src.isEmpty) return _fallback();

    if (src.startsWith('http')) {
      if (src.toLowerCase().endsWith('.svg')) {
        return SvgPicture.network(
          src,
          width: width,
          height: height,
          fit: fit,
          placeholderBuilder: (context) => _fallback(),
        );
      }
      return CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder: (context, url) => _fallback(),
        errorWidget: (context, url, error) => _fallback(),
      );
    }

    if (src.endsWith('.svg')) {
      return SvgPicture.asset(
        src,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return Image.asset(
      src,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stack) => _fallback(),
    );
  }

  Widget _fallback() {
    if (errorWidget != null) return errorWidget!;

    final asset = placeholderAsset;
    if (asset != null) {
      return SvgPicture.asset(
        asset,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return SizedBox(width: width, height: height);
  }
}

/// Logo tròn của đội / giải, có viền nền như bản Android.
class TeamLogo extends StatelessWidget {
  const TeamLogo({super.key, required this.url, this.size = 32});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: AppImage(
          source: url,
          width: size,
          height: size,
          placeholderAsset: 'assets/icons/ic_ball.svg',
        ),
      );
}

/// Nền tròn xám cho ảnh thiếu — dùng ở chỗ bản gốc không có placeholder riêng.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({super.key, this.width, this.height, this.radius = 4});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.gray5,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
