import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../providers/match_detail_provider.dart';

/// Port `presentation/detail/MatchH2HFragment.kt` + `fragment_match_h2h.xml`:
/// hai thẻ `bg_border_radius_24_no_stroke` — "Overall" và "Last 5 games" —
/// mỗi thẻ có ba viên Win / Draw / Win chia đều.
class MatchH2HTab extends StatelessWidget {
  const MatchH2HTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<MatchDetailProvider>();
    final h2h = provider.h2h.isEmpty ? null : provider.h2h.first;

    if (h2h == null) {
      return ListView(
        children: [
          SizedBox(height: AppDimens.sdp(60)),
          AppEmptyView(message: s.theFieldIsQuiteEmpty),
        ],
      );
    }

    // Bản gốc suy ra số thắng của khách trong 5 trận gần nhất: 5 - thắng - hoà.
    final lastHome = h2h.winLastFive ?? 0;
    final lastDraw = h2h.drawsLastFive ?? 0;
    final lastAway = (5 - lastHome - lastDraw).clamp(0, 5);

    return ListView(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
      children: [
        SizedBox(height: AppDimens.sdp(16)),
        _H2HCard(
          title: s.overall,
          home: h2h.totalWin ?? 0,
          draw: h2h.totalDraws ?? 0,
          away: h2h.totalLoss ?? 0,
        ),
        SizedBox(height: AppDimens.sdp(32)),
        _H2HCard(
          title: s.last5Games,
          home: lastHome,
          draw: lastDraw,
          away: lastAway,
        ),
        SizedBox(height: AppDimens.sdp(16)),
      ],
    );
  }
}

class _H2HCard extends StatelessWidget {
  const _H2HCard({
    required this.title,
    required this.home,
    required this.draw,
    required this.away,
  });

  final String title;
  final int home;
  final int draw;
  final int away;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.all(AppDimens.sdp(12)),
        decoration: BoxDecoration(
          color: const Color(0xFF20201F),
          borderRadius: BorderRadius.circular(AppDimens.sdp(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bold(
                size: AppDimens.ssp(13),
                color: AppColors.text100,
              ),
            ),
            SizedBox(height: AppDimens.sdp(10)),
            Row(
              children: [
                Expanded(
                  child: _Pill(
                    text: 'Win: $home',
                    color: const Color(0xFFD2E3FF),
                  ),
                ),
                SizedBox(width: AppDimens.sdp(4)),
                Expanded(
                  child: _Pill(
                    text: 'Draw: $draw',
                    color: const Color(0xFFFFDAB9),
                  ),
                ),
                SizedBox(width: AppDimens.sdp(4)),
                Expanded(
                  child: _Pill(
                    text: 'Win: $away',
                    color: const Color(0xFF8ADB83),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

/// `bg_h2h_home/draw/away`: nền pastel, bo 4sdp, chữ đen 8ssp regular,
/// paddingV 6sdp.
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(6)),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimens.sdp(4)),
        ),
        child: Text(
          text,
          style: AppTextStyles.regular(
            size: AppDimens.ssp(8),
            color: Colors.black,
          ),
        ),
      );
}
