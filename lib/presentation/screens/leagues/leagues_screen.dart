import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../../domain/entities/match_entities.dart';
import '../../providers/home_provider.dart';
import '../../providers/leagues_provider.dart';
import '../../widgets/sport_toolbar.dart';
import '../home/widgets/sport_picker_sheet.dart';
import 'widgets/league_list_widgets.dart';

/// Port `presentation/leagues/LeaguesFragment.kt` + `fragment_leagues.xml`:
/// toolbar 64dp nền `color_item_bg` (pill chọn môn – tiêu đề – nút tìm kiếm),
/// rồi một danh sách phẳng gồm section "Favorite Leagues" và "All Leagues"
/// (có hai sub-header quốc tế / quốc gia), tất cả đều thu gọn được.
class LeaguesScreen extends StatelessWidget {
  const LeaguesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<LeaguesProvider>();
    final home = context.read<HomeProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SportToolbar(
              title: s.leagues,
              sportSlug: provider.sportSlug,
              onSportTap: () async {
                final slug = await SportPickerSheet.show(
                  context,
                  sports: home.availableSports,
                  selected: provider.sportSlug,
                  liveCount: home.liveCountFor,
                  totalCount: home.totalCountFor,
                );
                if (slug != null) await provider.selectSport(slug);
              },
              onSearchTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.searchLeague),
            ),
            Expanded(
              child: provider.isLoading
                  ? const EarthLoadingOverlay(label: 'Loading')
                  : RefreshIndicator(
                      color: AppColors.brandAccent,
                      backgroundColor: AppColors.itemBg,
                      onRefresh: provider.loadData,
                      child: CustomScrollView(
                        slivers: _buildSlivers(context, provider, s),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bản gốc dùng `GridLayoutManager(3)` với `spanSizeLookup`: header và dòng
  /// "chưa có mục yêu thích" chiếm cả 3 cột, mỗi giải chiếm 1 cột.
  List<Widget> _buildSlivers(
    BuildContext context,
    LeaguesProvider provider,
    S s,
  ) {
    final slivers = <Widget>[
      SliverPadding(
        padding: EdgeInsets.only(
          left: AppDimens.sdp(14),
          right: AppDimens.sdp(14),
          top: AppDimens.sdp(12),
        ),
        sliver: SliverToBoxAdapter(
          child: LeagueSectionHeader(
            title: s.favoriteLeagues,
            expanded: provider.favouriteVisible,
            onTap: provider.toggleFavouriteVisibility,
          ),
        ),
      ),
    ];

    if (provider.favouriteVisible) {
      if (provider.favourites.isEmpty) {
        slivers.add(_full(NoFavoriteRow(message: s.noFavoriteLeague)));
      } else {
        slivers.add(_grid(provider.favourites
            .map((l) => _cell(context, provider, l))
            .toList(growable: false)));
      }
    }

    final allExpanded =
        provider.internationalVisible || provider.nationalVisible;
    slivers.add(_full(LeagueSectionHeader(
      title: s.allLeagues,
      expanded: allExpanded,
      onTap: () {
        provider.toggleInternationalVisibility();
        provider.toggleNationalVisibility();
      },
    )));

    if (allExpanded) {
      if (provider.international.isNotEmpty) {
        slivers.add(_full(LeagueSubHeader(
          title: provider.isFootball
              ? s.internationalTournaments
              : s.sectionFeatured,
          expanded: provider.internationalVisible,
          onTap: provider.toggleInternationalVisibility,
          isFirst: true,
        )));
        if (provider.internationalVisible) {
          slivers.add(_grid(provider.international
              .map((l) => _cell(context, provider, l))
              .toList(growable: false)));
        }
      }

      if (provider.national.isNotEmpty) {
        slivers.add(_full(LeagueSubHeader(
          title: provider.isFootball ? s.nationalLeagues : s.allLeagues,
          expanded: provider.nationalVisible,
          onTap: provider.toggleNationalVisibility,
        )));
        if (provider.nationalVisible) {
          slivers.add(_grid(provider.national
              .map((l) => _cell(context, provider, l))
              .toList(growable: false)));
        }
      }
    }

    slivers.add(SliverToBoxAdapter(
      child: SizedBox(height: AppDimens.sdp(80)),
    ));
    return slivers;
  }

  Widget _full(Widget child) => SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(14)),
        sliver: SliverToBoxAdapter(child: child),
      );

  Widget _grid(List<Widget> cells) => SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(14)),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisExtent: AppDimens.sdp(13) +
                AppDimens.sdp(40) +
                AppDimens.ssp(8) * 1.4 +
                AppDimens.sdp(58),
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => cells[index],
            childCount: cells.length,
          ),
        ),
      );

  Widget _cell(
    BuildContext context,
    LeaguesProvider provider,
    League league,
  ) =>
      LeagueGridCell(
        name: league.name,
        logoUrl: league.logoUrl,
        isFavourite: league.isFavorite,
        onTap: () => Navigator.of(context).pushNamed(
          league.sportSlug == 'football'
              ? AppRoutes.leagueDetail
              : AppRoutes.uniqueTournament,
          arguments: league.sportSlug == 'football'
              ? {
                  'leagueId': league.leagueId,
                  'leagueName': league.name,
                  'leagueLogo': league.logoUrl,
                  'countryName': league.country,
                }
              : {
                  'uniqueTournamentId': league.leagueId,
                  'name': league.name,
                  'sportSlug': league.sportSlug,
                },
        ),
        onToggleFavourite: () => provider.toggleFavourite(league),
      );
}

/// Icon tìm kiếm 32dp / padding 4dp ở toolbar — tách ra để dùng lại.
class ToolbarSearchButton extends StatelessWidget {
  const ToolbarSearchButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: SvgPicture.asset('assets/icons/ic_search.svg'),
          ),
        ),
      );
}

/// Kiểu chữ tiêu đề toolbar (18sp, `text500`).
TextStyle toolbarTitleStyle() =>
    AppTextStyles.medium(size: 18, color: AppColors.text500);
