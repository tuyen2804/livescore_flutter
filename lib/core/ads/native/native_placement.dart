import 'package:flutter/material.dart';

/// Model cho `placement_config` — xem `docs/ADS_NATIVE_DESIGN.md`.
///
/// Config gốc đặt tên lẫn lộn snake_case với camelCase, có chỗ còn thừa dấu
/// cách đầu chuỗi. Mọi hàm đọc ở đây đều chấp cả hai kiểu và `trim()` trước.

// ---------------------------------------------------------------- tiện ích

/// Lấy giá trị đầu tiên khác null trong danh sách khoá — dùng cho các trường
/// có hai cách đặt tên (`bg_color` vs `layoutBackgroundColor`).
Object? _pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    final v = json[k];
    if (v != null && v != '') return v;
  }
  return null;
}

String? _str(Object? v) {
  if (v == null) return null;
  final s = '$v'.trim();
  return s.isEmpty ? null : s;
}

int? _int(Object? v) => switch (v) {
      int() => v,
      num() => v.toInt(),
      String() => int.tryParse(v.trim()),
      _ => null,
    };

double? _double(Object? v) => switch (v) {
      num() => v.toDouble(),
      String() => double.tryParse(v.trim()),
      _ => null,
    };

/// `"#FFA600"` hoặc `"#B3000000"` (có alpha) hoặc số nguyên.
Color? parseAdColor(Object? v) {
  if (v == null) return null;
  if (v is int) return Color(v);
  final s = '$v'.trim();
  if (s.isEmpty) return null;
  final hex = s.startsWith('#') ? s.substring(1) : s;
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return null;
  // 6 ký tự = không có alpha → mặc định đục.
  return Color(hex.length <= 6 ? 0xFF000000 | value : value);
}

// ---------------------------------------------------------------- style

/// Phần `style` sau khi gọt: chỉ còn 5 trường thật sự có nhiều giá trị.
@immutable
class AdStyle {
  const AdStyle({
    this.bgColor,
    this.headlineColor,
    this.bodyColor,
    this.headlineTextSizeSp,
    this.ctaShape,
  });

  final Color? bgColor;
  final Color? headlineColor;
  final Color? bodyColor;
  final double? headlineTextSizeSp;

  /// `ROUNDED_RECT` hoặc `PILL`. Bo góc suy ra từ đây: 10 và 24.
  final String? ctaShape;

  static const AdStyle empty = AdStyle();

  factory AdStyle.fromJson(Map<String, dynamic> json) => AdStyle(
        bgColor: parseAdColor(_pick(json, ['bg_color', 'layoutBackgroundColor'])),
        headlineColor:
            parseAdColor(_pick(json, ['headline_color', 'headlineColor'])),
        bodyColor: parseAdColor(_pick(json, ['body_color', 'bodyColor'])),
        headlineTextSizeSp: _double(
            _pick(json, ['headline_text_size_sp', 'headlineTextSizeSp'])),
        ctaShape: _str(_pick(json, ['cta_shape', 'ctaShape'])),
      );

  /// Style của slot đè lên style của union.
  AdStyle mergeOver(AdStyle? base) => AdStyle(
        bgColor: bgColor ?? base?.bgColor,
        headlineColor: headlineColor ?? base?.headlineColor,
        bodyColor: bodyColor ?? base?.bodyColor,
        headlineTextSizeSp: headlineTextSizeSp ?? base?.headlineTextSizeSp,
        ctaShape: ctaShape ?? base?.ctaShape,
      );

  /// Truyền xuống `NativeAdFactory` của Android/iOS qua `customOptions`.
  Map<String, Object> toCustomOptions() {
    final out = <String, Object>{};
    if (bgColor != null) out['bg_color'] = bgColor!.toARGB32();
    if (headlineColor != null) {
      out['headline_color'] = headlineColor!.toARGB32();
    }
    if (bodyColor != null) out['body_color'] = bodyColor!.toARGB32();
    if (headlineTextSizeSp != null) {
      out['headline_text_size_sp'] = headlineTextSizeSp!;
    }
    if (ctaShape != null) out['cta_shape'] = ctaShape!;
    return out;
  }
}

// ---------------------------------------------------------------- load policy

/// Bốn giá trị hợp lệ của `reload_mode`. Chuỗi có thể ghép bằng `|`.
enum ReloadMode {
  manual,
  autoOnClose,
  autoInterval,
  autoOnCloseAndInterval;

  bool get onClose =>
      this == autoOnClose || this == autoOnCloseAndInterval;
  bool get onInterval =>
      this == autoInterval || this == autoOnCloseAndInterval;

  /// `LiveScore_native_fullscreen` khai `"ON_DEMAND"` — không nằm trong 4 giá
  /// trị hợp lệ, có lẽ lẫn với `load_prepare_mode`. Hiểu là [manual].
  static ReloadMode parse(Object? raw) {
    final s = _str(raw)?.toUpperCase() ?? '';
    final hasClose = s.contains('AUTO_ON_CLOSE');
    final hasInterval = s.contains('AUTO_INTERVAL');
    if (hasClose && hasInterval) return autoOnCloseAndInterval;
    if (hasClose) return autoOnClose;
    if (hasInterval) return autoInterval;
    return manual;
  }
}

@immutable
class LoadPolicy {
  const LoadPolicy({
    this.reloadMode = ReloadMode.manual,
    this.reloadIntervalSec = 0,
  });

  final ReloadMode reloadMode;
  final int reloadIntervalSec;

  static const LoadPolicy none = LoadPolicy();

  factory LoadPolicy.fromJson(Map<String, dynamic> json) => LoadPolicy(
        reloadMode: ReloadMode.parse(_pick(json, ['reload_mode', 'reloadMode'])),
        reloadIntervalSec:
            _int(_pick(json, ['reload_interval_sec', 'reloadIntervalSec'])) ?? 0,
      );
}

// ---------------------------------------------------------------- button seq

enum ButtonStepType {
  countdown,
  close,
  next,
  redirect,
  collapse,
  back,
  none;

  static ButtonStepType parse(Object? raw) =>
      switch (_str(raw)?.toUpperCase()) {
        'COUNTDOWN' => countdown,
        'CLOSE' => close,
        'NEXT' => next,
        'REDIRECT' => redirect,
        'COLLAPSE' => collapse,
        'BACK' => back,
        _ => none,
      };
}

enum ButtonPosition {
  topStart,
  topEnd,
  bottomStart,
  bottomEnd;

  static ButtonPosition parse(Object? raw) =>
      switch (_str(raw)?.toUpperCase()) {
        'TOP_START' => topStart,
        'BOTTOM_START' => bottomStart,
        'BOTTOM_END' => bottomEnd,
        _ => topEnd, // mặc định của SDK
      };

  Alignment get alignment => switch (this) {
        topStart => Alignment.topLeft,
        topEnd => Alignment.topRight,
        bottomStart => Alignment.bottomLeft,
        bottomEnd => Alignment.bottomRight,
      };
}

/// `shape` của một nút trong chuỗi.
enum StepShape {
  circle,
  roundedRect,
  none;

  static StepShape parse(Object? raw) => switch (_str(raw)?.toUpperCase()) {
        'CIRCLE' => circle,
        'NONE' => none,
        _ => roundedRect,
      };
}

@immutable
class StepStyle {
  const StepStyle({
    this.shape = StepShape.roundedRect,
    this.sizeDp = 36,
    this.bgColor,
    this.iconColor,
    this.symbolScale = 0.4,
    this.iconTextSizeSp = 14,
    this.strokeWidthDp = 0,
    this.strokeColor,
    this.cornerRadiusDp = 8,
    this.progressColor,
    this.progressStrokeDp = 2.5,
  });

  final StepShape shape;
  final double sizeDp;
  final Color? bgColor;
  final Color? iconColor;
  final double symbolScale;
  final double iconTextSizeSp;
  final double strokeWidthDp;
  final Color? strokeColor;
  final double cornerRadiusDp;
  final Color? progressColor;
  final double progressStrokeDp;

  static const StepStyle fallback = StepStyle();

  /// Config dùng lẫn `size_dp` và `sizeDp`, `corner_radius_dp` và
  /// `cornerRadiusDp`… nên khoá nào cũng phải thử cả hai.
  factory StepStyle.fromJson(Map<String, dynamic> json) => StepStyle(
        shape: StepShape.parse(_pick(json, ['shape'])),
        sizeDp: _double(_pick(json, ['size_dp', 'sizeDp'])) ?? 36,
        bgColor: parseAdColor(_pick(json, ['bg_color', 'bgColor'])) ??
            const Color(0xB3000000),
        iconColor: parseAdColor(_pick(json, ['icon_color', 'iconColor'])) ??
            const Color(0xFFFFFFFF),
        symbolScale:
            _double(_pick(json, ['symbol_scale', 'symbolScale'])) ?? 0.4,
        iconTextSizeSp:
            _double(_pick(json, ['icon_text_size_sp', 'iconTextSizeSp'])) ?? 14,
        strokeWidthDp:
            _double(_pick(json, ['stroke_width_dp', 'strokeWidthDp'])) ?? 0,
        strokeColor: parseAdColor(_pick(json, ['stroke_color', 'strokeColor'])),
        cornerRadiusDp:
            _double(_pick(json, ['corner_radius_dp', 'cornerRadiusDp'])) ?? 8,
        progressColor:
            parseAdColor(_pick(json, ['progress_color', 'progressColor'])) ??
                const Color(0xCCFFFFFF),
        progressStrokeDp:
            _double(_pick(json, ['progress_stroke_dp', 'progressStrokeDp'])) ??
                2.5,
      );
}

@immutable
class ButtonStep {
  const ButtonStep({
    required this.type,
    this.position = ButtonPosition.topEnd,
    this.symbol,
    this.text,
    this.durationMs = 0,
    this.withPrevious = false,
    this.style = StepStyle.fallback,
  });

  final ButtonStepType type;
  final ButtonPosition position;

  /// Một trong 14 symbol của SDK; null thì suy từ [type].
  final String? symbol;

  /// `""` = không nhãn. null với REDIRECT thì SDK gốc tự điền "Open Store".
  final String? text;
  final int durationMs;

  /// true = hiện song song với step trước thay vì thay thế nó.
  final bool withPrevious;
  final StepStyle style;

  factory ButtonStep.fromJson(Map<String, dynamic> json) {
    final rawStyle = json['style'];
    return ButtonStep(
      type: ButtonStepType.parse(json['type']),
      position: ButtonPosition.parse(json['position']),
      symbol: _str(json['symbol']),
      // Phân biệt "không khai" với "khai chuỗi rỗng" — chuỗi rỗng có nghĩa.
      text: json.containsKey('text') ? '${json['text']}' : null,
      durationMs: _int(_pick(json, ['duration_ms', 'durationMs'])) ?? 0,
      withPrevious:
          _pick(json, ['with_previous', 'withPrevious']) == true,
      style: rawStyle is Map
          ? StepStyle.fromJson(Map<String, dynamic>.from(rawStyle))
          : StepStyle.fallback,
    );
  }
}

// ---------------------------------------------------------------- slot/union

@immutable
class AdSlot {
  const AdSlot({required this.ids, this.layout, this.style});

  /// Thứ tự ưu tiên: `[0]` high-floor, các phần tử sau là dự phòng.
  /// **Cả mảng chỉ tạo ra MỘT quảng cáo** — xem mục 5.1 của doc.
  final List<String> ids;
  final String? layout;
  final AdStyle? style;

  factory AdSlot.fromJson(Map<String, dynamic> json) {
    final rawIds = json['ids'];
    final rawStyle = json['style'];
    return AdSlot(
      ids: rawIds is List
          ? rawIds.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList()
          : const [],
      layout: _str(json['layout']),
      style: rawStyle is Map
          ? AdStyle.fromJson(Map<String, dynamic>.from(rawStyle))
          : null,
    );
  }
}

@immutable
class AdUnion {
  const AdUnion({
    required this.slots,
    this.buttonSequence = const [],
    this.style,
  });

  /// **Số slot = số quảng cáo hiện cùng lúc.**
  final List<AdSlot> slots;
  final List<ButtonStep> buttonSequence;
  final AdStyle? style;

  factory AdUnion.fromJson(Map<String, dynamic> json) {
    final rawSlots = json['slots'];
    final rawSeq = _pick(json, ['button_sequence', 'buttonSequence']);
    final rawStyle = json['style'];
    return AdUnion(
      slots: rawSlots is List
          ? rawSlots
              .whereType<Map>()
              .map((e) => AdSlot.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      buttonSequence: rawSeq is List
          ? rawSeq
              .whereType<Map>()
              .map((e) => ButtonStep.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      style: rawStyle is Map
          ? AdStyle.fromJson(Map<String, dynamic>.from(rawStyle))
          : null,
    );
  }

  /// Style thật của slot thứ [index] sau khi đè lên style của union.
  AdStyle styleOf(int index) {
    final base = style ?? AdStyle.empty;
    if (index < 0 || index >= slots.length) return base;
    return slots[index].style?.mergeOver(base) ?? base;
  }
}

// ---------------------------------------------------------------- placement

enum PlacementType {
  inline,
  fullscreen;

  static PlacementType parse(Object? raw) =>
      _str(raw)?.toUpperCase() == 'FULLSCREEN' ? fullscreen : inline;
}

@immutable
class NativePlacement {
  const NativePlacement({
    required this.name,
    required this.type,
    required this.unions,
    this.loadPolicy = LoadPolicy.none,
    this.gravity,
    this.bgAlpha,
  });

  final String name;
  final PlacementType type;
  final List<AdUnion> unions;
  final LoadPolicy loadPolicy;

  /// `TOP|CENTER_HORIZONTAL` — chỉ có nghĩa khi hiện dạng overlay.
  final String? gravity;
  final double? bgAlpha;

  factory NativePlacement.fromJson(String name, Map<String, dynamic> json) {
    final rawUnions = json['unions'];
    final rawPolicy = json['load_policy'] ?? json['loadPolicy'];
    // Config gốc để gravity trong `position: { gravity: ... }`; bản gọt đưa
    // thẳng lên `gravity`. Chấp cả hai.
    final rawPosition = json['position'];
    return NativePlacement(
      name: name,
      type: PlacementType.parse(json['type']),
      unions: rawUnions is List
          ? rawUnions
              .whereType<Map>()
              .map((e) => AdUnion.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      loadPolicy: rawPolicy is Map
          ? LoadPolicy.fromJson(Map<String, dynamic>.from(rawPolicy))
          : LoadPolicy.none,
      gravity: _str(json['gravity']) ??
          (rawPosition is Map ? _str(rawPosition['gravity']) : null),
      bgAlpha: _double(_pick(json, ['bg_alpha', 'bgAlpha'])),
    );
  }

  AdUnion? get firstUnion => unions.isEmpty ? null : unions.first;

  /// Tổng số quảng cáo phải nạp cho union đầu tiên.
  int get slotCount => firstUnion?.slots.length ?? 0;

  bool get isEmpty => unions.isEmpty || slotCount == 0;
}

/// Toàn bộ `{"placements": {...}}`.
@immutable
class NativePlacementConfig {
  const NativePlacementConfig(this.placements);

  final Map<String, NativePlacement> placements;

  static const NativePlacementConfig empty =
      NativePlacementConfig(<String, NativePlacement>{});

  bool get isEmpty => placements.isEmpty;

  NativePlacement? operator [](String name) => placements[name];

  factory NativePlacementConfig.fromJson(Map<String, dynamic> json) {
    final raw = json['placements'];
    if (raw is! Map) return empty;
    final out = <String, NativePlacement>{};
    raw.forEach((key, value) {
      if (value is Map) {
        out['$key'] = NativePlacement.fromJson(
          '$key',
          Map<String, dynamic>.from(value),
        );
      }
    });
    return NativePlacementConfig(out);
  }
}
