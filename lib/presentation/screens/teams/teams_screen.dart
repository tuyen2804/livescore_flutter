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
import '../../providers/teams_provider.dart';
import '../../widgets/sport_toolbar.dart';
import '../home/widgets/sport_picker_sheet.dart';
import '../leagues/widgets/league_list_widgets.dart';

/// Port `presentation/teams/TeamsFragment.kt` + `fragment_teams.xml`:
/// toolbar 64dp, rồi tiêu đề "Favorite teams" + lưới 3 cột (cao tối đa
/// 200sdp), tiếp đến "All teams" + lưới 3 cột chiếm phần còn lại.
/// Hai tiêu đề đều thu gọn được bằng `ic_expand`.
class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<TeamsProvider>();
    final home = context.read<HomeProvider>();

    final hasFavourites = provider.favouriteTeams.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        bottom: false,
        // `ctrNoData` là con ĐẦU TIÊN của ConstraintLayout nên nằm dưới cùng,
        // phủ toàn màn và chỉ phụ thuộc `allTeams.isEmpty` — phần toolbar và
        // hai tiêu đề vẫn vẽ đè lên trên.
        child: Stack(
          children: [
            if (!provider.isLoading && provider.allTeams.isEmpty)
              const Positioned.fill(child: _NoData()),
            Column(
              children: [
                SportToolbar(
                  title: s.teams,
                  sportSlug: provider.sportSlug,
                  onSportTap: () async {
                    // `TeamsFragment.setupSportPicker` truyen `sportEventCounts =
                    // emptyMap()` nen dialog o day khong hien so tran.
                    final slug = await SportPickerSheet.show(
                      context,
                      sports: home.availableSports,
                      selected: provider.sportSlug,
                      liveCount: (_) => 0,
                      totalCount: (_) => 0,
                    );
                    if (slug != null) await provider.selectSport(slug);
                  },
                  onSearchTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.search),
                ),
                if (provider.isLoading)
                  const Expanded(child: EarthLoadingOverlay(label: 'Loading'))
                else
                  Expanded(
                    child: Column(
                      children: [
                        // Khối yêu thích chỉ hiện khi có đội, cao tối đa 200sdp.
                        if (hasFavourites) ...[
                          Padding(
                            padding: EdgeInsets.only(
                              left: AppDimens.sdp(14),
                              right: AppDimens.sdp(14),
                              top: AppDimens.sdp(16),
                            ),
                            child: _CollapseTitle(
                              title: s.favoriteTeams,
                              expanded: provider.favouriteVisible,
                              onTap: provider.toggleFavouriteVisibility,
                            ),
                          ),
                          if (provider.favouriteVisible)
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: AppDimens.sdp(200),
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: AppDimens.sdp(14),
                                  right: AppDimens.sdp(14),
                                  top: AppDimens.sdp(10),
                                ),
                                child: _TeamGrid(
                                  teams: provider.favouriteTeams,
                                  shrinkWrap: true,
                                  builder: (t) => _cell(context, provider, t),
                                ),
                              ),
                            ),
                        ],
                        Padding(
                          padding: EdgeInsets.only(
                            left: AppDimens.sdp(14),
                            right: AppDimens.sdp(14),
                            top: AppDimens.sdp(20),
                          ),
                          child: _CollapseTitle(
                            title: s.allTeams,
                            expanded: provider.allVisible,
                            onTap: provider.toggleAllVisibility,
                          ),
                        ),
                        if (provider.allVisible)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: AppDimens.sdp(14),
                                right: AppDimens.sdp(14),
                                top: AppDimens.sdp(14),
                                bottom: AppDimens.sdp(10),
                              ),
                              child: _TeamGrid(
                                teams: provider.allTeams,
                                builder: (t) => _cell(context, provider, t),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, TeamsProvider provider, TeamEntity team) =>
      LeagueGridCell(
        name: team.name,
        logoUrl: team.logoUrl,
        isFavourite: team.isFavorite,
        placeholderAsset: 'assets/icons/ic_ball.svg',
        onTap: () => Navigator.of(context).pushNamed(
          provider.isFootball
              ? AppRoutes.teamDetail
              : AppRoutes.sofascoreTeamDetail,
          arguments: {
            'teamId': int.tryParse(team.id) ?? 0,
            'teamName': team.name,
            'sportSlug': provider.sportSlug,
          },
        ),
        onToggleFavourite: () => provider.toggleFavourite(team),
      );
}

/// `txtFavourite` / `txtAll` + `imgCollapse` 18sdp — chữ 12ssp `text100`.
class _CollapseTitle extends StatelessWidget {
  const _CollapseTitle({
    required this.title,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.medium(
              size: AppDimens.ssp(12),
              color: AppColors.text100,
            ),
          ),
        ),
        AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 180),
          child: SvgPicture.asset(
            'assets/icons/ic_expand.svg',
            width: AppDimens.sdp(18),
            height: AppDimens.sdp(18),
          ),
        ),
      ],
    ),
  );
}

class _TeamGrid extends StatelessWidget {
  const _TeamGrid({
    required this.teams,
    required this.builder,
    this.shrinkWrap = false,
  });

  final List<TeamEntity> teams;
  final Widget Function(TeamEntity) builder;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: shrinkWrap,
    physics: shrinkWrap ? const ClampingScrollPhysics() : null,
    padding: EdgeInsets.zero,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisExtent:
          AppDimens.sdp(13) +
          AppDimens.sdp(40) +
          AppDimens.ssp(8) * 1.4 +
          AppDimens.sdp(58),
    ),
    itemCount: teams.length,
    itemBuilder: (context, index) => builder(teams[index]),
  );
}

/// `ctrNoData` của `fragment_teams.xml`: chỉ có `ic_ball` (88x109dp, do
/// `wrap_content`) rồi một `TextView` mà bản gốc **không hề gán text** —
/// nên trạng thái rỗng thực tế chỉ hiện quả bóng.
class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/icons/ic_ball.svg', width: 88, height: 109),
        SizedBox(height: AppDimens.sdp(6)),
      ],
    ),
  );
}
