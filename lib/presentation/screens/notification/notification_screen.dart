import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/sport_presentation.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/earth_loading_view.dart';
import '../../../data/models/local/db_entities.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/notification_dialogs.dart';
import '../../widgets/sport_icon.dart';

/// Port `presentation/notification/NotificationFragment.kt` +
/// `fragment_notification.xml`: toolbar 74sdp → hàng chip chọn môn →
/// danh sách gom theo giải (`item_league_section` + `item_notification`).
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<NotificationProvider>().loadNotifications(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<NotificationProvider>();

    // `SPORT_STRING_RES` + mục "all" ở cuối.
    final sports = [...SportPresentation.sportPickerOrder, 'all'];

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Column(
        children: [
          _Toolbar(title: s.notifications),
          if (provider.isLoading)
            const Expanded(child: EarthLoadingOverlay(label: 'Loading'))
          else ...[
            SizedBox(
              height: AppDimens.sdp(36),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: sports.length,
                itemBuilder: (context, index) {
                  final slug = sports[index];
                  return _SportChip(
                    slug: slug,
                    label: slug == 'all'
                        ? s.sportPickerAll
                        : SportPresentation.label(slug),
                    selected: provider.sportSlug == slug,
                    onTap: () => provider.filterBySport(slug),
                  );
                },
              ),
            ),
            Expanded(
              child: provider.isEmpty
                  // Hai dòng này bản gốc ghi thẳng trong XML, không qua strings.
                  ? const _NoNotification(
                      title: 'Your field is empty',
                      message: "Looks like you haven't added anything yet",
                    )
                  : ListView(
                      padding: EdgeInsets.only(
                        top: AppDimens.sdp(6),
                        bottom: AppDimens.sdp(16),
                      ),
                      children: [
                        for (final group in provider.groups)
                          _LeagueSection(
                            group: group,
                            onToggle: (item) => _confirmOff(provider, item),
                          ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  /// Chuông ở đây luôn ở trạng thái bật nên chỉ có luồng hỏi tắt.
  Future<void> _confirmOff(
    NotificationProvider provider,
    NotificationDbItem item,
  ) async {
    final confirmed = await TurnOffNotificationDialog.show(context);
    if (!confirmed) return;
    await provider.toggle(item);
  }
}

/// Toolbar 74sdp: back 30sdp (margin 14/25, padding 2), tiêu đề 18ssp bold
/// căn giữa với `marginEnd 40sdp` để bù chỗ nút back.
class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Container(
        height: AppDimens.sdp(74),
        width: double.infinity,
        color: AppColors.itemBg,
        padding: EdgeInsets.only(
          top: AppDimens.sdp(25),
          left: AppDimens.sdp(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
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
                padding: EdgeInsets.only(
                  top: AppDimens.sdp(3),
                  right: AppDimens.sdp(40),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bold(
                    size: AppDimens.ssp(18),
                    color: AppColors.text500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

/// Chip môn dựng bằng code trong `NotificationFragment`: padding 12/6,
/// icon 16dp cách chữ 6dp, chữ 13sp đậm. Chọn = `bg_sport_chip_selected`
/// (nền `#1A22C55E`, viền 1.5dp accent), chưa chọn = `bg_unselect_lang`.
class _SportChip extends StatelessWidget {
  const _SportChip({
    required this.slug,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String slug;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint =
        selected ? AppColors.brandAccent : const Color(0xFF94A3B8);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1A22C55E) : AppColors.itemBg,
          borderRadius: BorderRadius.circular(AppDimens.sdp(50)),
          border: selected
              ? Border.all(color: AppColors.brandAccent, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: slug == 'all'
                  ? SvgPicture.asset(
                      'assets/icons/ic_league.svg',
                      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
                    )
                  : SportIcon(slug: slug, color: tint),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bold(
                size: 13,
                color:
                    selected ? AppColors.white : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Port `item_league_section.xml`: logo 24sdp, tên giải 14ssp semi-bold,
/// paddingH 16sdp paddingTop 10sdp, danh sách trận cách 8sdp.
class _LeagueSection extends StatelessWidget {
  const _LeagueSection({required this.group, required this.onToggle});

  final NotificationGroup group;
  final void Function(NotificationDbItem item) onToggle;

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.black,
        padding: EdgeInsets.only(
          left: AppDimens.sdp(16),
          right: AppDimens.sdp(16),
          top: AppDimens.sdp(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppImage(
                  source: group.logoUrl,
                  width: AppDimens.sdp(24),
                  height: AppDimens.sdp(24),
                  placeholderAsset: 'assets/icons/ic_league.svg',
                ),
                SizedBox(width: AppDimens.sdp(12)),
                Expanded(
                  child: Text(
                    group.dateLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.semiBold(
                      size: AppDimens.ssp(14),
                      color: AppColors.text500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimens.sdp(8)),
            for (final item in group.items)
              _NotificationRow(item: item, onToggle: () => onToggle(item)),
          ],
        ),
      );
}

/// Port `item_notification.xml`: cột trạng thái/giờ/ngày, vạch dọc `#2A2D30`,
/// hai đội với logo 20sdp, chuông `ic_noti_select` 24sdp.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.item, required this.onToggle});

  final NotificationDbItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final status = item.status ?? 'NS';
    // Bản gốc: FT/đã kết thúc → accent, đang đá → đỏ, còn lại → trắng.
    final upper = status.toUpperCase();
    final color = upper == 'FT' || upper == 'ENDED'
        ? AppColors.brandAccent
        : (upper == 'LIVE' || upper == 'HT')
            ? Colors.red
            : AppColors.text500;

    return Container(
      margin: EdgeInsets.only(bottom: AppDimens.sdp(10)),
      padding: EdgeInsets.symmetric(
        horizontal: AppDimens.sdp(10),
        vertical: AppDimens.sdp(12),
      ),
      decoration: BoxDecoration(
        color: AppColors.itemBg,
        borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  status,
                  style: AppTextStyles.medium(
                    size: AppDimens.ssp(11),
                    color: color,
                  ),
                ),
                SizedBox(height: AppDimens.sdp(2)),
                Text(
                  DateTimeUtils.convertUtcToLocalTime(item.timeStr),
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(10),
                    color: color,
                  ),
                ),
                SizedBox(height: AppDimens.sdp(2)),
                Text(
                  DateTimeUtils.convertUtcToLocalDate(item.timeStr),
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(10),
                    color: color,
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              margin: EdgeInsets.only(left: AppDimens.sdp(8)),
              color: const Color(0xFF2A2D30),
            ),
            SizedBox(width: AppDimens.sdp(12)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TeamLine(name: item.homeName, logo: item.homeLogoUrl),
                  SizedBox(height: AppDimens.sdp(12)),
                  _TeamLine(name: item.awayName, logo: item.awayLogoUrl),
                ],
              ),
            ),
            GestureDetector(
              onTap: onToggle,
              child: SizedBox(
                width: AppDimens.sdp(24),
                height: AppDimens.sdp(24),
                child: Padding(
                  padding: EdgeInsets.all(AppDimens.sdp(4)),
                  child: SvgPicture.asset('assets/icons/ic_noti_select.svg'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  const _TeamLine({required this.name, required this.logo});

  final String name;
  final String? logo;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          AppImage(
            source: logo,
            width: AppDimens.sdp(20),
            height: AppDimens.sdp(20),
            placeholderAsset: 'assets/icons/ic_ball.svg',
          ),
          SizedBox(width: AppDimens.sdp(10)),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.semiBold(
                size: AppDimens.ssp(12),
                color: AppColors.text500,
              ),
            ),
          ),
        ],
      );
}

/// Port `llNoNotification`: `ic_empty` 120dp + hai dòng chữ 16sp / 14sp.
class _NoNotification extends StatelessWidget {
  const _NoNotification({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/ic_empty.svg',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.medium(size: 16, color: AppColors.text100),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.regular(size: 14, color: AppColors.text200),
            ),
          ],
        ),
      );
}
