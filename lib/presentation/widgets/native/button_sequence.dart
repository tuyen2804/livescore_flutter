import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/ads/native/native_placement.dart';

/// Máy trạng thái cho `button_sequence` — port mục 4 của
/// `docs/ADS_NATIVE_DESIGN.md`.
///
/// Chạy tuần tự từng step; `with_previous: true` thì step mới hiện **song
/// song** với step trước thay vì thay thế nó.
///
/// ## Một khác biệt bắt buộc so với SDK gốc
///
/// Step `REDIRECT` của SDK gốc mở thẳng cửa hàng. Bản Flutter **không làm
/// được**: `google_mobile_ads` không có API kích hoạt cú chạm lên native ad,
/// và tự dựng một cú chạm giả là traffic không hợp lệ — AdMob khoá tài khoản.
/// Ở đây `REDIRECT` chỉ hiển thị đúng như cấu hình rồi **chuyển sang step kế**.
/// Muốn mở cửa hàng thì user phải chạm vào chính quảng cáo.
class ButtonSequenceRunner extends StatefulWidget {
  const ButtonSequenceRunner({
    super.key,
    required this.steps,
    required this.onClose,
    this.onCollapse,
    this.onNextUnion,
    this.onPreviousUnion,
  });

  final List<ButtonStep> steps;

  /// `CLOSE` và `BACK` — đóng thật.
  final VoidCallback onClose;

  /// `COLLAPSE` — thu nhỏ, chỉ collapsible dùng.
  final VoidCallback? onCollapse;

  /// `NEXT` khi đã ở step cuối — sang union kế.
  final VoidCallback? onNextUnion;
  final VoidCallback? onPreviousUnion;

  @override
  State<ButtonSequenceRunner> createState() => _ButtonSequenceRunnerState();
}

class _ButtonSequenceRunnerState extends State<ButtonSequenceRunner> {
  /// Nút đóng dự phòng khi chuỗi đã hết mà chưa có CLOSE.
  static const ButtonStep _fallbackClose = ButtonStep(
    type: ButtonStepType.close,
  );

  Timer? _timer;
  int _countdownRemainingMs = 0;

  /// Nhóm đang hiện: bước [_current] cùng các bước ngay sau nó khai
  /// `with_previous: true`, tới [_end] (tài liệu 8.1 — hiện CÙNG LÚC, user
  /// chọn một).
  int _current = -1;
  int _end = -1;

  @override
  void initState() {
    super.initState();
    _advanceTo(0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int _groupEnd(int index) {
    var end = index;
    while (end + 1 < widget.steps.length &&
        widget.steps[end + 1].withPrevious) {
      end++;
    }
    return end;
  }

  void _advanceTo(int index) {
    _timer?.cancel();
    if (index >= widget.steps.length) {
      // Hết chuỗi mà chưa đóng: build() hiện nút đóng dự phòng, nếu không
      // user kẹt lại — fullscreen chặn nút back, iOS thì không có nút back.
      setState(() => _current = _end = widget.steps.length);
      return;
    }

    final step = widget.steps[index];
    final end = _groupEnd(index);
    setState(() {
      _current = index;
      _end = end;
      _countdownRemainingMs = step.durationMs;
    });

    // COUNTDOWN và mọi step có `duration_ms` đều tự sang nhóm kế khi hết giờ.
    if (step.durationMs > 0) {
      const tick = Duration(milliseconds: 100);
      _timer = Timer.periodic(tick, (timer) {
        if (!mounted) return;
        setState(() => _countdownRemainingMs -= tick.inMilliseconds);
        if (_countdownRemainingMs <= 0) {
          timer.cancel();
          _advanceTo(end + 1);
        }
      });
    }
  }

  void _onTap(int index) {
    final step = widget.steps[index];
    switch (step.type) {
      case ButtonStepType.close:
        widget.onClose();
      case ButtonStepType.back:
        if (widget.onPreviousUnion != null) {
          widget.onPreviousUnion!();
        } else {
          widget.onClose();
        }
      case ButtonStepType.collapse:
        (widget.onCollapse ?? widget.onClose)();
      case ButtonStepType.next:
      case ButtonStepType.redirect:
        // Nút close giả (NEXT + symbol CLOSE_X) và REDIRECT đều chỉ đi tiếp,
        // qua hết nhóm đang hiện.
        if (_end + 1 >= widget.steps.length && widget.onNextUnion != null) {
          widget.onNextUnion!();
        } else {
          _advanceTo(_end + 1);
        }
      case ButtonStepType.countdown:
      case ButtonStepType.none:
        break; // không bấm được
    }
  }

  Widget _place(ButtonStep step, Widget button) => Align(
    alignment: step.position.alignment,
    child: Padding(padding: const EdgeInsets.all(12), child: button),
  );

  @override
  Widget build(BuildContext context) {
    if (_current >= widget.steps.length) {
      return _place(
        _fallbackClose,
        _StepButton(
          step: _fallbackClose,
          remainingMs: 0,
          onTap: widget.onClose,
        ),
      );
    }

    return Stack(
      children: [
        for (var index = _current; index <= _end; index++)
          _place(
            widget.steps[index],
            _StepButton(
              step: widget.steps[index],
              remainingMs: index == _current ? _countdownRemainingMs : 0,
              onTap: () => _onTap(index),
            ),
          ),
      ],
    );
  }
}

/// Một nút trong chuỗi. `COUNTDOWN` vẽ thêm vòng tiến trình.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.step,
    required this.remainingMs,
    required this.onTap,
  });

  final ButtonStep step;
  final int remainingMs;
  final VoidCallback onTap;

  bool get _isCountdown => step.type == ButtonStepType.countdown;

  /// `text: ""` = không nhãn. Bản gốc: REDIRECT không khai text thì SDK tự
  /// điền "Open Store" — và chính vì có nhãn nên nút thành viên thuốc dù khai
  /// `shape: CIRCLE`.
  String? get _label {
    if (_isCountdown) return null;
    final text = step.text;
    if (text != null) return text.isEmpty ? null : text;
    return step.type == ButtonStepType.redirect ? 'Open Store' : null;
  }

  @override
  Widget build(BuildContext context) {
    final style = step.style;
    final size = style.sizeDp;
    // NONE là placeholder: giữ chỗ, không vẽ gì, không bấm được.
    if (step.type == ButtonStepType.none) {
      return SizedBox.square(dimension: size);
    }
    final hasLabel = _label != null;

    final radius = switch (style.shape) {
      StepShape.circle => size / 2,
      StepShape.roundedRect => style.cornerRadiusDp,
      StepShape.none => 0.0,
    };

    final child = hasLabel
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Symbol(step: step, size: size * style.symbolScale),
              const SizedBox(width: 6),
              Text(
                _label!,
                style: TextStyle(
                  color: style.iconColor,
                  fontSize: style.iconTextSizeSp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        : _isCountdown
        ? _Countdown(step: step, remainingMs: remainingMs)
        : _Symbol(step: step, size: size * style.symbolScale);

    return GestureDetector(
      onTap: _isCountdown ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: hasLabel ? null : size,
        height: size,
        alignment: Alignment.center,
        padding: hasLabel
            ? const EdgeInsets.symmetric(horizontal: 12)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: style.shape == StepShape.none ? null : style.bgColor,
          borderRadius: BorderRadius.circular(radius),
          border: style.strokeWidthDp > 0 && style.strokeColor != null
              ? Border.all(
                  color: style.strokeColor!,
                  width: style.strokeWidthDp,
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// 14 symbol của SDK, vẽ bằng icon có sẵn của Flutter.
class _Symbol extends StatelessWidget {
  const _Symbol({required this.step, required this.size});

  final ButtonStep step;
  final double size;

  IconData get _icon {
    final name = step.symbol?.toUpperCase();
    return switch (name) {
      'CLOSE_X' => Icons.close,
      'NEXT_RIGHT' => Icons.chevron_right,
      'BACK_LEFT' => Icons.chevron_left,
      'CHEVRON_DOWN' => Icons.keyboard_arrow_down,
      'CHEVRON_UP' => Icons.keyboard_arrow_up,
      'PLAY' => Icons.play_arrow,
      'PAUSE' => Icons.pause,
      'SKIP_NEXT' => Icons.skip_next,
      'REFRESH' => Icons.refresh,
      'ARROW_RIGHT' => Icons.arrow_forward,
      'ARROW_LEFT' => Icons.arrow_back,
      'DOUBLE_RIGHT' => Icons.double_arrow,
      'REDIRECT_STORE' => Icons.open_in_new,
      // Không khai symbol thì suy từ loại step.
      _ => switch (step.type) {
        ButtonStepType.close => Icons.close,
        ButtonStepType.next => Icons.chevron_right,
        ButtonStepType.back => Icons.chevron_left,
        ButtonStepType.collapse => Icons.keyboard_arrow_down,
        ButtonStepType.redirect => Icons.open_in_new,
        _ => Icons.circle,
      },
    };
  }

  @override
  Widget build(BuildContext context) =>
      Icon(_icon, size: math.max(size, 12), color: step.style.iconColor);
}

/// Vòng đếm ngược + số giây còn lại.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.step, required this.remainingMs});

  final ButtonStep step;
  final int remainingMs;

  @override
  Widget build(BuildContext context) {
    final total = step.durationMs <= 0 ? 1 : step.durationMs;
    final progress = (remainingMs / total).clamp(0.0, 1.0);
    final seconds = (remainingMs / 1000).ceil().clamp(0, 999);

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: step.style.progressStrokeDp,
            color: step.style.progressColor,
            backgroundColor: Colors.transparent,
          ),
        ),
        Text(
          '$seconds',
          style: TextStyle(
            color: step.style.iconColor,
            fontSize: step.style.iconTextSizeSp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
