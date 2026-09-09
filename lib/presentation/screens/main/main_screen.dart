import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../highlight/highlight_screen.dart';
import '../home/home_screen.dart';
import '../leagues/leagues_screen.dart';
import '../prediction/prediction_screen.dart';
import '../teams/teams_screen.dart';
import '../../providers/teams_provider.dart';

/// Port `presentation/main/MainFragment.kt` + `fragment_main.xml`:
/// thanh dưới nền `color_item_bg`, padding dọc 8dp / ngang 10sdp,
/// icon 24dp + nhãn 10sp, màu theo `color/tab_text_color.xml`
/// (chọn = #FFA600, không chọn = #64748B).
/// Hai khung quảng cáo `frAds` / `containerCollapExpand` đã bỏ.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _index = widget.initialTab;

  static const List<Widget> _pages = [
    HomeScreen(),
    LeaguesScreen(),
    HighlightScreen(),
    TeamsScreen(),
    PredictionScreen(),
  ];

  static const int _teamsTab = 3;

  /// `TeamsFragment.onResume` gọi `viewModel.loadData()` mỗi lần tab hiện lên;
  /// `IndexedStack` giữ tab sống nên phải nạp lại thủ công khi chuyển sang.
  void _select(int i) {
    setState(() => _index = i);
    if (i == _teamsTab) {
      context.read<TeamsProvider>().loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final items = <_NavItem>[
      _NavItem(asset: 'assets/icons/ic_explore_state.svg', label: s.explore),
      _NavItem(asset: 'assets/icons/ic_league_state.svg', label: s.leagues),
      _NavItem(
        asset: 'assets/icons/ic_highlight_state.svg',
        label: s.highlights,
      ),
      _NavItem(asset: 'assets/icons/ic_team_state.svg', label: s.teams),
      _NavItem(asset: 'assets/icons/ic_prediction.svg', label: s.prediction),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        color: AppColors.itemBg,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.sdp(10),
              vertical: 8,
            ),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: items[i],
                      selected: _index == i,
                      onTap: () => _select(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.asset, required this.label});

  final String asset;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brandAccent : AppColors.tabInactive;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          SvgPicture.asset(
            item.asset,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyles.regular(size: 10, color: color),
          ),
        ],
      ),
    );
  }
}
