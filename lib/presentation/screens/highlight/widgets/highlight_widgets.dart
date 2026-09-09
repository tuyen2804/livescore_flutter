import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../data/models/football/football_models.dart';
import '../../../providers/highlight_provider.dart';

/// Ảnh nền: ưu tiên `imgUrl` của API, thiếu thì lấy thumbnail YouTube.
String? highlightThumb(HighlightDto item) {
  if (item.imgUrl.isNotEmpty) return item.imgUrl;
  final id = HighlightProvider.youtubeId(item.url);
  return id == null ? null : ApiConstants.youtubeThumb(id);
}

String highlightDate(HighlightDto item) {
  if (item.matchDate <= 0) return '';
  return DateFormat('dd/MM/yyyy')
      .format(DateTime.fromMillisecondsSinceEpoch(item.matchDate * 1000));
}

/// Port `vpHighLight` + `item_highlight_banner.xml`:
/// tỉ lệ 360:200, ảnh `centerCrop`, nút play 50dp, mask mờ trên và dưới,
/// chỉ báo dạng thanh (mục đang xem rộng 40dp, còn lại 8dp).
class HighlightBannerPager extends StatefulWidget {
  const HighlightBannerPager({
    super.key,
    required this.items,
    required this.onTap,
  });

  final List<HighlightDto> items;
  final void Function(HighlightDto item) onTap;

  @override
  State<HighlightBannerPager> createState() => _HighlightBannerPagerState();
}

class _HighlightBannerPagerState extends State<HighlightBannerPager> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return AspectRatio(
      aspectRatio: 360 / 200,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return GestureDetector(
                onTap: () => widget.onTap(item),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(source: highlightThumb(item), fit: BoxFit.cover),
                    Center(
                      child: Image.asset(
                        'assets/images/img_play.png',
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stack) => const Icon(
                          Icons.play_circle_fill,
                          size: 50,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // `mask_banner_highlight` phủ trên và dưới, cao 100sdp.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: AppDimens.sdp(100),
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF181716), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: AppDimens.sdp(100),
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFF181716), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: AppDimens.sdp(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // `bg_radius_primary_100` chỉ có viền 1dp accent, không tô nền;
                // `bg_radius_100` không vẽ gì nên mục chưa chọn gần như vô hình.
                for (var i = 0; i < widget.items.length; i++)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: i == _page ? 1 : 0.5,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 40 : 8,
                      height: 4,
                      decoration: BoxDecoration(
                        border: i == _page
                            ? Border.all(color: AppColors.colorPrimary)
                            : null,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Port `item_category_group.xml`: tên nhóm 14sp `color_d2d3d5`,
/// "View all" 14sp màu accent, hàng ngang tối đa 5 mục.
class HighlightCategoryGroup extends StatelessWidget {
  const HighlightCategoryGroup({
    super.key,
    required this.title,
    required this.items,
    required this.onViewAll,
    required this.onTap,
  });

  final String title;
  final List<HighlightDto> items;
  final VoidCallback onViewAll;
  final void Function(HighlightDto item) onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final visible = items.take(5).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(15)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.medium(
                      size: 14,
                      color: AppColors.colorD2d3d5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onViewAll,
                  child: Text(
                    s.viewAll,
                    style: AppTextStyles.medium(
                      size: 14,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppDimens.sdp(5)),
          SizedBox(
            // 310dp rộng, tỉ lệ 312:180 → cao ≈ 179dp.
            height: 310 * 180 / 312,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: AppDimens.sdp(15)),
              itemCount: visible.length,
              itemBuilder: (context, index) => HighlightCard(
                item: visible[index],
                onTap: () => onTap(visible[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Port `item_highlight.xml`: rộng 310dp, tỉ lệ 312:180, bo góc 24dp,
/// phủ `bg_mask_highlight` và nút play 50dp ở giữa.
class HighlightCard extends StatelessWidget {
  const HighlightCard({
    super.key,
    required this.item,
    required this.onTap,
    this.width = 310,
  });

  final HighlightDto item;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          margin: EdgeInsets.only(right: AppDimens.sdp(10)),
          // `bg_mask_highlight`: viền 1dp `#393941`, bo 24dp, phủ gradient
          // `#181716` → trong suốt từ trên xuống.
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF393941)),
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppImage(source: highlightThumb(item), fit: BoxFit.cover),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF181716), Color(0x00181716)],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Image.asset(
                    'assets/images/img_play.png',
                    width: 50,
                    height: 50,
                    errorBuilder: (context, error, stack) => const Icon(
                      Icons.play_circle_fill,
                      size: 50,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
