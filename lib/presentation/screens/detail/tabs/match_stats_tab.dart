import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../providers/match_detail_provider.dart';

/// Port `presentation/detail/MatchStatsFragment.kt`: danh sách phẳng các dòng
/// `item_match_stat.xml`, không có thẻ bọc ngoài.
class MatchStatsTab extends StatelessWidget {
  const MatchStatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<MatchDetailProvider>();
    final home = provider.statsFor(home: true);
    final away = provider.statsFor(home: false);

    // Bản gốc chỉ dựng danh sách khi có đủ số liệu của cả hai đội.
    if (home == null || away == null) {
      return ListView(
        children: [
          SizedBox(height: AppDimens.sdp(60)),
          AppEmptyView(message: s.theFieldIsQuiteEmpty),
        ],
      );
    }

    // Tên và thứ tự lấy nguyên từ `StatsAdapter.init` — bản gốc không dịch.
    final rows = <(String, int, int)>[
      ('Possession (%)', home.possession ?? 0, away.possession ?? 0),
      ('Shots on Target', home.shotOnTarget ?? 0, away.shotOnTarget ?? 0),
      ('Shots off Target', home.shotOffTarget ?? 0, away.shotOffTarget ?? 0),
      ('Blocked Shots', home.blockerShots ?? 0, away.blockerShots ?? 0),
      ('Corner Kicks', home.cornerKicks ?? 0, away.cornerKicks ?? 0),
      ('Offsides', home.offsides ?? 0, away.offsides ?? 0),
      ('Fouls', home.fouls ?? 0, away.fouls ?? 0),
      ('Throw-ins', home.throwIn ?? 0, away.throwIn ?? 0),
      ('Yellow Cards', home.yellowCards ?? 0, away.yellowCards ?? 0),
      ('Red Cards', home.redCards ?? 0, away.redCards ?? 0),
    ];

    return ListView(
      padding: EdgeInsets.only(bottom: AppDimens.sdp(16)),
      children: [
        for (final row in rows)
          _StatRow(label: row.$1, home: row.$2, away: row.$3),
      ],
    );
  }
}

/// Port `item_match_stat.xml`: dòng cao 44dp, hai viên `bg_item_stats`
/// (nền `#283240`, viền `#3B495E`, bo 16dp) cao 28dp kèm chấm 7dp.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.home,
    required this.away,
  });

  final String label;
  final int home;
  final int away;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              _Chip(value: '$home', dotFirst: false),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.semiBold(
                      size: 12,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
              ),
              _Chip(value: '$away', dotFirst: true),
            ],
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.value, required this.dotFirst});

  final String value;
  final bool dotFirst;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: AppColors.brandAccent,
        shape: BoxShape.circle,
      ),
    );
    final text = Text(
      value,
      style: AppTextStyles.semiBold(size: 11, color: const Color(0xFFF8FAFC)),
    );

    return Container(
      height: 28,
      padding: EdgeInsets.only(
        left: dotFirst ? 8 : 10,
        right: dotFirst ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF283240),
        border: Border.all(color: const Color(0xFF3B495E)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: dotFirst
            ? [dot, const SizedBox(width: 6), text]
            : [text, const SizedBox(width: 6), dot],
      ),
    );
  }
}
