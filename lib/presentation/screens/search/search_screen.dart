import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/match_entities.dart';
import '../../providers/search_provider.dart';
import '../leagues/widgets/league_list_widgets.dart';

/// Port `presentation/search/SearchFragment.kt` + `fragment_search.xml`:
/// back 30dp + ô tìm kiếm `bg_border_12_gray`, rồi "Top team" và lưới 3 cột.
/// Gõ chữ thì tiêu đề + lưới top ẩn đi, thay bằng lưới kết quả.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => SearchProvider(sl(), sl(), sl()),
        child: const _SearchView(),
      );
}

class _SearchView extends StatelessWidget {
  const _SearchView();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<SearchProvider>();
    final showResults = provider.hasQuery;
    final teams = showResults ? provider.teams : provider.topTeams;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 25, left: 14, right: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: SvgPicture.asset(
                      'assets/icons/ic_arrow_back.svg',
                      width: 30,
                      height: 30,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      onChanged: provider.onQueryChanged,
                      style: AppTextStyles.regular(
                        size: 14,
                        color: AppColors.text500,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        // `bg_border_12_gray`: nền #33FFFFFF, viền 1dp #55FFFFFF.
                        fillColor: const Color(0x33FFFFFF),
                        hintText: s.searchTeamOrLeague,
                        hintStyle: AppTextStyles.regular(
                          size: 14,
                          color: AppColors.text200,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset(
                            'assets/icons/ic_search.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              AppColors.text200,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 42, minHeight: 42),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0x55FFFFFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0x55FFFFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0x55FFFFFF)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!showResults)
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 20),
                child: Text(
                  s.topTeam,
                  style: AppTextStyles.medium(
                    size: 16,
                    color: AppColors.text500,
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 14,
                  right: 14,
                  top: showResults ? 16 : 14,
                  bottom: 10,
                ),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisExtent: AppDimens.sdp(13) +
                        AppDimens.sdp(40) +
                        AppDimens.ssp(8) * 1.4 +
                        AppDimens.sdp(58),
                  ),
                  itemCount: teams.length,
                  itemBuilder: (context, index) =>
                      _cell(context, provider, teams[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    SearchProvider provider,
    TeamEntity team,
  ) =>
      LeagueGridCell(
        name: team.name,
        logoUrl: team.logoUrl,
        isFavourite: team.isFavorite,
        placeholderAsset: 'assets/icons/ic_ball.svg',
        onTap: () async {
          await provider.rememberTeam(team);
          if (!context.mounted) return;
          Navigator.of(context).pushNamed(
            AppRoutes.teamDetail,
            arguments: {'teamId': int.tryParse(team.id) ?? 0},
          );
        },
        onToggleFavourite: () => provider.rememberTeam(team),
      );
}
