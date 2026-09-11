import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ads/ads_constants.dart';
import '../../../core/ads/interstitial_ad_manager.dart';
import '../../../core/billing/premium_manager.dart';
import '../../../core/ads/native/native_ad_manager.dart';
import '../../../core/ads/native/native_placements.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/datasources/local/app_prefs.dart';
import '../../providers/pick_favorite_provider.dart';
import 'widgets/pick_grid.dart';
import '../../widgets/native/native_ad_view.dart';
import '../../widgets/native/native_fullscreen_overlay.dart';

/// Port `presentation/onboarding/pick/PickFavoriteTeamsFragment.kt` — màn cuối
/// của onboarding, bản gốc nạp trước inter `LiveScore_inter_Inapp` ở đây để
/// lần chuyển tab đầu tiên trong Main đã có sẵn quảng cáo.
class PickFavoriteTeamsScreen extends StatefulWidget {
  const PickFavoriteTeamsScreen({super.key});

  @override
  State<PickFavoriteTeamsScreen> createState() =>
      _PickFavoriteTeamsScreenState();
}

class _PickFavoriteTeamsScreenState extends State<PickFavoriteTeamsScreen> {
  @override
  void initState() {
    super.initState();
    InterstitialAdManager.preload(InterPlacement.inApp);
    // Màn No-ads đi ngay sau khi bấm Get Started.
    unawaited(sl<NativeAdManager>().preload(NativePlacements.noAds));
    if (PremiumManager.featureEnabled) {
      // Màn No-ads đi ngay sau màn này: nạp trước inter của nó.
      InterstitialAdManager.preload(InterPlacement.noAds);
    }
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => PickFavoriteProvider(sl(), sl())..loadData(),
        child: const _PickTeamsView(),
      );
}

class _PickTeamsView extends StatelessWidget {
  const _PickTeamsView();

  Future<void> _finish(BuildContext context) async {
    final navigator = Navigator.of(context);
    await sl<AppPrefs>().setPassedPickFav(true);

    // `LiveScore_native_fullscreen_2` — 2 quảng cáo chia đôi màn kèm chuỗi
    // nút COUNTDOWN → REDIRECT → CLOSE. Không có sẵn thì đi tiếp luôn.
    if (context.mounted) {
      await NativeFullscreenOverlay.show(
        context,
        NativePlacements.fullscreenInter,
      );
    }
    // Bản gốc: Get Started → màn No-ads, màn đó mới dẫn vào Home. Tắt tính
    // năng Premium thì vào thẳng Home và xoá sạch back stack onboarding.
    if (PremiumManager.featureEnabled && !sl<PremiumManager>().isPremium) {
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.premium,
        (route) => false,
        arguments: const {'fromOnboarding': true},
      );
      return;
    }
    navigator.pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<PickFavoriteProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            PickTitle(text: s.chooseYourTeams),
            SizedBox(height: AppDimens.sdp(12)),
            Expanded(
              child: provider.isLoading
                  ? const AppLoading()
                  : provider.teams.isEmpty
                      ? AppEmptyView(message: s.noData)
                      : PickGrid(
                          itemCount: provider.teams.length,
                          itemBuilder: (context, index) {
                            final team = provider.teams[index];
                            return PickCard(
                              name: team.name,
                              imageUrl: provider.logoUrl(team.imagePath),
                              selected: team.isFavourite,
                              isLeague: false,
                              onTap: () => provider.toggleTeamFavorite(team),
                            );
                          },
                        ),
            ),
            // Ngược với màn chọn giải: ở đây `btnContinue` mới ghim đáy,
            // `layoutNative` nằm trên nó, lề dưới 6sdp.
            NativeAdView(
              placement: NativePlacements.choose2,
              margin: EdgeInsets.only(bottom: AppDimens.sdp(6)),
            ),
            PickBottomButton(
              label: s.getStarted,
              onTap: () => _finish(context),
            ),
          ],
        ),
      ),
    );
  }
}
