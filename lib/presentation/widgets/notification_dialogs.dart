import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';

/// Port `MatchNotificationConfig` của `MatchNotificationDialog.kt`.
class MatchNotificationConfig {
  const MatchNotificationConfig({
    this.beforeMatchMinutes = 15,
    this.notifyMatchStart = true,
    this.notifyEndFirstHalf = true,
    this.notifyStartSecondHalf = false,
    this.notifyEndMatch = false,
  });

  final int beforeMatchMinutes;
  final bool notifyMatchStart;
  final bool notifyEndFirstHalf;
  final bool notifyStartSecondHalf;
  final bool notifyEndMatch;
}

/// Port `dialog_match_notifications.xml` + `MatchNotificationDialog.kt`:
/// bottom sheet nền `bg_dialog_round` (bo 20dp trên, viền 1sdp #4b4f58),
/// hai bánh xe chọn giờ/phút, 4 ô chọn loại thông báo và nút Done.
class MatchNotificationDialog extends StatefulWidget {
  const MatchNotificationDialog({super.key, this.initial});

  final MatchNotificationConfig? initial;

  static Future<MatchNotificationConfig?> show(
    BuildContext context, {
    MatchNotificationConfig? initial,
  }) =>
      showModalBottomSheet<MatchNotificationConfig>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        builder: (_) => MatchNotificationDialog(initial: initial),
      );

  @override
  State<MatchNotificationDialog> createState() =>
      _MatchNotificationDialogState();
}

class _MatchNotificationDialogState extends State<MatchNotificationDialog> {
  late int _hour;
  late int _minute;
  late bool _matchStart;
  late bool _endFirstHalf;
  late bool _startSecondHalf;
  late bool _endMatch;

  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    final config = widget.initial ?? const MatchNotificationConfig();
    _hour = config.beforeMatchMinutes ~/ 60;
    _minute = config.beforeMatchMinutes % 60;
    _matchStart = config.notifyMatchStart;
    _endFirstHalf = config.notifyEndFirstHalf;
    _startSecondHalf = config.notifyStartSecondHalf;
    _endMatch = config.notifyEndMatch;
    _hourController = FixedExtentScrollController(initialItem: _hour);
    _minuteController = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppDimens.sdp(16)),
      decoration: BoxDecoration(
        color: AppColors.itemBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.text400, width: AppDimens.sdp(1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                s.notifications,
                style: AppTextStyles.bold(
                  size: AppDimens.ssp(16),
                  color: AppColors.text500,
                ),
              ),
            ),
            SizedBox(height: AppDimens.sdp(16)),
            Text(
              s.matchAlarmBeforeMatch,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(12),
                color: AppColors.text500,
              ),
            ),
            const SizedBox(height: 12),
            // `llTimePicker`: nền `bg_draw_team`, cao 120dp, 2 NumberPicker.
            Container(
              height: 120,
              decoration: _drawTeamBox,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NumberPicker(
                    controller: _hourController,
                    max: 23,
                    onChanged: (v) => setState(() => _hour = v),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (_) => Expanded(
                        child: Center(
                          child: Text(
                            ':',
                            style: AppTextStyles.regular(
                              size: AppDimens.ssp(14),
                              color: AppColors.text500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _NumberPicker(
                    controller: _minuteController,
                    max: 59,
                    onChanged: (v) => setState(() => _minute = v),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimens.sdp(16)),
            Text(
              s.notifications,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(12),
                color: AppColors.text500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: _drawTeamBox,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NotiCheckbox(
                    label: s.matchStart,
                    value: _matchStart,
                    onChanged: (v) => setState(() => _matchStart = v),
                  ),
                  const SizedBox(height: 10),
                  _NotiCheckbox(
                    label: s.endOfFirstHalf,
                    value: _endFirstHalf,
                    onChanged: (v) => setState(() => _endFirstHalf = v),
                  ),
                  const SizedBox(height: 10),
                  _NotiCheckbox(
                    label: s.startOfSecondHalf,
                    value: _startSecondHalf,
                    onChanged: (v) => setState(() => _startSecondHalf = v),
                  ),
                  const SizedBox(height: 10),
                  _NotiCheckbox(
                    label: s.fullTime,
                    value: _endMatch,
                    onChanged: (v) => setState(() => _endMatch = v),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppDimens.sdp(16)),
            // `btnDone`: nền `bg_tv_details`, cao 46sdp, chữ 14ssp bold.
            GestureDetector(
              onTap: () => Navigator.of(context).pop(
                MatchNotificationConfig(
                  beforeMatchMinutes: _hour * 60 + _minute,
                  notifyMatchStart: _matchStart,
                  notifyEndFirstHalf: _endFirstHalf,
                  notifyStartSecondHalf: _startSecondHalf,
                  notifyEndMatch: _endMatch,
                ),
              ),
              child: Container(
                height: AppDimens.sdp(46),
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.brandAccent,
                  borderRadius: BorderRadius.circular(AppDimens.sdp(20)),
                ),
                child: Text(
                  s.done,
                  style: AppTextStyles.bold(
                    size: AppDimens.ssp(14),
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `bg_draw_team.xml`: bo 12sdp, nền #25000000, viền 1sdp #4b4f58.
final BoxDecoration _drawTeamBox = BoxDecoration(
  color: const Color(0x25000000),
  borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
  border: Border.all(color: AppColors.text400, width: AppDimens.sdp(1)),
);

/// Thay `com.shawnlin.numberpicker.NumberPicker`: 3 dòng nhìn thấy,
/// dòng đang chọn màu trắng, các dòng khác #666666.
class _NumberPicker extends StatefulWidget {
  const _NumberPicker({
    required this.controller,
    required this.max,
    required this.onChanged,
  });

  final FixedExtentScrollController controller;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_NumberPicker> createState() => _NumberPickerState();
}

class _NumberPickerState extends State<_NumberPicker> {
  late int _selected = widget.controller.initialItem;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 56,
        height: 120,
        child: ListWheelScrollView.useDelegate(
          controller: widget.controller,
          itemExtent: 40,
          diameterRatio: 100,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() => _selected = index);
            widget.onChanged(index);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.max + 1,
            builder: (context, index) => Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: AppTextStyles.regular(
                  size: AppDimens.ssp(14),
                  color: index == _selected
                      ? AppColors.white
                      : const Color(0xFF666666),
                ),
              ),
            ),
          ),
        ),
      );
}

/// Port `selector_noti_checkbox`: `ic_check_circle_green` khi chọn,
/// `ic_uncheck_noti` khi bỏ chọn, cách chữ 10sdp.
class _NotiCheckbox extends StatelessWidget {
  const _NotiCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onChanged(!value),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.only(left: AppDimens.sdp(4)),
          child: Row(
            children: [
              SvgPicture.asset(
                value
                    ? 'assets/icons/ic_check_circle_green.svg'
                    : 'assets/icons/ic_uncheck_noti.svg',
                width: AppDimens.sdp(18),
                height: AppDimens.sdp(18),
              ),
              SizedBox(width: AppDimens.sdp(10)),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(12),
                    color: AppColors.text500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Port `dialog_turn_off_notification.xml` + `TurnOffNotificationDialog.kt`:
/// hộp `bg_league_grid_item` giữa màn, hai nút Cancel (nền trắng) và OK
/// (nền accent) chia đôi, cách nhau 14sdp.
class TurnOffNotificationDialog extends StatelessWidget {
  const TurnOffNotificationDialog({super.key});

  static Future<bool> show(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => const TurnOffNotificationDialog(),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(AppDimens.sdp(22)),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppDimens.sdp(16),
          horizontal: AppDimens.sdp(12),
        ),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              s.turnOffNotifications,
              textAlign: TextAlign.center,
              style: AppTextStyles.bold(
                size: AppDimens.ssp(14),
                color: AppColors.text500,
              ),
            ),
            SizedBox(height: AppDimens.sdp(8)),
            Text(
              s.youWonTReceiveAnyAlertsOrUpdatesUntilYouTurnThemBackOn,
              textAlign: TextAlign.center,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(12),
                color: AppColors.text100,
              ),
            ),
            SizedBox(height: AppDimens.sdp(22)),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: s.cancel,
                    background: AppColors.white,
                    foreground: AppColors.bgApp,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                SizedBox(width: AppDimens.sdp(14)),
                Expanded(
                  child: _DialogButton(
                    label: s.ok,
                    background: AppColors.brandAccent,
                    foreground: AppColors.white,
                    radius: 20,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.radius = 50,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final double radius;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(10)),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppDimens.sdp(radius)),
          ),
          child: Text(
            label,
            style: AppTextStyles.bold(
              size: AppDimens.ssp(14),
              color: foreground,
            ),
          ),
        ),
      );
}
