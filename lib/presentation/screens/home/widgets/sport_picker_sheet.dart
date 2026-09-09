import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/sport_presentation.dart';

/// Port `BottomSheetSportPicker.kt` + `bottom_sheet_sport_picker.xml`.
class SportPickerSheet extends StatefulWidget {
  const SportPickerSheet({
    super.key,
    required this.sports,
    required this.selected,
    required this.liveCount,
    required this.totalCount,
  });

  final List<String> sports;
  final String selected;
  final int Function(String slug) liveCount;
  final int Function(String slug) totalCount;

  static Future<String?> show(
    BuildContext context, {
    required List<String> sports,
    required String selected,
    required int Function(String) liveCount,
    required int Function(String) totalCount,
  }) =>
      showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => SportPickerSheet(
          sports: sports,
          selected: selected,
          liveCount: liveCount,
          totalCount: totalCount,
        ),
      );

  @override
  State<SportPickerSheet> createState() => _SportPickerSheetState();
}

class _SportPickerSheetState extends State<SportPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final filtered = _query.isEmpty
        ? widget.sports
        : widget.sports
            .where((slug) => SportPresentation.label(slug)
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            SizedBox(height: AppDimens.sdp(10)),
            Container(
              width: AppDimens.sdp(40),
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppDimens.sdp(12)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(16)),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(14),
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.bgApp,
                  hintText: s.sportPickerSearchHint,
                  hintStyle: AppTextStyles.regular(
                    size: AppDimens.ssp(14),
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textSecondary),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: AppDimens.sdp(12)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: AppDimens.sdp(8)),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(8)),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final slug = filtered[index];
                  final live = widget.liveCount(slug);
                  final total = widget.totalCount(slug);
                  final selected = slug == widget.selected;
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(slug),
                    leading: Icon(
                      SportPresentation.icon(slug),
                      color: selected
                          ? AppColors.brandAccent
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      SportPresentation.label(slug),
                      style: AppTextStyles.medium(
                        size: AppDimens.ssp(14),
                        color: selected
                            ? AppColors.brandAccent
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (live > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$live',
                              style: AppTextStyles.semiBold(
                                size: 10,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        if (total > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '$total',
                            style: AppTextStyles.regular(
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
