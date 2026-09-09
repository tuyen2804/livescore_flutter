import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// Port `EarthLoadingView.kt` + `view_earth_loading.xml`: nền `bg_anim_loading`,
/// hai lớp `OrbitRingsView` (sau/trước), Trái Đất 180dp và chiếc cúp 90dp bay
/// theo quỹ đạo elip nghiêng -20°, một vòng 2000ms.
class EarthLoadingView extends StatefulWidget {
  const EarthLoadingView({super.key});

  @override
  State<EarthLoadingView> createState() => _EarthLoadingViewState();
}

class _EarthLoadingViewState extends State<EarthLoadingView>
    with SingleTickerProviderStateMixin {
  /// `orbitDurationMs = 2000f` của bản gốc.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // `angle = elapsed / duration * 360` — không wrap để khỏi giật.
          final angle = _controller.value * 360;
          final rad = angle * math.pi / 180;

          // Quỹ đạo khớp `rect1` của OrbitRingsView.
          const radiusX = 320.0;
          const radiusY = 96.0;
          const tilt = -20 * math.pi / 180;

          final x = radiusX * math.cos(rad);
          final y = radiusY * math.sin(rad);
          final rotatedX = x * math.cos(tilt) - y * math.sin(tilt);
          final rotatedY = x * math.sin(tilt) + y * math.cos(tilt);

          final scale = 0.6 + 0.3 * math.sin(rad);
          // Cúp chui ra sau Trái Đất ở nửa vòng phía trên.
          final cupBehind = math.sin(rad) <= 0;

          // Cả cụm dịch lên 280sdp + 30px như `layout_marginBottom` gốc.
          final offsetY = -AppDimens.sdp(280) / 2 - 30;

          final cup = Transform.translate(
            offset: Offset(rotatedX, rotatedY + offsetY - 30),
            child: Transform.scale(
              scale: scale,
              child: Image.asset(
                'assets/images/ic_cup.webp',
                width: 90,
                height: 90,
              ),
            ),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/bg_anim_loading.webp',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    const ColoredBox(color: AppColors.bgApp),
              ),
              Center(
                child: Transform.translate(
                  offset: Offset(0, offsetY),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _OrbitRingsPainter(
                      rotationPhase: angle,
                      isFrontPart: false,
                    ),
                  ),
                ),
              ),
              if (cupBehind) Center(child: cup),
              Center(
                child: Transform.translate(
                  offset: Offset(0, offsetY),
                  child: Image.asset(
                    'assets/images/ic_earth.webp',
                    width: 180,
                    height: 180,
                  ),
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: Offset(0, offsetY),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _OrbitRingsPainter(
                      rotationPhase: angle,
                      isFrontPart: true,
                    ),
                  ),
                ),
              ),
              if (!cupBehind) Center(child: cup),
            ],
          );
        },
      );
}

/// Port `OrbitRingsView.kt`: 4 quỹ đạo elip, mỗi quỹ đạo vẽ chuỗi "tia lửa"
/// gồm 7 lớp path (2 lớp quầng, 2 tua, 2 viền và lõi trắng).
class _OrbitRingsPainter extends CustomPainter {
  const _OrbitRingsPainter({
    required this.rotationPhase,
    required this.isFrontPart,
  });

  final double rotationPhase;
  final bool isFrontPart;

  static final Paint _glow = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x30B8860B);
  static final Paint _outerGlow = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x18B8860B);
  static final Paint _coreBorder = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF7B4E20);
  static final Paint _altBorder = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFFD700);
  static final Paint _innerCore = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFFFFFF);
  static final Paint _wispy = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFFFFD54F);

  static const Rect _rect1 = Rect.fromLTRB(-320, -96, 320, 96);
  static const Rect _rect2 = Rect.fromLTRB(-304, -88, 304, 88);
  static const Rect _rect3 = Rect.fromLTRB(-336, -104, 336, 104);
  static const Rect _rect4 = Rect.fromLTRB(-416, -224, 416, 224);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-20 * math.pi / 180);

    canvas.clipRect(
      isFrontPart
          ? const Rect.fromLTRB(-1500, 0, 1500, 1500)
          : const Rect.fromLTRB(-1500, -1500, 1500, 0),
    );

    final speed = rotationPhase * 4.5;
    _draw(canvas, _rect1, 600, 2.7, 840, speed);
    _draw(canvas, _rect2, 200, 1.0, 630, speed + 560, reverse: true);
    _draw(canvas, _rect3, 160, 0.7, 490, speed - 400);

    final wobble = math.sin(rotationPhase * 3) * 16;
    _draw(canvas, _rect4, 210, 1.3, 2100, 560 + wobble);

    canvas.restore();
  }

  /// Port `drawSparkFibers`.
  void _draw(
    Canvas canvas,
    Rect oval,
    double sparkLength,
    double scale,
    double advance,
    double phaseOffset, {
    bool reverse = false,
  }) {
    final orbit = Path()..addOval(oval);
    final metrics = orbit.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final length = metric.length;
    if (length == 0) return;

    final sparkCount = (length / advance).ceil();
    final baseOffset = phaseOffset % length;
    const steps = 40;
    final stepSize = sparkLength / steps;
    final dir = reverse ? 1.0 : -1.0;

    for (var idx = 0; idx < sparkCount; idx++) {
      var headDist = baseOffset + idx * advance;
      headDist = ((headDist % length) + length) % length;

      final glowPath = Path();
      final outerGlowPath = Path();
      final coreBorderPath = Path();
      final altBorderPath = Path();
      final innerCorePath = Path();
      final wispyLeftPath = Path();
      final wispyRightPath = Path();

      for (var pass = 0; pass <= 1; pass++) {
        final start = pass == 0 ? 0 : steps;
        final end = pass == 0 ? steps : 0;
        final step = pass == 0 ? 1 : -1;

        for (var i = start; pass == 0 ? i <= end : i >= end; i += step) {
          final d = headDist + dir * (i * stepSize);
          var wrapped = d % length;
          if (wrapped < 0) wrapped += length;

          final tangent = metric.getTangentForOffset(wrapped);
          if (tangent == null) continue;
          final px = tangent.position.dx;
          final py = tangent.position.dy;
          final nx = -tangent.vector.dy;
          final ny = tangent.vector.dx;

          final t = 1 - (i / steps);
          final baseWidth =
              t > 0.8 ? 4 * ((1 - t) / 0.2) : 4 * (t / 0.8);
          final coreWidth = baseWidth * scale;

          final glowW = coreWidth * 3.5 / 2;
          final outerGlowW = coreWidth * 5 / 2;
          final innerW = coreWidth * 0.75 / 2;

          final twist = math.sin(t * 25) * (coreWidth * 0.45);
          final b1W = coreWidth * 1.1 / 2;
          final b1cx = px + nx * twist;
          final b1cy = py + ny * twist;
          final b2W = coreWidth * 0.8 / 2;
          final b2cx = px - nx * twist;
          final b2cy = py - ny * twist;

          final deviation = (1 - t) * (1 - t) * 4 * scale;
          final wW = coreWidth * 0.4 / 2;
          final w1cx = px + nx * deviation;
          final w1cy = py + ny * deviation;
          final w2cx = px - nx * deviation;
          final w2cy = py - ny * deviation;

          final edge = pass == 0 ? 1.0 : -1.0;
          final points = <Path, Offset>{
            glowPath: Offset(px + nx * glowW * edge, py + ny * glowW * edge),
            outerGlowPath:
                Offset(px + nx * outerGlowW * edge, py + ny * outerGlowW * edge),
            innerCorePath:
                Offset(px + nx * innerW * edge, py + ny * innerW * edge),
            coreBorderPath:
                Offset(b1cx + nx * b1W * edge, b1cy + ny * b1W * edge),
            altBorderPath:
                Offset(b2cx + nx * b2W * edge, b2cy + ny * b2W * edge),
            wispyLeftPath: Offset(w1cx + nx * wW * edge, w1cy + ny * wW * edge),
            wispyRightPath: Offset(w2cx + nx * wW * edge, w2cy + ny * wW * edge),
          };

          final first = pass == 0 && i == 0;
          points.forEach((path, point) {
            if (first) {
              path.moveTo(point.dx, point.dy);
            } else {
              path.lineTo(point.dx, point.dy);
            }
          });
        }
      }

      canvas.drawPath(outerGlowPath..close(), _outerGlow);
      canvas.drawPath(glowPath..close(), _glow);
      canvas.drawPath(wispyLeftPath..close(), _wispy);
      canvas.drawPath(wispyRightPath..close(), _wispy);
      canvas.drawPath(coreBorderPath..close(), _coreBorder);
      canvas.drawPath(altBorderPath..close(), _altBorder);
      canvas.drawPath(innerCorePath..close(), _innerCore);
    }
  }

  @override
  bool shouldRepaint(_OrbitRingsPainter old) =>
      old.rotationPhase != rotationPhase || old.isFrontPart != isFrontPart;
}

/// Port `layoutLoading` trong `fragment_home.xml`: hiệu ứng Trái Đất phủ kín
/// màn hình, thêm dòng "Loading" 17ssp bold kèm shimmer "..." 22ssp,
/// đẩy lên 100sdp so với tâm.
class EarthLoadingOverlay extends StatelessWidget {
  const EarthLoadingOverlay({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const EarthLoadingView(),
          Center(
            child: Transform.translate(
              offset: Offset(0, -AppDimens.sdp(100) / 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bold(
                      size: AppDimens.ssp(17),
                      color: AppColors.white,
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: AppColors.white.withValues(alpha: 0.3),
                    highlightColor: AppColors.white,
                    period: const Duration(milliseconds: 800),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: AppDimens.sdp(2)),
                      child: Text(
                        '...',
                        style: AppTextStyles.bold(
                          size: AppDimens.ssp(22),
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}
