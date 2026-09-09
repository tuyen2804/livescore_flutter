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

/// Port `presentation/search/SearchLeagueFragment.kt` +
/// `fragment_search_league.xml` — cùng khung với màn tìm đội, chỉ đổi
/// gợi ý thành "Search league" và lưới hiển thị giải đấu.
class SearchLeagueScreen extends StatelessWidget {
  const SearchLeagueScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => SearchProvider(sl(), sl(), sl()),
        child: const _SearchLeagueView(),
      );
}

class _SearchLeagueView extends StatelessWidget {
  const _SearchLeagueView();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<SearchProvider>();
    final showResults = provider.hasQuery;
    final leagues = showResults ? provider.leagues : provider.topLeagues;

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
                        fillColor: const Color(0x33FFFFFF),
                        hintText: s.searchLeague,
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
                  s.topLeague,
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
                  itemCount: leagues.length,
                  itemBuilder: (context, index) =>
                      _cell(context, provider, leagues[index]),
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
    League league,
  ) =>
      LeagueGridCell(
        name: league.name,
        logoUrl: league.logoUrl,
        isFavourite: league.isFavorite,
        onTap: () async {
          await provider.rememberLeague(league);
          if (!context.mounted) return;
          Navigator.of(context).pushNamed(
            AppRoutes.leagueDetail,
            arguments: {
              'leagueId': league.leagueId,
              'leagueName': league.name,
              'leagueLogo': league.logoUrl,
              'countryName': league.country,
            },
          );
        },
        onToggleFavourite: () => provider.rememberLeague(league),
      );
}
