import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/football/football_models.dart';
import '../../providers/highlight_provider.dart';
import 'widgets/highlight_widgets.dart';

/// Port `presentation/highlight/HighlightFragment.kt` + `fragment_highlight.xml`:
/// toolbar 74sdp → banner ViewPager tỉ lệ 360:200 (3 mục đầu) có mask trên/dưới
/// và chỉ báo dạng thanh → danh sách nhóm ngang bên dưới.
class HighlightScreen extends StatelessWidget {
  const HighlightScreen({super.key});

  static void openDetail(BuildContext context, HighlightDto item) {
    Navigator.of(context).pushNamed(
      AppRoutes.highlightDetail,
      arguments: {
        'url': item.url,
        'title': item.title,
        'homeTeam': item.homeTeamName,
        'awayTeam': item.awayTeamName,
        'leagueName': item.leagueName,
        'thumb': item.imgUrl,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<HighlightProvider>();
    final all = provider.highlights;

    // `HighlightFragment.observeViewModel`: 3 mục đầu làm banner,
    // 10 mục kế là nhóm "popular", phần còn lại là nhóm "other".
    final banners = all.take(3).toList(growable: false);
    final popular = all.skip(3).take(10).toList(growable: false);
    final other = all.skip(13).toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Column(
        children: [
          Container(
            height: AppDimens.sdp(74),
            width: double.infinity,
            color: AppColors.itemBg,
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(top: AppDimens.sdp(28)),
            child: Text(
              s.highlights,
              style: AppTextStyles.bold(
                size: AppDimens.ssp(18),
                color: AppColors.text500,
              ),
            ),
          ),
          Expanded(
            child: provider.isLoading && all.isEmpty
                ? const EarthLoadingOverlay(label: 'Loading')
                : all.isEmpty
                    ? AppEmptyView(message: s.theFieldIsQuiteEmpty)
                    : RefreshIndicator(
                        color: AppColors.brandAccent,
                        backgroundColor: AppColors.itemBg,
                        onRefresh: provider.fetchHighlights,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            HighlightBannerPager(
                              items: banners,
                              onTap: (item) => openDetail(context, item),
                            ),
                            SizedBox(height: AppDimens.sdp(15)),
                            if (popular.isNotEmpty)
                              HighlightCategoryGroup(
                                // Bản gốc gắn 🔥 riêng cho nhóm "popular".
                                title: '🔥 ${s.popular}',
                                items: popular,
                                onViewAll: () => _openList(
                                  context,
                                  '${s.popular} ${s.highlights}',
                                  popular,
                                ),
                                onTap: (item) => openDetail(context, item),
                              ),
                            if (other.isNotEmpty)
                              HighlightCategoryGroup(
                                title: s.other,
                                items: other,
                                onViewAll: () => _openList(
                                  context,
                                  '${s.other} ${s.highlights}',
                                  other,
                                ),
                                onTap: (item) => openDetail(context, item),
                              ),
                            SizedBox(height: AppDimens.sdp(16)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _openList(BuildContext context, String title, List<HighlightDto> items) {
    Navigator.of(context).pushNamed(
      AppRoutes.highlightList,
      arguments: {
        'title': title,
        'ids': items.map((e) => e.id).toList(growable: false),
      },
    );
  }
}

/// Port `item_highlight_detail.xml` — layout `HighlightListAdapter` thực sự
/// dùng: ảnh tỉ lệ 312:180 bo 24dp phủ `bg_mask_highlight`, nút play 50dp,
/// tiêu đề 13ssp bold và mô tả 10ssp `#888888`; paddingH 8dp paddingV 14dp.
class HighlightListRow extends StatelessWidget {
  const HighlightListRow({super.key, required this.item, required this.onTap});

  final HighlightDto item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 312 / 180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF393941)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppImage(
                          source: highlightThumb(item),
                          fit: BoxFit.cover,
                        ),
                        const IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF181716),
                                  Color(0x00181716),
                                ],
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
              ),
              SizedBox(height: AppDimens.sdp(6)),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bold(
                  size: AppDimens.ssp(13),
                  color: AppColors.text500,
                ),
              ),
              SizedBox(height: AppDimens.sdp(4)),
              Text(
                highlightDate(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(10),
                  color: const Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      );
}
