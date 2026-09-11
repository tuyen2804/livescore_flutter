import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:live_score/core/ads/native/native_ad_controller.dart';
import 'package:live_score/core/ads/native/native_ad_manager.dart';
import 'package:live_score/core/ads/native/native_placement.dart';
import 'package:live_score/core/di/injection.dart';
import 'package:live_score/presentation/widgets/native/native_fullscreen_overlay.dart';

const _placementName = 'LiveScore_native_fullscreen';

/// `AdWidget` thật cần platform view và ad đã load; test chỉ cần ô giữ chỗ.
class _FakeLoadedAd extends LoadedNativeAd {
  _FakeLoadedAd()
    : super(
        ad: NativeAd(
          adUnitId: 'test',
          factoryId: 'test',
          listener: NativeAdListener(),
          request: const AdRequest(),
        ),
        layout: 'FULLSCREEN_PORT_MEDIA_INFO_CTA',
        style: AdStyle.fromJson(const <String, dynamic>{}),
        slotId: 'test',
      );

  @override
  Widget get widget => const ColoredBox(color: Colors.blue);
}

class _FakeManager implements NativeAdManager {
  _FakeManager(this.controller);

  final NativeAdController controller;

  @override
  NativeAdController? controllerOf(String placement) => controller;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late NativeAdController controller;

  setUp(() {
    final placement = NativePlacement.fromJson(_placementName, {
      'type': 'FULLSCREEN',
      'unions': [
        {
          'slots': [
            {
              'ids': ['test'],
              'layout': 'FULLSCREEN_PORT_MEDIA_INFO_CTA',
            },
          ],
          'button_sequence': [
            {
              'type': 'CLOSE',
              'position': 'TOP_END',
              'style': {'shape': 'CIRCLE', 'size_dp': 28},
            },
          ],
        },
      ],
    });
    controller = NativeAdController(placement)
      ..ads.value = [_FakeLoadedAd()]
      ..state.value = NativeAdState.loaded;
    sl.registerSingleton<NativeAdManager>(_FakeManager(controller));
  });

  tearDown(() => sl.unregister<NativeAdManager>());

  /// Màn gọi overlay; [onClosed] chạy khi `show()` trả về.
  Widget host(VoidCallback onClosed) => MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              await NativeFullscreenOverlay.show(context, _placementName);
              onClosed();
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );

  testWidgets('bấm CLOSE thì overlay đóng và show() trả về', (tester) async {
    var closed = false;
    await tester.pumpWidget(host(() => closed = true));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(NativeFullscreenOverlay), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(NativeFullscreenOverlay), findsNothing);
    expect(closed, isTrue);
    // Chỉ đóng đúng overlay, màn bên dưới vẫn còn.
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets(
    'quảng cáo biến mất giữa chừng thì overlay tự đóng đúng một lần',
    (tester) async {
      var closedCount = 0;
      await tester.pumpWidget(host(() => closedCount++));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(NativeFullscreenOverlay), findsOneWidget);

      controller.ads.value = const [];
      await tester.pumpAndSettle();

      expect(find.byType(NativeFullscreenOverlay), findsNothing);
      expect(closedCount, 1);
      expect(find.text('open'), findsOneWidget);
    },
  );
}
