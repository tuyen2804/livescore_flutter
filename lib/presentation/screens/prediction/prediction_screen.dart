import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/state_views.dart';
import '../../../domain/entities/match_entities.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/analytics_service.dart';
import '../../providers/prediction_provider.dart';
import '../../widgets/reward_flow.dart';
import '../home/widgets/date_strip.dart';
import 'widgets/prediction_widgets.dart';

/// Port `presentation/prediction/PredictionFragment.kt` + `fragment_prediction.xml`:
/// toolbar (tiêu đề 20sp + chuông 30dp) → thanh ngày → 3 pill Live/Upcoming/
/// Finished (mặc định Upcoming) → danh sách nhóm theo giải.
class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  /// `selectedTabPosition = 1` — bản gốc mở ở tab Upcoming.
  int _tab = 1;

  /// Port `filterByTab`.
  static const List<List<int>> _tabStates = [
    [2, 4, 6, 21, 22, 23, 3], // Live + HT
    [1, 26, 13, 19], // NS, TBD
    [5, 17, 8, 7, 9, 25], // FT, AET, PEN
  ];

  List<LeagueSection> _filter(List<LeagueSection> sections) {
    final states = _tabStates[_tab];
    return sections
        .map((s) => s.copyWith(
              fixtures: s.fixtures
                  .where((f) => states.contains(f.state))
                  .toList(growable: false),
            ))
        .where((s) => s.fixtures.isNotEmpty)
        .toList(growable: false);
  }

  /// Port `PredictionFragment`: tab Finished vào thẳng, còn Live / Up coming
  /// phải xem hết quảng cáo reward mới mở được kết quả dự đoán.
  void _openForecast(BuildContext context, dynamic fixture) {
    void go() {
      sl<AnalyticsService>().logEvent('prediction_submit', {
        'match_id': '${fixture.id}',
        'league_name': '${fixture.leagueName}',
        'home_team': '${fixture.teamHome}',
        'away_team': '${fixture.teamAway}',
      });
      Navigator.of(context).pushNamed(
        AppRoutes.matchForecast,
        arguments: {
          'matchId': int.tryParse('${fixture.id}') ?? 0,
          'homeTeamName': fixture.teamHome,
          'awayTeamName': fixture.teamAway,
          'homeTeamLogo': fixture.homeLogoUrl,
          'awayTeamLogo': fixture.awayLogoUrl,
        },
      );
    }

    if (_tab == 2) {
      go();
      return;
    }
    RewardFlow.start(context, onGranted: go);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<PredictionProvider>();
    final sections = _filter(provider.leagueFixtures);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // `toolbar` của bản gốc: tiêu đề căn giữa parent, chuông neo ở
            // mép phải — Stack phải chiếm hết bề ngang, không co theo chữ.
            Padding(
              padding: const EdgeInsets.only(top: 25, bottom: 4),
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      s.matchPrediction,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.medium(
                        size: 20,
                        color: AppColors.text500,
                      ),
                    ),
                    Positioned(
                      right: 15,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.notification),
                        child: SvgPicture.asset(
                          'assets/icons/ic_notihome.svg',
                          width: 30,
                          height: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: AppDimens.sdp(12)),
            DateStrip(
              dates: provider.dateStrip,
              selected: provider.selectedDate,
              onSelect: provider.setDate,
              onPickDate: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: provider.selectedDate,
                  firstDate: now.subtract(const Duration(days: 365)),
                  lastDate: now.add(const Duration(days: 365)),
                );
                if (picked != null) provider.setDate(picked);
              },
            ),
            SizedBox(height: AppDimens.sdp(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(10)),
              child: Row(
                children: [
                  Expanded(
                    child: PredictionPill(
                      label: s.live,
                      selected: _tab == 0,
                      onTap: () => setState(() => _tab = 0),
                    ),
                  ),
                  SizedBox(width: AppDimens.sdp(8)),
                  Expanded(
                    child: PredictionPill(
                      label: s.upComing,
                      selected: _tab == 1,
                      onTap: () => setState(() => _tab = 1),
                    ),
                  ),
                  SizedBox(width: AppDimens.sdp(8)),
                  Expanded(
                    child: PredictionPill(
                      label: s.finished,
                      selected: _tab == 2,
                      onTap: () => setState(() => _tab = 2),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimens.sdp(10)),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brandAccent,
                backgroundColor: AppColors.itemBg,
                onRefresh: provider.refreshData,
                child: provider.isLoading && provider.isEmpty
                    ? const AppLoading()
                    : sections.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: AppDimens.sdp(60)),
                              AppEmptyView(
                                message: s.theFieldIsQuiteEmpty,
                                icon: Icons.auto_graph,
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            itemCount: sections.length,
                            itemBuilder: (context, index) =>
                                PredictionLeagueGroup(
                              section: sections[index],
                              onMatchTap: (fixture) =>
                                  _openForecast(context, fixture),
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
