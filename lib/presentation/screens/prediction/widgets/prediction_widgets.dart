import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../domain/entities/match_entities.dart';

/// Port `bg_pill_selected` / `bg_pill_unselected`: bo 20sdp,
/// chọn = nền accent + chữ đen, không chọn = nền `color_item_bg` + chữ text500.
class PredictionPill extends StatelessWidget {
  const PredictionPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(8)),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandAccent : AppColors.itemBg,
            borderRadius: BorderRadius.circular(AppDimens.sdp(20)),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.medium(
              size: AppDimens.ssp(13),
              color: selected ? AppColors.black : AppColors.text500,
            ),
          ),
        ),
      );
}

/// Port `item_prediction_league.xml`: header logo 26sdp + tên 13ssp bold,
/// mũi tên `ic_expand` 18sdp; nhóm không có nền, các trận mới có.
class PredictionLeagueGroup extends StatefulWidget {
  const PredictionLeagueGroup({
    super.key,
    required this.section,
    required this.onMatchTap,
  });

  final LeagueSection section;
  final void Function(MatchFixture fixture) onMatchTap;

  @override
  State<PredictionLeagueGroup> createState() => _PredictionLeagueGroupState();
}

class _PredictionLeagueGroupState extends State<PredictionLeagueGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.sdp(14),
        right: AppDimens.sdp(14),
        bottom: AppDimens.sdp(10),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(8)),
              child: Row(
                children: [
                  SizedBox(
                    width: AppDimens.sdp(26),
                    height: AppDimens.sdp(26),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: AppImage(
                        source: section.leagueLogoUrl,
                        placeholderAsset: 'assets/icons/ic_league.svg',
                      ),
                    ),
                  ),
                  SizedBox(width: AppDimens.sdp(12)),
                  Expanded(
                    child: Text(
                      section.leagueName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bold(
                        size: AppDimens.ssp(13),
                        color: AppColors.text500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: AppDimens.sdp(18),
                    height: AppDimens.sdp(18),
                    child: Padding(
                      padding: EdgeInsets.all(AppDimens.sdp(2)),
                      child: AnimatedRotation(
                        turns: _expanded ? 0 : 0.5,
                        duration: const Duration(milliseconds: 180),
                        child: SvgPicture.asset('assets/icons/ic_expand.svg'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            for (final fixture in section.fixtures)
              PredictionMatchRow(
                fixture: fixture,
                onTap: () => widget.onMatchTap(fixture),
              ),
        ],
      ),
    );
  }
}

/// Port `item_prediction_match.xml`: nền `bg_border_radius_16_dark`,
/// padding 12sdp — cột trạng thái/giờ/ngày màu accent, vạch dọc,
/// hai đội logo 20sdp + tên 12ssp semi-bold, nút "Result" viền accent.
class PredictionMatchRow extends StatelessWidget {
  const PredictionMatchRow({
    super.key,
    required this.fixture,
    required this.onTap,
  });

  final MatchFixture fixture;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: AppDimens.sdp(8)),
        padding: EdgeInsets.all(AppDimens.sdp(12)),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(AppDimens.sdp(16)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    fixture.status,
                    style: AppTextStyles.bold(
                      size: AppDimens.ssp(11),
                      color: AppColors.brandAccent,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fixture.matchTime,
                    style: AppTextStyles.medium(
                      size: AppDimens.ssp(10),
                      color: AppColors.brandAccent,
                    ),
                  ),
                  if (fixture.matchDate?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 2),
                    Text(
                      fixture.matchDate!,
                      style: AppTextStyles.regular(
                        size: AppDimens.ssp(10),
                        color: AppColors.brandAccent,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(width: AppDimens.sdp(4)),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.divider,
              ),
              SizedBox(width: AppDimens.sdp(12)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TeamLine(
                      name: fixture.teamHome,
                      logo: fixture.homeLogoUrl,
                    ),
                    SizedBox(height: AppDimens.sdp(12)),
                    _TeamLine(
                      name: fixture.teamAway,
                      logo: fixture.awayLogoUrl,
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppDimens.sdp(8)),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.sdp(14),
                    vertical: AppDimens.sdp(4),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.sdp(20)),
                    border: Border.all(color: AppColors.brandAccent),
                  ),
                  child: Text(
                    s.result,
                    style: AppTextStyles.bold(
                      size: AppDimens.ssp(10),
                      color: AppColors.brandAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  const _TeamLine({required this.name, required this.logo});

  final String name;
  final String? logo;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: AppDimens.sdp(20),
            height: AppDimens.sdp(20),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AppImage(
                source: logo,
                placeholderAsset: 'assets/icons/ic_ball.svg',
              ),
            ),
          ),
          SizedBox(width: AppDimens.sdp(10)),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.semiBold(
                size: AppDimens.ssp(12),
                color: AppColors.text500,
              ),
            ),
          ),
        ],
      );
}
