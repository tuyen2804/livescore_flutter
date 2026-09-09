import 'package:flutter/material.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/sport_presentation.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../data/models/sofascore/sofascore_models.dart';

/// Thẻ trận dùng chung cho các màn Sofascore — port `item_event_match_row.xml`.
class SofaEventRow extends StatelessWidget {
  const SofaEventRow({
    super.key,
    required this.event,
    this.onTap,
    this.margin,
    this.borderRadius,
  });

  final SofascoreEvent event;
  final VoidCallback? onTap;

  /// Cho phép màn Home ghép nhiều dòng thành một "thẻ" liền mạch
  /// (`bg_card_top/middle/bottom`) thay vì mỗi dòng một khối bo tròn.
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final phase = SportPresentation.eventPhase(event.statusType);
    final started = SportPresentation.usesStartedEventPresentation(
      event.statusType,
    );
    final live = phase == EventPhase.live;

    final radius = borderRadius ?? BorderRadius.circular(12);

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        margin: margin ?? EdgeInsets.only(bottom: AppDimens.sdp(8)),
        padding: EdgeInsets.all(AppDimens.sdp(10)),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: radius,
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppDimens.sdp(42),
              child: Column(
                children: [
                  Text(
                    live
                        ? (event.status?.description ?? 'LIVE')
                        : DateTimeUtils.formatEpochToLocalTime(
                            event.startTimestamp,
                          ),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.medium(
                      size: AppDimens.ssp(10),
                      color: live ? AppColors.brandAccent : AppColors.text100,
                    ),
                  ),
                  Text(
                    DateTimeUtils.formatEpochToLocalDate(event.startTimestamp),
                    style: AppTextStyles.regular(
                      size: AppDimens.ssp(8),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: AppDimens.sdp(36),
              color: AppColors.divider,
              margin: EdgeInsets.symmetric(horizontal: AppDimens.sdp(10)),
            ),
            Expanded(
              child: Column(
                children: [
                  _Competitor(
                    team: event.homeTeam,
                    score: started ? event.homeScore?.current : null,
                    sportSlug: event.sportSlug,
                    winner: event.winnerCode == 1,
                  ),
                  SizedBox(height: AppDimens.sdp(6)),
                  _Competitor(
                    team: event.awayTeam,
                    score: started ? event.awayScore?.current : null,
                    sportSlug: event.sportSlug,
                    winner: event.winnerCode == 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Competitor extends StatelessWidget {
  const _Competitor({
    required this.team,
    required this.score,
    required this.sportSlug,
    required this.winner,
  });

  final Team? team;
  final int? score;
  final String sportSlug;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final useFlag = SportPresentation.homeCompetitorImage(sportSlug) ==
        HomeCompetitorImage.countryFlag;
    final logo = team == null
        ? null
        : (useFlag ? (team!.country?.flagUrl ?? team!.logoUrl) : team!.logoUrl);

    return Row(
      children: [
        AppImage(
          source: logo,
          width: AppDimens.sdp(18),
          height: AppDimens.sdp(18),
        ),
        SizedBox(width: AppDimens.sdp(8)),
        Expanded(
          child: Text(
            team?.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: winner
                ? AppTextStyles.semiBold(
                    size: AppDimens.ssp(12),
                    color: AppColors.text500,
                  )
                : AppTextStyles.regular(
                    size: AppDimens.ssp(12),
                    color: AppColors.text500,
                  ),
          ),
        ),
        Text(
          score?.toString() ?? '-',
          style: AppTextStyles.semiBold(
            size: AppDimens.ssp(12),
            color: AppColors.text500,
          ),
        ),
      ],
    );
  }
}

/// Khối card có tiêu đề — port `view_event_section_card.xml`.
class SofaCard extends StatelessWidget {
  const SofaCard({super.key, required this.title, required this.child});

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

/// Thanh so sánh 2 bên — port `view_match_stat_bar.xml`.
class SofaStatBar extends StatelessWidget {
  const SofaStatBar({
    super.key,
    required this.label,
    required this.home,
    required this.away,
  });

  final String label;
  final String home;
  final String away;

  @override
  Widget build(BuildContext context) {
    final h = double.tryParse(home.replaceAll('%', '')) ?? 0;
    final a = double.tryParse(away.replaceAll('%', '')) ?? 0;
    final total = h + a;
    final ratio = total == 0 ? 0.5 : h / total;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(7)),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                home,
                style: AppTextStyles.semiBold(
                  size: AppDimens.ssp(12),
                  color: AppColors.text500,
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(11),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                away,
                style: AppTextStyles.semiBold(
                  size: AppDimens.ssp(12),
                  color: AppColors.text500,
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimens.sdp(5)),
          Row(
            children: [
              Expanded(
                flex: (ratio * 1000).round().clamp(1, 999),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(width: AppDimens.sdp(4)),
              Expanded(
                flex: ((1 - ratio) * 1000).round().clamp(1, 999),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray2,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thanh tab của các màn Sofascore — giống `tabLayout` bên football:
/// cao 30sdp, không gạch chỉ báo, chọn = accent / còn lại = trắng.
class SofaTabBar extends StatelessWidget {
  const SofaTabBar({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: AppDimens.sdp(30),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(16)),
          itemCount: labels.length,
          itemBuilder: (context, index) => GestureDetector(
            onTap: () => onSelect(index),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(4)),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.sdp(16),
                  vertical: AppDimens.sdp(4),
                ),
                child: Text(
                  labels[index],
                  style: AppTextStyles.medium(
                    size: AppDimens.ssp(12),
                    color: index == selected
                        ? AppColors.brandAccent
                        : AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Header bảng xếp hạng Sofascore — cùng 5 cột với `llTableHeader`
/// của `activity_unique_tournament.xml`: `#` · Team · P · GD · PTS.
class SofaStandingHeader extends StatelessWidget {
  const SofaStandingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.sdp(14),
        top: AppDimens.sdp(6),
        bottom: AppDimens.sdp(6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppDimens.sdp(25),
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(12),
                color: AppColors.text100,
              ),
            ),
          ),
          SizedBox(width: AppDimens.sdp(6)),
          Expanded(
            child: Text(
              s.team,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(10),
                color: AppColors.text100,
              ),
            ),
          ),
          _StandingCell(text: s.tableMatchesPlayed),
          const _StandingCell(text: 'GD'),
          _StandingCell(text: s.tablePoints, marginEnd: true),
        ],
      ),
    );
  }
}

/// Một dòng bảng xếp hạng Sofascore (`{position, team, matches, points, ...}`).
class SofaStandingRow extends StatelessWidget {
  const SofaStandingRow({super.key, required this.row});

  final Map<String, dynamic> row;

  static int _int(dynamic v) => v is num ? v.toInt() : 0;

  @override
  Widget build(BuildContext context) {
    final team = row['team'];
    final teamId = team is Map ? _int(team['id']) : 0;
    final teamName = team is Map ? '${team['name'] ?? ''}' : '';
    final scored = _int(row['scoresFor']);
    final conceded = _int(row['scoresAgainst']);

    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.sdp(14),
        top: AppDimens.sdp(6),
        bottom: AppDimens.sdp(6),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: AppDimens.sdp(25),
                child: Text(
                  '${row['position'] ?? ''}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(12),
                    color: AppColors.text500,
                  ),
                ),
              ),
              SizedBox(width: AppDimens.sdp(4)),
              SizedBox(
                width: AppDimens.sdp(22),
                height: AppDimens.sdp(22),
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.sdp(1)),
                  child: AppImage(
                    source: teamId == 0 ? null : ApiConstants.teamLogo(teamId),
                    placeholderAsset: 'assets/icons/ic_ball.svg',
                  ),
                ),
              ),
              SizedBox(width: AppDimens.sdp(6)),
              Expanded(
                child: Text(
                  teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.medium(
                    size: AppDimens.ssp(10),
                    color: AppColors.text500,
                  ),
                ),
              ),
              _StandingCell(text: '${_int(row['matches'])}'),
              _StandingCell(text: '${scored - conceded}'),
              _StandingCell(text: '${_int(row['points'])}', marginEnd: true),
            ],
          ),
          SizedBox(height: AppDimens.sdp(6)),
          Container(height: 1, color: AppColors.borderColor),
        ],
      ),
    );
  }
}

class _StandingCell extends StatelessWidget {
  const _StandingCell({required this.text, this.marginEnd = false});

  final String text;
  final bool marginEnd;

  @override
  Widget build(BuildContext context) => Container(
        width: AppDimens.sdp(40),
        margin: EdgeInsets.only(right: marginEnd ? AppDimens.sdp(5) : 0),
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          style: AppTextStyles.regular(
            size: AppDimens.ssp(12),
            color: AppColors.text500,
          ),
        ),
      );
}
