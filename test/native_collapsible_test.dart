import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:live_score/core/ads/native/native_ad_controller.dart';
import 'package:live_score/core/ads/native/native_ad_manager.dart';
import 'package:live_score/core/ads/native/native_placement.dart';
import 'package:live_score/core/di/injection.dart';
import 'package:live_score/presentation/widgets/native/native_collapsible.dart';

const _placementName = 'collap_home';

/// `AdWidget` thật cần platform view; test chỉ cần ô giữ chỗ có key riêng.
class _FakeLoadedAd extends LoadedNativeAd {
  _FakeLoadedAd(this.name, String layout)
    : super(
        ad: NativeAd(
          adUnitId: 'test',
          factoryId: 'test',
          listener: NativeAdListener(),
          request: const AdRequest(),
        ),
        layout: layout,
        style: AdStyle.fromJson(const <String, dynamic>{}),
        slotId: name,
      );

  final String name;

  @override
  Widget get widget => ColoredBox(key: ValueKey(name), color: Colors.blue);
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
  setUp(() {
    final placement = NativePlacement.fromJson(_placementName, {
      'type': 'INLINE',
      'unions': [
        {
          'slots': [
            {
              'ids': ['big'],
              'layout': 'FULLSIZE_INFO_MEDIA_CTA',
            },
            {
              'ids': ['small'],
              'layout': 'SMALL_BANNER_INFO2CTA',
            },
          ],
          'button_sequence': [
            {'type': 'COLLAPSE', 'symbol': 'CHEVRON_DOWN'},
          ],
        },
      ],
    });
    final controller = NativeAdController(placement)
      ..ads.value = [
        _FakeLoadedAd('big', 'FULLSIZE_INFO_MEDIA_CTA'),
        _FakeLoadedAd('small', 'SMALL_BANNER_INFO2CTA'),
      ]
      ..state.value = NativeAdState.loaded;
    sl.registerSingleton<NativeAdManager>(_FakeManager(controller));
  });

  tearDown(() => sl.unregister<NativeAdManager>());

  testWidgets('thu gọn thì sang dạng nhỏ và không còn nút mở lại', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Spacer(),
              NativeCollapsible(placement: _placementName),
            ],
          ),
        ),
      ),
    );

    // Dạng mở có chuỗi nút để thu gọn.
    expect(find.byKey(const ValueKey('big')), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pump();

    expect(find.byKey(const ValueKey('small')), findsOneWidget);
    expect(find.byKey(const ValueKey('big')), findsNothing);
    // Dạng nhỏ: không nút mở lại, không chuỗi nút.
    expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });
}
