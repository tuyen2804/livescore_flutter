import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:live_score/core/ads/native/native_ad_controller.dart';
import 'package:live_score/core/ads/native/native_ad_heights.dart';
import 'package:live_score/core/ads/native/native_ad_manager.dart';
import 'package:live_score/core/ads/native/native_placement.dart';
import 'package:live_score/core/di/injection.dart';
import 'package:live_score/presentation/widgets/native/native_ad_view.dart';

const _placementName = 'LiveScore_native_OB';
const _adKey = Key('ad');

/// `AdWidget` thật cần platform view và ad đã load; test chỉ cần ô giữ chỗ.
class _FakeLoadedAd extends LoadedNativeAd {
  _FakeLoadedAd(String slotId)
    : super(
        ad: NativeAd(
          adUnitId: 'test',
          factoryId: 'test',
          listener: NativeAdListener(),
          request: const AdRequest(),
        ),
        layout: 'FULLSIZE_MEDIA_INFO_CTA',
        style: AdStyle.fromJson(const <String, dynamic>{}),
        slotId: slotId,
      );

  @override
  Widget get widget => const ColoredBox(key: _adKey, color: Colors.blue);
}

class _FakeManager implements NativeAdManager {
  _FakeManager(this.controller);

  final NativeAdController controller;

  @override
  NativeAdController? controllerOf(String placement) => controller;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Giả lập factory native báo chiều cao qua kênh.
Future<void> _report(String slotId, double height) =>
    NativeAdHeights.handleCall(
      MethodCall('height', {'slot_id': slotId, 'height': height}),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nhận chiều cao đúng slot, bỏ qua slot lạ hoặc đã huỷ', () async {
    final id = NativeAdHeights.newSlotId();
    expect(NativeAdHeights.listenable(id).value, isNull);

    await _report(id, 212.5);
    expect(NativeAdHeights.listenable(id).value, 212.5);

    await _report('khong-ton-tai', 99);
    expect(NativeAdHeights.listenable('khong-ton-tai').value, isNull);

    NativeAdHeights.remove(id);
    await _report(id, 300);
    expect(NativeAdHeights.listenable(id).value, isNull);
  });

  testWidgets(
    'NativeAdView cao đúng bằng chiều cao native báo, full chiều rộng',
    (tester) async {
      final slotId = NativeAdHeights.newSlotId();
      final placement = NativePlacement.fromJson(_placementName, {
        'type': 'INLINE',
        'unions': [
          {
            'slots': [
              {
                'ids': ['test'],
                'layout': 'FULLSIZE_MEDIA_INFO_CTA',
              },
            ],
          },
        ],
      });
      final controller = NativeAdController(placement)
        ..ads.value = [_FakeLoadedAd(slotId)]
        ..state.value = NativeAdState.loaded;
      sl.registerSingleton<NativeAdManager>(_FakeManager(controller));
      addTearDown(() {
        sl.unregister<NativeAdManager>();
        NativeAdHeights.remove(slotId);
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(children: [NativeAdView(placement: _placementName)]),
          ),
        ),
      );

      // Native chưa báo thì dùng chiều cao mặc định của layout.
      expect(tester.getSize(find.byKey(_adKey)).height, 330);

      await _report(slotId, 212);
      await tester.pump();

      final size = tester.getSize(find.byKey(_adKey));
      expect(size.height, 212);
      expect(size.width, tester.getSize(find.byType(Scaffold)).width);
    },
  );
}
