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
import '../../../data/models/football/football_models.dart';
import '../../widgets/collapsible_section.dart';
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
        // Sofascore không biết `leagueId` hệ Sportmonks nên dò theo tên +
        // quốc gia; `leagueId` giờ chỉ còn dùng cho phần yêu thích tại máy.
        create: (_) => LeagueDetailProvider(sl())
          ..load(leagueName, countryName: countryName),
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
                          // Màn này đã tự vẽ `StandingTableHeader` ở trên
                          // (đúng như `llTableHeader` của bản gốc), bật thêm ở
                          // đây là ra hai hàng tiêu đề chồng nhau.
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

/// Lịch giải, tách **đã diễn ra** và **sắp diễn ra** thành hai nhóm gập được.
///
/// `getLeagueDetail` gộp `events/last` với `events/next` rồi trả một danh sách
/// phẳng, nên trước đây trận đã đá và trận sắp đá nằm lẫn lộn. Trận có tỷ số
/// (`score != null`) là trận đã đá.
class _FixtureList extends StatefulWidget {
  const _FixtureList({required this.provider});

  final LeagueDetailProvider provider;

  @override
  State<_FixtureList> createState() => _FixtureListState();
}

class _FixtureListState extends State<_FixtureList> {
  bool _playedOpen = true;
  bool _upcomingOpen = true;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final all = widget.provider.fixtures;
    if (all.isEmpty) {
      return AppEmptyView(message: s.theFieldIsQuiteEmpty);
    }

    final played = all.where((f) => _scores(f) != null).toList()
      // Trận vừa đá xong lên trước, giống mọi app tỉ số.
      ..sort((a, b) => (b.startingAt ?? '').compareTo(a.startingAt ?? ''));
    final upcoming = all.where((f) => _scores(f) == null).toList()
      ..sort((a, b) => (a.startingAt ?? '').compareTo(b.startingAt ?? ''));

    return ListView(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
      children: [
        if (played.isNotEmpty) ...[
          CollapsibleSectionHeader(
            title: s.finished,
            logoAsset: 'assets/icons/ic_ball.svg',
            count: played.length,
            expanded: _playedOpen,
            onTap: () => setState(() => _playedOpen = !_playedOpen),
          ),
          if (_playedOpen) ...played.map(_card),
        ],
        if (upcoming.isNotEmpty) ...[
          CollapsibleSectionHeader(
            title: s.fixtures,
            logoAsset: 'assets/icons/ic_ball.svg',
            count: upcoming.length,
            expanded: _upcomingOpen,
            onTap: () => setState(() => _upcomingOpen = !_upcomingOpen),
          ),
          if (_upcomingOpen) ...upcoming.map(_card),
        ],
      ],
    );
  }

  static List<String>? _scores(UpcomingFixtureDto f) {
    final parts = f.score?.split('-');
    return parts != null && parts.length >= 2 ? parts : null;
  }

  Widget _card(UpcomingFixtureDto f) {
    final s = S.of(context);
    final scores = _scores(f);
    return FixtureCard(
      homeName: f.homeName ?? '',
      homeLogo: f.homeImagePath,
      awayName: f.awayName ?? '',
      awayLogo: f.awayImagePath,
      centerText: scores != null
          ? '${scores[0].trim()} - ${scores[1].trim()}'
          : DateTimeUtils.convertUtcToLocalTime(f.startingAt),
      dateState: '${DateTimeUtils.convertUtcToLocalDate(f.startingAt)} • '
          '${scores != null ? s.statusFt : s.statusNs}',
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.matchDetail,
        arguments: {'matchId': f.id ?? 0},
      ),
    );
  }
}
