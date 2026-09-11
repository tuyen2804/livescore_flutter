import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:live_score/core/ads/native/native_placement.dart';
import 'package:live_score/presentation/widgets/native/button_sequence.dart';

ButtonStep _step(Map<String, dynamic> json) => ButtonStep.fromJson(json);

Widget _host(List<ButtonStep> steps, {VoidCallback? onClose}) => MaterialApp(
  home: Scaffold(
    backgroundColor: Colors.black,
    body: ButtonSequenceRunner(steps: steps, onClose: onClose ?? () {}),
  ),
);

void main() {
  group('StepStyle mặc định theo tài liệu', () {
    test('nút thường mặc định tròn, nền #B3000000, icon trắng', () {
      final style = _step({'type': 'CLOSE'}).style;
      expect(style.shape, StepShape.circle);
      expect(style.bgColor, const Color(0xB3000000));
      expect(style.iconColor, const Color(0xFFFFFFFF));
    });

    test('khai style nhưng thiếu shape thì vẫn tròn', () {
      final style = _step({
        'type': 'COUNTDOWN',
        'style': {'size_dp': 25},
      }).style;
      expect(style.shape, StepShape.circle);
    });

    test('REDIRECT mặc định bo góc, nền #A0000000', () {
      final style = _step({'type': 'REDIRECT'}).style;
      expect(style.shape, StepShape.roundedRect);
      expect(style.bgColor, const Color(0xA0000000));
    });

    test('khai shape thì theo config', () {
      final style = _step({
        'type': 'CLOSE',
        'style': {'shape': 'ROUNDED_RECT'},
      }).style;
      expect(style.shape, StepShape.roundedRect);
    });

    test('BOTTOM_CENTER nằm giữa đáy', () {
      final step = _step({'type': 'REDIRECT', 'position': 'BOTTOM_CENTER'});
      expect(step.position.alignment, Alignment.bottomCenter);
    });
  });

  group('ButtonSequenceRunner', () {
    testWidgets('COUNTDOWN hết giờ thì sang CLOSE, bấm CLOSE thì đóng', (
      tester,
    ) async {
      var closed = 0;
      await tester.pumpWidget(
        _host([
          _step({'type': 'COUNTDOWN', 'duration_ms': 1000}),
          _step({'type': 'CLOSE'}),
        ], onClose: () => closed++),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);

      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(closed, 1);
    });

    testWidgets('with_previous: CLOSE và NEXT hiện cùng lúc sau countdown', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host([
          _step({'type': 'COUNTDOWN', 'duration_ms': 1000}),
          _step({'type': 'CLOSE'}),
          _step({
            'type': 'NEXT',
            'position': 'TOP_START',
            'with_previous': true,
          }),
        ]),
      );

      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('NONE là ô trống, không vẽ icon', (tester) async {
      await tester.pumpWidget(
        _host([
          _step({'type': 'NONE'}),
        ]),
      );
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('hết chuỗi mà chưa có CLOSE thì tự hiện nút đóng', (
      tester,
    ) async {
      var closed = 0;
      await tester.pumpWidget(
        _host([
          _step({'type': 'NEXT'}),
        ], onClose: () => closed++),
      );

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
      expect(find.byIcon(Icons.close), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(closed, 1);
    });
  });
}
