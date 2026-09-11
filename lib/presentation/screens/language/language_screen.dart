import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/ads/native/native_ad_manager.dart';
import '../../../core/ads/native/native_placements.dart';
import '../../../core/di/injection.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../../domain/entities/language_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/native/native_ad_view.dart';

/// Port `presentation/language/LanguageFragment.kt` (bỏ native ads).
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, this.fromSettings = false});

  final bool fromSettings;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  @override
  void initState() {
    super.initState();
    // Nạp trước cho hai màn kế tiếp: Loading rồi Onboarding trang 1.
    unawaited(sl<NativeAdManager>().preloadAll([
      NativePlacements.loading,
      NativePlacements.onboarding1,
    ]));
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => LanguageProvider(sl()),
        child: _LanguageView(fromSettings: widget.fromSettings),
      );
}

class _LanguageView extends StatefulWidget {
  const _LanguageView({required this.fromSettings});

  final bool fromSettings;

  @override
  State<_LanguageView> createState() => _LanguageViewState();
}

class _LanguageViewState extends State<_LanguageView> {
  /// Port `LanguageFragment`: vào từ onboarding thì hiện `LGF_1`; **chạm chọn
  /// một ngôn ngữ** thì đổi sang `LGF_2` (`observeLanguageAdSlot2`); còn vào
  /// từ Settings thì `LGF_2` ngay từ đầu (`observeLanguageSetting`).
  bool _useSlot2 = false;

  bool get _fromSettings => widget.fromSettings;

  String get _placement => (_fromSettings || _useSlot2)
      ? NativePlacements.language2
      : NativePlacements.language1;

  Future<void> _confirm(BuildContext context) async {
    final provider = context.read<LanguageProvider>();
    final app = context.read<AppProvider>();
    final navigator = Navigator.of(context);

    final code = await provider.saveSelectedLanguage();
    if (code != null) {
      await app.setLocale(_toLocale(code));
    }
    if (_fromSettings) {
      navigator.pop(true);
    } else {
      navigator.pushReplacementNamed(AppRoutes.loading);
    }
  }

  /// Mã 'in' (Indonesia) của Android tương ứng 'id' chuẩn ISO.
  static Locale _toLocale(String code) =>
      Locale(code == 'in' ? 'id' : code);

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            // Hàng tiêu đề: nút back chỉ hiện khi vào từ Settings
            // (`btnBack` mặc định gone), tiêu đề 17ssp bold, `ic_next_lang`.
            Padding(
              padding: EdgeInsets.only(top: AppDimens.sdp(20)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_fromSettings)
                    Padding(
                      padding: EdgeInsets.only(left: AppDimens.sdp(12)),
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: SvgPicture.asset(
                          'assets/icons/ic_back.svg',
                          width: AppDimens.sdp(30),
                          height: AppDimens.sdp(30),
                          colorFilter: const ColorFilter.mode(
                            AppColors.text500,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(width: AppDimens.sdp(31)),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(top: AppDimens.sdp(10)),
                      child: Text(
                        s.languages,
                        style: AppTextStyles.bold(
                          size: AppDimens.ssp(17),
                          color: AppColors.text500,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: AppDimens.sdp(8),
                      right: AppDimens.sdp(31),
                    ),
                    child: GestureDetector(
                      onTap: provider.selected == null
                          ? null
                          : () => _confirm(context),
                      child: Opacity(
                        opacity: provider.selected == null ? 0.4 : 1,
                        child: SvgPicture.asset(
                          'assets/icons/ic_next_lang.svg',
                          width: AppDimens.sdp(31),
                          height: AppDimens.sdp(31),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(AppDimens.sdp(12)),
                itemCount: provider.languages.length,
                itemBuilder: (context, index) {
                  final item = provider.languages[index];
                  return _LanguageTile(
                    item: item,
                    onTap: () {
                      provider.selectLanguage(item);
                      if (!_fromSettings && !_useSlot2) {
                        setState(() => _useSlot2 = true);
                      }
                    },
                  );
                },
              ),
            ),
            // `layoutAds` nằm trong `layoutBotttom` ghim đáy parent, **không
            // lề** — xem `fragment_language.xml`.
            NativeAdView(placement: _placement),
          ],
        ),
      ),
    );
  }
}

/// Port `item_language.xml` + `LanguageAdapter.bind`: nền `bg_unselect_lang`
/// (bo 50sdp, `color_item_bg`) hoặc `bg_select_lang` (thêm viền 1.5dp cam),
/// cờ 28sdp, tên 12ssp medium, `ic_select_cb`/`ic_unselect` 16sdp.
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.item, required this.onTap});

  final LanguageModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = item.isSelected;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(top: AppDimens.sdp(6)),
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.sdp(12),
          vertical: AppDimens.sdp(11),
        ),
        decoration: BoxDecoration(
          color: AppColors.itemBg,
          borderRadius: BorderRadius.circular(AppDimens.sdp(50)),
          border: selected
              ? Border.all(color: AppColors.brandAccent, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            AppImage(
              source: item.flagAsset,
              width: AppDimens.sdp(28),
              height: AppDimens.sdp(28),
            ),
            SizedBox(width: AppDimens.sdp(12)),
            Expanded(
              child: Text(
                item.name,
                style: AppTextStyles.medium(
                  size: AppDimens.ssp(12),
                  color: AppColors.text500,
                ),
              ),
            ),
            SvgPicture.asset(
              selected
                  ? 'assets/icons/ic_select_cb.svg'
                  : 'assets/icons/ic_unselect.svg',
              width: AppDimens.sdp(16),
              height: AppDimens.sdp(16),
            ),
          ],
        ),
      ),
    );
  }
}
