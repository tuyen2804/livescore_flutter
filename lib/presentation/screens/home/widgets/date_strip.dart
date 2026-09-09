import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_time_utils.dart';

/// Port `layout_date_strip_item.xml` + `HomeDateAdapter`:
/// mỗi ô rộng đúng 1/5 bề ngang màn hình, gồm thứ — gạch chân — ngày.
class DateStrip extends StatelessWidget {
  const DateStrip({
    super.key,
    required this.dates,
    required this.selected,
    required this.onSelect,
    required this.onPickDate,
  });

  final List<DateTime> dates;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final locale = Localizations.localeOf(context).toString();
    // `date_format_day` = EEE, `date_format_value` = "MMM d" (en) / "d 'thg' M" (vi).
    final dayFormat = DateFormat(s.dateFormatDay, locale);
    final valueFormat = DateFormat(s.dateFormatValue, locale);
    final itemWidth = MediaQuery.sizeOf(context).width / 5;

    return Row(
      children: [
        SizedBox(width: AppDimens.sdp(16)),
        GestureDetector(
          onTap: onPickDate,
          child: SizedBox(
            width: AppDimens.sdp(24),
            height: AppDimens.sdp(24),
            child: Padding(
              padding: EdgeInsets.all(AppDimens.sdp(3)),
              child: SvgPicture.asset(
                'assets/icons/ic_calender.svg',
                colorFilter: const ColorFilter.mode(
                  AppColors.brandAccent,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: AppDimens.sdp(8)),
        Expanded(
          child: SizedBox(
            height: AppDimens.sdp(56),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                return _DateCell(
                  width: itemWidth,
                  dayLabel: DateTimeUtils.isToday(date)
                      ? s.today
                      : dayFormat.format(date),
                  dateLabel: valueFormat.format(date),
                  selected: DateTimeUtils.isSameDay(date, selected),
                  onTap: () => onSelect(date),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.width,
    required this.dayLabel,
    required this.dateLabel,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final String dayLabel;
  final String dateLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Bản gốc: chọn = chữ trắng in đậm + gạch chân hiện; không chọn = text100,
    // gạch chân `invisible` (vẫn chiếm chỗ nên chiều cao không đổi).
    final color = selected ? AppColors.text500 : AppColors.text100;
    final weight = selected ? FontWeight.w700 : FontWeight.w500;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(8)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                dayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.medium(size: AppDimens.ssp(10), color: color)
                    .copyWith(fontWeight: weight),
              ),
              SizedBox(height: AppDimens.sdp(4)),
              Opacity(
                opacity: selected ? 1 : 0,
                child: Container(
                  width: AppDimens.sdp(24),
                  height: 2,
                  color: AppColors.brandAccent,
                ),
              ),
              SizedBox(height: AppDimens.sdp(4)),
              Text(
                dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.medium(size: AppDimens.ssp(11), color: color)
                    .copyWith(fontWeight: weight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
