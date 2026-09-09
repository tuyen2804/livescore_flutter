import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../domain/entities/match_entities.dart';
import 'home_match_row.dart';

/// Port `item_home_league.xml` + `HomeLeagueAdapter.FootballViewHolder`:
/// nền `bg_border_radius_16_dark`, header logo 18sdp + tên giải 12ssp
/// semi-bold (KHÔNG viết hoa), mũi tên `ic_expand`, gạch ngang rồi tới
/// danh sách trận. Bản gốc mặc định mở sẵn mọi giải.
class HomeLeagueCard extends StatefulWidget {
  const HomeLeagueCard({
    super.key,
    required this.section,
    required this.onMatchTap,
    required this.onToggleNotification,
  });

  final LeagueSection section;
  final void Function(MatchFixture fixture) onMatchTap;
  final void Function(MatchFixture fixture) onToggleNotification;

  /// `MAX_MATCH_ROWS` của bản gốc.
  static const int maxMatchRows = 20;

  @override
  State<HomeLeagueCard> createState() => _HomeLeagueCardState();
}

class _HomeLeagueCardState extends State<HomeLeagueCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final fixtures =
        section.fixtures.take(HomeLeagueCard.maxMatchRows).toList(growable: false);

    return Container(
      margin: EdgeInsets.only(
        left: AppDimens.sdp(10),
        right: AppDimens.sdp(10),
        bottom: AppDimens.sdp(10),
      ),
      decoration: BoxDecoration(
        color: AppColors.itemBg,
        borderRadius: BorderRadius.circular(AppDimens.sdp(16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimens.sdp(10),
                vertical: AppDimens.sdp(10),
              ),
              child: Row(
                children: [
                  AppImage(
                    source: section.leagueLogoUrl,
                    width: AppDimens.sdp(18),
                    height: AppDimens.sdp(18),
                    placeholderAsset: 'assets/icons/ic_league.svg',
                  ),
                  SizedBox(width: AppDimens.sdp(8)),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.leagueName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.semiBold(
                              size: AppDimens.ssp(12),
                              color: AppColors.text500,
                            ),
                          ),
                          if (!section.isFootball &&
                              (section.categoryName?.isNotEmpty ?? false))
                            Text(
                              section.categoryName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.regular(
                                size: AppDimens.ssp(10),
                                color: AppColors.textSecondary,
                              ),
                            ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppDimens.sdp(8)),
                  // `ic_expand` là mũi tên chỉ xuống; mở thì xoay 180°.
                  AnimatedRotation(
                    turns: _expanded ? 0 : 0.5,
                    duration: const Duration(milliseconds: 180),
                    child: SvgPicture.asset(
                      'assets/icons/ic_expand.svg',
                      width: AppDimens.sdp(18),
                      height: AppDimens.sdp(18),
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(10)),
              child: const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.divider,
              ),
            ),
            for (var i = 0; i < fixtures.length; i++)
              HomeMatchRow(
                fixture: fixtures[i],
                showDivider: i != fixtures.length - 1,
                onTap: () => widget.onMatchTap(fixtures[i]),
                onToggleNotification: () =>
                    widget.onToggleNotification(fixtures[i]),
              ),
            SizedBox(height: AppDimens.sdp(8)),
          ],
        ],
      ),
    );
  }
}
