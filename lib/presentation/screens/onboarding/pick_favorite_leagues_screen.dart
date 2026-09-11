import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ads/native/native_ad_manager.dart';
import '../../../core/ads/native/native_placements.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/state_views.dart';
import '../../providers/pick_favorite_provider.dart';
import 'widgets/pick_grid.dart';
import '../../widgets/native/native_ad_view.dart';

/// Port `presentation/onboarding/pick/PickFavoriteLeaguesFragment.kt`.
class PickFavoriteLeaguesScreen extends StatefulWidget {
  const PickFavoriteLeaguesScreen({super.key});

  @override
  State<PickFavoriteLeaguesScreen> createState() =>
      _PickFavoriteLeaguesScreenState();
}

class _PickFavoriteLeaguesScreenState extends State<PickFavoriteLeaguesScreen> {
  @override
  void initState() {
    super.initState();
    // Màn chọn đội đi ngay sau màn này.
    unawaited(sl<NativeAdManager>().preload(NativePlacements.choose2));
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => PickFavoriteProvider(sl(), sl())..loadData(),
        child: const _PickLeaguesView(),
      );
}

class _PickLeaguesView extends StatelessWidget {
  const _PickLeaguesView();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<PickFavoriteProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            PickTitle(text: s.chooseYourLeagues),
            SizedBox(height: AppDimens.sdp(12)),
            Expanded(
              child: provider.isLoading
                  ? const AppLoading()
                  : provider.leagues.isEmpty
                      ? AppEmptyView(message: s.noData)
                      : PickGrid(
                          itemCount: provider.leagues.length,
                          itemBuilder: (context, index) {
                            final league = provider.leagues[index];
                            return PickCard(
                              name: league.name,
                              imageUrl: provider.logoUrl(league.imagePath),
                              selected: league.isFavourite,
                              onTap: () => provider.toggleLeagueFavorite(league),
                            );
                          },
                        ),
            ),
            // `fragment_pick_favorite_leagues.xml`: `layoutNative` ghim đáy
            // parent, `btnNext` nằm **trên** nó (`bottom_toTopOf layoutNative`).
            PickBottomButton(
              label: s.next,
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.pickFavoriteTeams),
            ),
            const NativeAdView(placement: NativePlacements.choose1),
          ],
        ),
      ),
    );
  }
}
