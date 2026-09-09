import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../providers/detail_providers.dart';

/// Port `presentation/detail/MatchForecastFragment.kt` —
/// đã bỏ phần khoá tính năng bằng reward ad.
class MatchForecastScreen extends StatelessWidget {
  const MatchForecastScreen({
    super.key,
    required this.matchId,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
  });

  final int matchId;
  final String homeTeamName;
  final String awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => MatchForecastProvider(sl())..load(matchId),
        child: _ForecastView(
          matchId: matchId,
          homeTeamName: homeTeamName,
          awayTeamName: awayTeamName,
          homeTeamLogo: homeTeamLogo,
          awayTeamLogo: awayTeamLogo,
        ),
      );
}

class _ForecastView extends StatelessWidget {
  const _ForecastView({
    required this.matchId,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeTeamLogo,
    this.awayTeamLogo,
  });

  final int matchId;
  final String homeTeamName;
  final String awayTeamName;
  final String? homeTeamLogo;
  final String? awayTeamLogo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<MatchForecastProvider>();
    final forecast = provider.forecast;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        title: Text(
          s.matchPrediction,
          style: AppTextStyles.semiBold(
            size: AppDimens.ssp(16),
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: provider.isLoading
          ? const EarthLoadingOverlay(label: 'Loading')
          : forecast == null
              // Port `ctrNoPrediction`: header hai đội vẫn hiện, bên dưới là
              // `ic_ball` 80dp + tiêu đề 16sp bold + mô tả 14sp.
              ? ListView(
                  padding: EdgeInsets.all(AppDimens.sdp(12)),
                  children: [
                    _TeamsHeader(
                      homeName: homeTeamName,
                      awayName: awayTeamName,
                      homeLogo: homeTeamLogo,
                      awayLogo: awayTeamLogo,
                    ),
                    const SizedBox(height: 20),
                    _NoPrediction(
                      title: s.noPredictionAvailable,
                      message: s
                          .theMatchHasEndedPredictionsAreOnlyAvailableForUpcomingOrLiveMatches,
                    ),
                  ],
                )
              : ListView(
                  padding: EdgeInsets.all(AppDimens.sdp(12)),
                  children: [
                    _TeamsHeader(
                      homeName: homeTeamName,
                      awayName: awayTeamName,
                      homeLogo: homeTeamLogo,
                      awayLogo: awayTeamLogo,
                    ),
                    SizedBox(height: AppDimens.sdp(12)),
                    if (forecast.matchResult != null)
                      _TripleCard(
                        title: s.matchResultPredictions,
                        left: forecast.matchResult!.home ?? 0,
                        middle: forecast.matchResult!.draw ?? 0,
                        right: forecast.matchResult!.away ?? 0,
                        leftLabel: s.homeText,
                        middleLabel: s.drawText,
                        rightLabel: s.awayText,
                      ),
                    if (forecast.firstGoal != null)
                      _TripleCard(
                        title: s.firstGoalPredictions,
                        left: forecast.firstGoal!.home ?? 0,
                        middle: forecast.firstGoal!.noGoal ?? 0,
                        right: forecast.firstGoal!.away ?? 0,
                        leftLabel: s.homeText,
                        middleLabel: s.noGoal,
                        rightLabel: s.awayText,
                      ),
                    if (forecast.matchScore != null)
                      _ValueCard(
                        title: s.matchScorePredictions,
                        value:
                            '${forecast.matchScore!.home ?? 0} - ${forecast.matchScore!.away ?? 0}',
                      ),
                    if (forecast.totalGoals != null)
                      _ValueCard(
                        title: s.totalGoalsPredictions,
                        value: '${forecast.totalGoals!.totalGoals ?? 0}',
                      ),
                    if (forecast.corner != null)
                      _ValueCard(
                        title: s.cornerPredictions,
                        value:
                            '${forecast.corner!.home ?? 0} - ${forecast.corner!.away ?? 0}',
                      ),
                    if (forecast.bothTeamsToScore != null)
                      _ValueCard(
                        title: s.bothTeamsToScore,
                        value: (forecast.bothTeamsToScore!.ft ?? false)
                            ? s.yesText
                            : s.noText,
                      ),
                    if (forecast.confidence != null)
                      _ValueCard(
                        title: s.confidenceFormat(
                          forecast.confidence!.percent ?? 0,
                        ),
                        value: '${forecast.confidence!.percent ?? 0}%',
                      ),
                    if (forecast.analysis?.text != null)
                      _TextCard(
                        title: s.inDepthAiAnalysis,
                        body: forecast.analysis!.text!,
                      ),
                    SizedBox(height: AppDimens.sdp(12)),
                    Text(
                      s.theAnalysesBelowAreForReferencePurposesOnly,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.regular(
                        size: AppDimens.ssp(10),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _TeamsHeader extends StatelessWidget {
  const _TeamsHeader({
    required this.homeName,
    required this.awayName,
    this.homeLogo,
    this.awayLogo,
  });

  final String homeName;
  final String awayName;
  final String? homeLogo;
  final String? awayLogo;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(AppDimens.sdp(14)),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(child: _Side(name: homeName, logo: homeLogo)),
            Text(
              S.of(context).vs,
              style: AppTextStyles.bold(
                size: AppDimens.ssp(14),
                color: AppColors.brandAccent,
              ),
            ),
            Expanded(child: _Side(name: awayName, logo: awayLogo)),
          ],
        ),
      );
}

class _Side extends StatelessWidget {
  const _Side({required this.name, required this.logo});

  final String name;
  final String? logo;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          AppImage(
            source: logo,
            width: AppDimens.sdp(44),
            height: AppDimens.sdp(44),
          ),
          SizedBox(height: AppDimens.sdp(6)),
          Text(
            name,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.medium(
              size: AppDimens.ssp(11),
              color: AppColors.text500,
            ),
          ),
        ],
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.only(bottom: AppDimens.sdp(10)),
        padding: EdgeInsets.all(AppDimens.sdp(12)),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.semiBold(
                size: AppDimens.ssp(13),
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppDimens.sdp(10)),
            child,
          ],
        ),
      );
}

class _TripleCard extends StatelessWidget {
  const _TripleCard({
    required this.title,
    required this.left,
    required this.middle,
    required this.right,
    required this.leftLabel,
    required this.middleLabel,
    required this.rightLabel,
  });

  final String title;
  final int left;
  final int middle;
  final int right;
  final String leftLabel;
  final String middleLabel;
  final String rightLabel;

  @override
  Widget build(BuildContext context) => _Card(
        title: title,
        child: Row(
          children: [
            _Slot(value: left, label: leftLabel, color: AppColors.homeColor),
            _Slot(value: middle, label: middleLabel, color: AppColors.drawColor),
            _Slot(value: right, label: rightLabel, color: AppColors.awayColor),
          ],
        ),
      );
}

class _Slot extends StatelessWidget {
  const _Slot({required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              '$value%',
              style: AppTextStyles.bold(size: AppDimens.ssp(16), color: color),
            ),
            SizedBox(height: AppDimens.sdp(4)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(10),
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppDimens.sdp(6)),
            LinearProgressIndicator(
              value: value / 100,
              minHeight: 4,
              backgroundColor: AppColors.divider,
              color: color,
            ),
          ],
        ),
      );
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => _Card(
        title: title,
        child: Center(
          child: Text(
            value,
            style: AppTextStyles.bold(
              size: AppDimens.ssp(20),
              color: AppColors.brandAccent,
            ),
          ),
        ),
      );
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => _Card(
        title: title,
        child: Text(
          body,
          style: AppTextStyles.regular(
            size: AppDimens.ssp(12),
            color: AppColors.text100,
          ),
        ),
      );
}

/// Port `ctrNoPrediction` của `fragment_match_forecast.xml`.
class _NoPrediction extends StatelessWidget {
  const _NoPrediction({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            SvgPicture.asset(
              'assets/icons/ic_ball.svg',
              width: 80,
              height: 80,
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.bold(size: 16, color: AppColors.text500),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.regular(
                  size: 14,
                  color: AppColors.colorD2d3d5,
                ),
              ),
            ),
          ],
        ),
      );
}
