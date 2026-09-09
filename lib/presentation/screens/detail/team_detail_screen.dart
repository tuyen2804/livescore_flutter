import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/match_entities.dart';
import '../../providers/detail_providers.dart';
import '../../widgets/detail_widgets.dart';
import 'widgets/fixture_card.dart';

/// Port `presentation/detail/DetailTeamFragment.kt` + `fragment_detail_team.xml`:
/// toolbar 74sdp → 2 tab viên thuốc (Fixtures / Squad) → danh sách trận
/// dùng `item_fixture.xml`, có header tên giải xen giữa.
class TeamDetailScreen extends StatelessWidget {
  const TeamDetailScreen({super.key, required this.teamId});

  final int teamId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => TeamDetailProvider(sl(), sl())..load(teamId),
        child: _TeamDetailView(teamId: teamId),
      );
}

class _TeamDetailView extends StatefulWidget {
  const _TeamDetailView({required this.teamId});

  final int teamId;

  @override
  State<_TeamDetailView> createState() => _TeamDetailViewState();
}

class _TeamDetailViewState extends State<_TeamDetailView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<TeamDetailProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Column(
        children: [
          // `fragment_detail_team.xml` chỉ có back + tên đội, không có nút sao.
          DetailToolbar(title: provider.teamName),
          SizedBox(height: AppDimens.sdp(14)),
          SegmentedTabs(
            tabs: [s.fixtures, s.squad],
            selected: _tab,
            onSelect: (i) => setState(() => _tab = i),
          ),
          SizedBox(height: AppDimens.sdp(24)),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(14)),
              child: provider.isLoading
                  ? const EarthLoadingOverlay(label: 'Loading')
                  : _tab == 0
                      ? _FixtureList(provider: provider)
                      : _SquadList(provider: provider),
            ),
          ),
        ],
      ),
    );
  }
}

/// `isLiveOrFinished && cả hai tỉ số có giá trị` thì hiện "2 - 1", còn lại
/// hiện giờ bóng lăn.
String _centerText(dynamic f) {
  final state = (f.matchState as String).toLowerCase();
  final live = state == 'live' || state == 'finished' || state == 'ft';
  final home = f.homeScore as String;
  final away = f.awayScore as String;
  final hasScore =
      home.isNotEmpty && away.isNotEmpty && home != '-' && away != '-';
  return live && hasScore ? '$home - $away' : f.time as String;
}

class _FixtureList extends StatelessWidget {
  const _FixtureList({required this.provider});

  final TeamDetailProvider provider;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (provider.items.isEmpty) {
      return AppEmptyView(message: s.theFieldIsQuiteEmpty);
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(10)),
      itemCount: provider.items.length,
      itemBuilder: (context, index) {
        final item = provider.items[index];
        return switch (item) {
          FixtureHeaderItem() => Padding(
              padding: EdgeInsets.only(
                top: AppDimens.sdp(12),
                bottom: AppDimens.sdp(8),
              ),
              child: Row(
                children: [
                  AppImage(
                    source: item.leagueLogo,
                    width: AppDimens.sdp(18),
                    height: AppDimens.sdp(18),
                    placeholderAsset: 'assets/icons/ic_league.svg',
                  ),
                  SizedBox(width: AppDimens.sdp(8)),
                  Expanded(
                    child: Text(
                      item.leagueName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.medium(
                        size: AppDimens.ssp(12),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          FixtureRowItem() => FixtureCard(
              homeName: item.fixture.homeTeamName,
              homeLogo: item.fixture.homeTeamLogo,
              awayName: item.fixture.awayTeamName,
              awayLogo: item.fixture.awayTeamLogo,
              // Port `ItemViewHolder.bind`: live/finished/ft mới hiện tỉ số.
              centerText: _centerText(item.fixture),
              dateState: '${item.fixture.date} • ${item.fixture.matchState}',
              isNotified: item.fixture.isNotified,
              onTap: () => Navigator.of(context).pushNamed(
                AppRoutes.matchDetail,
                arguments: {'matchId': int.tryParse(item.fixture.id) ?? 0},
              ),
            ),
        };
      },
    );
  }
}

/// Tab Squad: danh sách `item_player.xml` lấy từ `/live-score/list-player`.
class _SquadList extends StatelessWidget {
  const _SquadList({required this.provider});

  final TeamDetailProvider provider;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (provider.squad.isEmpty) {
      return AppEmptyView(message: s.theFieldIsQuiteEmpty);
    }

    return ListView.builder(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(10)),
      itemCount: provider.squad.length,
      itemBuilder: (context, index) {
        final player = provider.squad[index];
        return SquadPlayerRow(
          name: player.name,
          position: player.position,
          avatarUrl: player.imagePath,
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.playerDetail,
            arguments: {
              'playerName': player.name,
              'playerPos': player.position,
              'playerImg': player.imagePath,
              'teamName': provider.teamName,
              'playerHeight': player.heightText,
              'playerWeight': player.weightText,
              'playerAge': player.ageText,
              'playerNumber': player.numberText,
              'playerNationality': player.nationality,
            },
          ),
        );
      },
    );
  }
}
