import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../data/models/local/db_entities.dart';
import '../../providers/notification_provider.dart';

/// Port `presentation/notification/NotificationSettingsFragment.kt` —
/// chỉnh mốc báo cho từng trận đã bật thông báo.
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // `toolbar` của `fragment_notification_settings.xml`: cao theo nội
            // dung, paddingV 12sdp, back `ic_back` 24sdp padding 4sdp,
            // tiêu đề 16ssp căn giữa.
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(12)),
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'Notification Settings',
                      style: AppTextStyles.medium(
                        size: AppDimens.ssp(16),
                        color: AppColors.text500,
                      ),
                    ),
                    Positioned(
                      left: AppDimens.sdp(16),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: SizedBox(
                          width: AppDimens.sdp(24),
                          height: AppDimens.sdp(24),
                          child: Padding(
                            padding: EdgeInsets.all(AppDimens.sdp(4)),
                            child: SvgPicture.asset(
                              'assets/icons/ic_back.svg',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: provider.isLoading
                  ? const EarthLoadingOverlay(label: 'Loading')
                  : provider.isEmpty
                      ? AppEmptyView(message: s.theFieldIsQuiteEmpty)
                      : ListView.builder(
                          padding: EdgeInsets.all(AppDimens.sdp(16)),
                          itemCount: provider.items.length,
                          itemBuilder: (context, index) => _ConfigCard(
                            item: provider.items[index],
                            onChanged: provider.updateConfig,
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.item, required this.onChanged});

  final NotificationDbItem item;
  final Future<void> Function(NotificationDbItem) onChanged;

  static const List<int> _minuteOptions = [5, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: AppDimens.sdp(10)),
      padding: EdgeInsets.all(AppDimens.sdp(12)),
      decoration: BoxDecoration(
        color: AppColors.itemBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${item.homeName} vs ${item.awayName}',
            style: AppTextStyles.semiBold(
              size: AppDimens.ssp(13),
              color: AppColors.text500,
            ),
          ),
          SizedBox(height: AppDimens.sdp(10)),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.matchAlarmBeforeMatch,
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              DropdownButton<int>(
                value: _minuteOptions.contains(item.beforeMatchMinutes)
                    ? item.beforeMatchMinutes
                    : 15,
                dropdownColor: AppColors.itemBg,
                underline: const SizedBox.shrink(),
                style: AppTextStyles.medium(
                  size: AppDimens.ssp(12),
                  color: AppColors.brandAccent,
                ),
                items: [
                  for (final m in _minuteOptions)
                    DropdownMenuItem(value: m, child: Text("$m'")),
                ],
                onChanged: (value) => value == null
                    ? null
                    : onChanged(item.copyWith(beforeMatchMinutes: value)),
              ),
            ],
          ),
          _SwitchRow(
            label: s.matchStart,
            value: item.notifyMatchStart,
            onChanged: (v) => onChanged(item.copyWith(notifyMatchStart: v)),
          ),
          _SwitchRow(
            label: s.endOfFirstHalf,
            value: item.notifyEndFirstHalf,
            onChanged: (v) => onChanged(item.copyWith(notifyEndFirstHalf: v)),
          ),
          _SwitchRow(
            label: s.startOfSecondHalf,
            value: item.notifyStartSecondHalf,
            onChanged: (v) =>
                onChanged(item.copyWith(notifyStartSecondHalf: v)),
          ),
          _SwitchRow(
            label: s.fullTime,
            value: item.notifyEndMatch,
            onChanged: (v) => onChanged(item.copyWith(notifyEndMatch: v)),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(12),
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.brandAccent,
            onChanged: onChanged,
          ),
        ],
      );
}
