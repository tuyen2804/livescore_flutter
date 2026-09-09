import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../widgets/settings_toolbar.dart';
import '../../providers/highlight_provider.dart';
import 'highlight_screen.dart';

/// Port `presentation/highlight/HighlightListFragment.kt`:
/// danh sách dọc dùng `item_highlight_list.xml`, nhận sẵn tập id được
/// truyền từ màn Highlight (bản gốc truyền cả list qua Gson).
class HighlightListScreen extends StatelessWidget {
  const HighlightListScreen({super.key, required this.title, this.ids});

  final String title;
  final List<int>? ids;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<HighlightProvider>();
    final idSet = ids?.toSet();
    final items = idSet == null
        ? provider.highlights
        : provider.highlights.where((h) => idSet.contains(h.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Column(
        children: [
          SettingsToolbar(title: title),
          Expanded(
            child: provider.isLoading && items.isEmpty
                ? const EarthLoadingOverlay(label: 'Loading')
                : items.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: AppDimens.sdp(60)),
                          AppEmptyView(message: s.theFieldIsQuiteEmpty),
                        ],
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(
                          top: AppDimens.sdp(8),
                          left: AppDimens.sdp(8),
                          right: AppDimens.sdp(8),
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) => HighlightListRow(
                          item: items[index],
                          onTap: () =>
                              HighlightScreen.openDetail(context, items[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
