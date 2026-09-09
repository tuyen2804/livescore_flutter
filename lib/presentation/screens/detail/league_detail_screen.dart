import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../providers/detail_providers.dart';
import '../../widgets/detail_widgets.dart';
import 'tabs/match_table_tab.dart';
import 'widgets/fixture_card.dart';

/// Port `presentation/leagues/LeagueDetailFragment.kt` + `fragment_league_detail.xml`:
/// toolbar 74sdp → 2 tab dạng viên thuốc (Fixtures / Table) → nội dung.
/// Header bảng chỉ hiện khi đang ở tab Table.
class LeagueDetailScreen extends StatelessWidget {
  const LeagueDetailScreen({
    super.key,
    required this.leagueId,
    required this.leagueName,
    this.leagueLogo,
    this.countryName,
  });

  final int leagueId;
  final String leagueName;
  final String? leagueLogo;
  final String? countryName;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => LeagueDetailProvider(sl())..load(leagueId),
        child: _LeagueDetailView(leagueName: leagueName),
      );
}

class _LeagueDetailView extends StatefulWidget {
  const _LeagueDetailView({required this.leagueName});

  final String leagueName;

  @override
  State<_LeagueDetailView> createState() => _LeagueDetailViewState();
}

class _LeagueDetailViewState extends State<_LeagueDetailView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<LeagueDetailProvider>();
    final isTable = _tab == 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          DetailToolbar(title: widget.leagueName),
          SizedBox(height: AppDimens.sdp(17)),
          SegmentedTabs(
            tabs: [s.fixtures, s.table],
            selected: _tab,
            onSelect: (i) => setState(() => _tab = i),
          ),
          SizedBox(height: AppDimens.sdp(isTable ? 24 : 8)),
          if (isTable)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(14)),
              child: const StandingTableHeader(),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(14)),
              child: provider.isLoading
                  ? const EarthLoadingOverlay(label: 'Loading')
                  : isTable
                      ? MatchTableTab(
                          showAccentLine: false,
                          standings: provider.standings,
                          showHeader: false,
                        )
                      : _FixtureList(provider: provider),
            ),
          ),
        ],
      ),
    );
  }
}

class _FixtureList extends StatelessWidget {
  const _FixtureList({required this.provider});

  final LeagueDetailProvider provider;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    if (provider.fixtures.isEmpty) {
      return AppEmptyView(message: s.theFieldIsQuiteEmpty);
    }
    return ListView.builder(
      padding: EdgeInsets.only(
        top: AppDimens.sdp(16),
        bottom: AppDimens.sdp(16),
      ),
      itemCount: provider.fixtures.length,
      itemBuilder: (context, index) {
        final f = provider.fixtures[index];
        final scores = f.score?.split('-');
        final hasScore = scores != null && scores.length >= 2;
        return FixtureCard(
          homeName: f.homeName ?? '',
          homeLogo: f.homeImagePath,
          awayName: f.awayName ?? '',
          awayLogo: f.awayImagePath,
          centerText: hasScore
              ? '${scores[0].trim()} - ${scores[1].trim()}'
              : DateTimeUtils.convertUtcToLocalTime(f.startingAt),
          dateState:
              '${DateTimeUtils.convertUtcToLocalDate(f.startingAt)} • ${s.statusNs}',
          onTap: () => Navigator.of(context).pushNamed(
            AppRoutes.matchDetail,
            arguments: {'matchId': f.id ?? 0},
          ),
        );
      },
    );
  }
}
