import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../data/models/football/football_models.dart';
import '../../../providers/match_detail_provider.dart';

/// Port `item_match_table.xml` + `TableAdapter`: 5 cột —
/// `#` (25sdp) · Team · P · GD · PTS (mỗi cột 40sdp), gạch dưới `divider_gray`.
class MatchTableTab extends StatelessWidget {
  const MatchTableTab({
    super.key,
    this.standings,
    this.highlightTeamIds,
    this.showHeader = false,
    this.showAccentLine = true,
  });

  final List<StandingTeamDto>? standings;
  final Set<int>? highlightTeamIds;
  final bool showHeader;

  /// `fragment_match_table.xml` có vạch 1.5dp màu accent ngay trên bảng.
  final bool showAccentLine;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.read<MatchDetailProvider?>();
    final rows = standings ?? provider?.standings ?? const <StandingTeamDto>[];

    if (rows.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: AppDimens.sdp(60)),
          AppEmptyView(message: s.theFieldIsQuiteEmpty),
        ],
      );
    }

    // Bản gốc `TableAdapter` không tô sáng đội nào; chỉ màn giải mới truyền vào.
    final highlight = highlightTeamIds ?? const <int>{};

    return ListView(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
      children: [
        if (showHeader) const StandingTableHeader(),
        if (showAccentLine)
          Container(height: 1.5, color: AppColors.settingsAccent),
        for (final team in rows)
          StandingTableRow(
            team: team,
            highlighted: highlight.contains(team.id),
          ),
      ],
    );
  }
}

/// Port `llTableHeader` của `fragment_league_detail.xml`.
class StandingTableHeader extends StatelessWidget {
  const StandingTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.only(
        top: AppDimens.sdp(6),
        bottom: AppDimens.sdp(6),
      ),
      child: Row(
        children: [
          // Chừa đúng bề rộng dải màu khu vực ở hàng dữ liệu.
          SizedBox(width: AppDimens.sdp(3 + 11)),
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
          // 4 + 22 + 6: chừa chỗ logo đội, không thì chữ "Team" lệch hẳn sang
          // trái so với tên đội bên dưới.
          SizedBox(width: AppDimens.sdp(4 + 22 + 6)),
          Expanded(
            child: Text(
              s.team,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(10),
                color: AppColors.text100,
              ),
            ),
          ),
          _HeaderCell(label: s.tableMatchesPlayed),
          const _HeaderCell(label: 'W'),
          const _HeaderCell(label: 'D'),
          const _HeaderCell(label: 'L'),
          const _HeaderCell(label: 'GD'),
          _HeaderCell(label: s.tablePoints, marginEnd: true),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, this.marginEnd = false});

  final String label;
  final bool marginEnd;

  @override
  Widget build(BuildContext context) => Container(
        width: AppDimens.sdp(_cellWidth),
        margin: EdgeInsets.only(right: marginEnd ? AppDimens.sdp(5) : 0),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          style: AppTextStyles.regular(
            size: AppDimens.ssp(12),
            color: AppColors.text100,
          ),
        ),
      );
}

/// Port `item_match_table.xml`.
class StandingTableRow extends StatelessWidget {
  const StandingTableRow({
    super.key,
    required this.team,
    this.highlighted = false,
  });

  final StandingTeamDto team;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Container(
        color: highlighted
            ? AppColors.brandAccent.withValues(alpha: 0.12)
            : Colors.transparent,
        padding: EdgeInsets.only(
          top: AppDimens.sdp(6),
          bottom: AppDimens.sdp(6),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Dải màu khu vực cuối bảng: xanh lá dự cúp lớn, cam cúp hạng
                // dưới, đỏ xuống hạng. Giải không khai `promotion` thì dải
                // trong suốt, bảng nhìn y như cũ.
                Container(
                  width: AppDimens.sdp(3),
                  height: AppDimens.sdp(22),
                  color: _zoneColor(team.promotionGroup),
                ),
                SizedBox(width: AppDimens.sdp(11)),
                SizedBox(
                  width: AppDimens.sdp(25),
                  child: Text(
                    '${team.position}',
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
                      source: team.imagePath,
                      placeholderAsset: 'assets/icons/ic_ball.svg',
                    ),
                  ),
                ),
                SizedBox(width: AppDimens.sdp(6)),
                Expanded(
                  child: Text(
                    team.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.medium(
                      size: AppDimens.ssp(10),
                      color: AppColors.text500,
                    ),
                  ),
                ),
                _ValueCell(text: '${team.overallMatches ?? 0}'),
                _ValueCell(text: '${team.won ?? 0}'),
                _ValueCell(text: '${team.draw ?? 0}'),
                _ValueCell(text: '${team.lost ?? 0}'),
                _ValueCell(
                  text: _signed(team.goalDifference),
                  color: _diffColor(team.goalDifference),
                ),
                _ValueCell(
                  text: '${team.points}',
                  marginEnd: true,
                  bold: true,
                ),
              ],
            ),
            SizedBox(height: AppDimens.sdp(6)),
            Container(height: 1, color: AppColors.borderColor),
          ],
        ),
      );
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.text,
    this.marginEnd = false,
    this.color,
    this.bold = false,
  });

  final String text;
  final bool marginEnd;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) => Container(
        width: AppDimens.sdp(_cellWidth),
        margin: EdgeInsets.only(right: marginEnd ? AppDimens.sdp(5) : 0),
        alignment: Alignment.center,
        child: Text(
          text,
          maxLines: 1,
          style: bold
              ? AppTextStyles.semiBold(
                  size: AppDimens.ssp(12),
                  color: color ?? AppColors.textPrimary,
                )
              : AppTextStyles.regular(
                  size: AppDimens.ssp(12),
                  color: color ?? AppColors.text500,
                ),
        ),
      );
}

/// Sáu cột số phải vừa một dòng cùng tên đội, nên hẹp hơn mức 40sdp của bản
/// gốc vốn chỉ có ba cột.
const double _cellWidth = 26;

String _signed(int? value) {
  final v = value ?? 0;
  return v > 0 ? '+$v' : '$v';
}

Color _diffColor(int? value) {
  final v = value ?? 0;
  if (v > 0) return AppColors.homeColor;
  if (v < 0) return AppColors.awayColor;
  return AppColors.text500;
}

Color _zoneColor(int group) => switch (group) {
      1 => AppColors.homeColor,
      2 => AppColors.drawColor,
      3 => AppColors.awayColor,
      _ => Colors.transparent,
    };
