import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/match_entities.dart';
import '../../providers/detail_providers.dart';
import '../../widgets/collapsible_section.dart';
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

class _FixtureList extends StatefulWidget {
  const _FixtureList({required this.provider});

  final TeamDetailProvider provider;

  @override
  State<_FixtureList> createState() => _FixtureListState();
}

class _FixtureListState extends State<_FixtureList> {
  /// Nhớ nhóm bị đóng chứ không nhớ nhóm mở: mặc định mở hết, và giải mới xuất
  /// hiện sau khi tải lại vẫn mở sẵn.
  final Set<String> _closed = <String>{};

  TeamDetailProvider get provider => widget.provider;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (provider.items.isEmpty) {
      return AppEmptyView(message: s.theFieldIsQuiteEmpty);
    }

    // `provider.items` là danh sách phẳng xen kẽ header giải và trận. Gom lại
    // thành từng nhóm để gập được — một đội đá 4–5 giải song song nên danh sách
    // phẳng dài và khó tìm.
    final groups = <_LeagueGroup>[];
    for (final item in provider.items) {
      switch (item) {
        case FixtureHeaderItem():
          groups.add(_LeagueGroup(item.leagueName, item.leagueLogo));
        case FixtureRowItem():
          if (groups.isEmpty) {
            groups.add(_LeagueGroup(s.fixtures, null));
          }
          groups.last.fixtures.add(item.fixture);
      }
    }

    return ListView(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(10)),
      children: [
        for (final group in groups) ...[
          CollapsibleSectionHeader(
            title: group.name,
            logoUrl: group.logo,
            logoAsset: 'assets/icons/ic_league.svg',
            count: group.fixtures.length,
            expanded: _isOpen(group.name),
            onTap: () => setState(() {
              if (_closed.contains(group.name)) {
                _closed.remove(group.name);
              } else {
                _closed.add(group.name);
              }
            }),
          ),
          if (_isOpen(group.name))
            for (final fixture in group.fixtures)
              FixtureCard(
                homeName: fixture.homeTeamName,
                homeLogo: fixture.homeTeamLogo,
                awayName: fixture.awayTeamName,
                awayLogo: fixture.awayTeamLogo,
                // Port `ItemViewHolder.bind`: live/finished/ft mới hiện tỉ số.
                centerText: _centerText(fixture),
                dateState: '${fixture.date} • ${fixture.matchState}',
                isNotified: fixture.isNotified,
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.matchDetail,
                  arguments: {'matchId': int.tryParse(fixture.id) ?? 0},
                ),
              ),
        ],
      ],
    );
  }

  /// Mặc định mở hết; chỉ nhớ nhóm nào người dùng đã đóng.
  bool _isOpen(String name) => !_closed.contains(name);
}

class _LeagueGroup {
  _LeagueGroup(this.name, this.logo);

  final String name;
  final String? logo;
  final List<Fixture> fixtures = <Fixture>[];
}

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
              // Có id thì màn chi tiết tự gọi Sofascore lấy thêm chân thuận,
              // giá trị chuyển nhượng, hạn hợp đồng.
              'playerId': player.playerId,
            },
          ),
        );
      },
    );
  }
}
