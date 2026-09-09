import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/datasources/local/app_prefs.dart';
import '../../providers/pick_favorite_provider.dart';
import 'widgets/pick_grid.dart';

/// Port `presentation/onboarding/pick/PickFavoriteTeamsFragment.kt`.
class PickFavoriteTeamsScreen extends StatelessWidget {
  const PickFavoriteTeamsScreen({super.key});

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
            SizedBox(height: AppDimens.sdp(8)),
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
