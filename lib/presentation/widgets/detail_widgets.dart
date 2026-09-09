import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';

/// Toolbar 74sdp dùng chung cho các màn chi tiết (`fragment_detail_team.xml`,
/// `fragment_league_detail.xml`): back 30sdp bên trái, tiêu đề 18ssp căn giữa
/// với `marginEnd 40sdp` để bù chỗ nút back.
class DetailToolbar extends StatelessWidget {
  const DetailToolbar({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        height: AppDimens.sdp(74),
        color: AppColors.itemBg,
        padding: EdgeInsets.only(
          top: AppDimens.sdp(25),
          left: AppDimens.sdp(14),
          right: AppDimens.sdp(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              child: SizedBox(
                width: AppDimens.sdp(30),
                height: AppDimens.sdp(30),
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.sdp(2)),
                  child: SvgPicture.asset('assets/icons/ic_arrow_back.svg'),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: AppDimens.sdp(40)),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.medium(
                    size: AppDimens.ssp(18),
                    color: AppColors.text500,
                  ),
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      );
}

/// Port cặp `bg_unselect_lang` + `bg_tab`: vỏ bo 50sdp nền `color_item_bg`,
/// tab đang chọn nền accent bo 30sdp, chữ theo `tab_text_selector`.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.symmetric(horizontal: AppDimens.sdp(14)),
        padding: EdgeInsets.all(AppDimens.sdp(1)),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(AppDimens.sdp(50)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < tabs.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(8)),
                    decoration: BoxDecoration(
                      color: i == selected
                          ? AppColors.brandAccent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppDimens.sdp(30)),
                    ),
                    child: Text(
                      tabs[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.medium(
                        size: AppDimens.ssp(12),
                        color: AppColors.text500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// Port `bg_border_16_green_left`: nền #0F0F0F bo 16dp, viền trái 2dp accent.
class GreenLeftCard extends StatelessWidget {
  const GreenLeftCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: AppDimens.sdp(10)),
          decoration: BoxDecoration(
            color: AppColors.brandAccent,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.only(left: 2, top: 1, right: 1, bottom: 1),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.color0f,
              borderRadius: BorderRadius.circular(14),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.sdp(10),
              vertical: AppDimens.sdp(6),
            ),
            child: child,
          ),
        ),
      );
}

/// `divider_gradient_primary` — mờ dần từ trong suốt sang #66C8F558.
class GradientDivider extends StatelessWidget {
  const GradientDivider({super.key, this.height = 1});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0x00C8F558), Color(0x66C8F558)],
          ),
        ),
      );
}


/// Port `divider_gradient_timeline.xml`: dải 1sdp chuyển từ trong suốt
/// sang `#2d3442`. Đặt `fadeFromStart` để đảo chiều (bản gốc xoay 180°).
class TimelineGradientLine extends StatelessWidget {
  const TimelineGradientLine({super.key, this.fadeFromStart = true});

  final bool fadeFromStart;

  @override
  Widget build(BuildContext context) => Container(
        height: AppDimens.sdp(1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: fadeFromStart
                ? const [Color(0x002D3442), Color(0xFF2D3442)]
                : const [Color(0xFF2D3442), Color(0x002D3442)],
          ),
        ),
      );
}

/// Port `view_match_stat_bar.xml` + `MatchStatBarView.setData`:
/// thanh 24sdp chia theo tỉ lệ (nhà `#00E676`, hoà `#616161`, khách `#2979FF`)
/// kèm hàng chú thích ba chấm 8sdp.
class MatchStatBar extends StatelessWidget {
  const MatchStatBar({
    super.key,
    required this.home,
    required this.draw,
    required this.away,
  });

  final int home;
  final int draw;
  final int away;

  static const Color _homeColor = Color(0xFF00E676);
  static const Color _drawColor = Color(0xFF616161);
  static const Color _awayColor = Color(0xFF2979FF);

  @override
  Widget build(BuildContext context) {
    final safeTotal = (home + draw + away) < 1 ? 1 : home + draw + away;
    final pHome = home * 100 ~/ safeTotal;
    final pDraw = draw * 100 ~/ safeTotal;
    final pAway = away * 100 ~/ safeTotal;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
          child: Container(
            height: AppDimens.sdp(24),
            color: AppColors.itemBg,
            child: Row(
              children: [
                if (home > 0)
                  Expanded(
                    flex: home,
                    child: _Segment(
                      text: '$pHome%',
                      color: _homeColor,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                // Bản gốc ẩn hẳn phần hoà khi bằng 0 để không lộ mép.
                if (draw > 0)
                  Expanded(
                    flex: draw,
                    child: _Segment(
                      text: '$pDraw%',
                      color: _drawColor,
                      alignment: Alignment.center,
                    ),
                  ),
                if (away > 0)
                  Expanded(
                    flex: away,
                    child: _Segment(
                      text: '$pAway%',
                      color: _awayColor,
                      alignment: Alignment.centerRight,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppDimens.sdp(12)),
        Row(
          children: [
            Expanded(
              child: _Legend(
                color: AppColors.brandAccent,
                text: 'Win: $home',
                alignment: MainAxisAlignment.start,
              ),
            ),
            Expanded(
              child: _Legend(
                color: _drawColor,
                text: 'Draw: $draw',
                alignment: MainAxisAlignment.center,
              ),
            ),
            Expanded(
              child: _Legend(
                color: _awayColor,
                text: 'Win: $away',
                alignment: MainAxisAlignment.end,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.text,
    required this.color,
    required this.alignment,
  });

  final String text;
  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Container(
        color: color,
        alignment: alignment,
        padding: EdgeInsets.symmetric(
          horizontal: alignment == Alignment.center
              ? AppDimens.sdp(4)
              : AppDimens.sdp(8),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: AppTextStyles.bold(
            size: AppDimens.ssp(10),
            color: AppColors.white,
          ),
        ),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.text,
    required this.alignment,
  });

  final Color color;
  final String text;
  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: alignment,
        children: [
          Container(
            width: AppDimens.sdp(8),
            height: AppDimens.sdp(8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: AppDimens.sdp(6)),
          Text(
            text,
            style: AppTextStyles.medium(
              size: AppDimens.ssp(10),
              color: AppColors.text500,
            ),
          ),
        ],
      );
}
