import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/billing/premium_manager.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/language_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/settings_toolbar.dart';

/// Port `presentation/settings/SettingsFragment.kt` + `fragment_settings.xml`:
/// toolbar 74sdp rồi **một** thẻ `color_item_bg` bo 12sdp chứa 4 hàng
/// Language / Rate / Share / Privacy Policy. Banner Premium đã bỏ theo yêu cầu.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _policyUrl = 'https://policy.indie-dev.store/';
  static const String _storeUrl =
      'https://play.google.com/store/apps/details?id=com.ind.score2new.stream';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = context.watch<AppProvider>();

    final current = LanguageModel.all
        .where((l) => l.code == (app.locale?.languageCode ?? 'en'))
        .toList(growable: false);
    final currentName = current.isEmpty ? 'English' : current.first.name;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: Column(
        children: [
          SettingsToolbar(title: s.settings),
          // `btnPremium` — banner gradient #A855F7 → #1D4ED8, bo 12sdp,
          // chỉ hiện khi bật tính năng và chưa mua gói.
          if (PremiumManager.featureEnabled)
            ValueListenableBuilder<bool>(
              valueListenable: sl<PremiumManager>().isPremiumNotifier,
              builder: (context, premium, _) =>
                  premium ? const SizedBox.shrink() : const _PremiumBanner(),
            ),
          Padding(
            padding: EdgeInsets.only(
              left: AppDimens.sdp(16),
              right: AppDimens.sdp(16),
              top: AppDimens.sdp(16),
            ),
            child: Container(
              padding: EdgeInsets.all(AppDimens.sdp(12)),
              decoration: BoxDecoration(
                color: AppColors.itemBg,
                borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
              ),
              child: Column(
                children: [
                  _Row(
                    asset: 'assets/icons/ic_st_lang.svg',
                    label: s.language,
                    trailingText: currentName,
                    onTap: () => Navigator.of(context).pushNamed(
                      AppRoutes.language,
                      arguments: {'fromSettings': true},
                    ),
                  ),
                  _Row(
                    asset: 'assets/icons/ic_star.svg',
                    label: s.rate,
                    onTap: () => _open(_storeUrl),
                  ),
                  _Row(
                    asset: 'assets/icons/ic_share.svg',
                    label: s.share,
                    onTap: () => Share.share(
                      s.shareAppText('com.ind.score2new.stream'),
                    ),
                  ),
                  _Row(
                    asset: 'assets/icons/ic_privacy.svg',
                    label: s.privacyPolicy,
                    onTap: () => _open(_policyUrl),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Một hàng cài đặt: icon 20sdp, nhãn 12ssp `text500` cách 12sdp,
/// paddingV 12sdp; riêng hàng ngôn ngữ có tên hiện tại 11ssp `text200`
/// và mũi tên `ic_chevron_right` 16sdp.
class _Row extends StatelessWidget {
  const _Row({
    required this.asset,
    required this.label,
    required this.onTap,
    this.trailingText,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppDimens.sdp(12)),
          child: Row(
            children: [
              SvgPicture.asset(
                asset,
                width: AppDimens.sdp(20),
                height: AppDimens.sdp(20),
              ),
              SizedBox(width: AppDimens.sdp(12)),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.medium(
                    size: AppDimens.ssp(12),
                    color: AppColors.text500,
                  ),
                ),
              ),
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: AppTextStyles.regular(
                    size: AppDimens.ssp(11),
                    color: AppColors.text200,
                  ),
                ),
                SizedBox(width: AppDimens.sdp(4)),
                SvgPicture.asset(
                  'assets/icons/ic_chevron_right.svg',
                  width: AppDimens.sdp(16),
                  height: AppDimens.sdp(16),
                ),
              ],
            ],
          ),
        ),
      );
}


/// Port `btnPremium` trong `fragment_settings.xml`: nền `bg_premium_banner`
/// (gradient ngang #A855F7 → #1D4ED8, bo 12sdp), lề ngang 16sdp, padding
/// 14sdp, icon 30sdp, tiêu đề 16ssp bold `text500`, mô tả 11ssp `text100`.
class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.sdp(16),
        right: AppDimens.sdp(16),
        top: AppDimens.sdp(16),
      ),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(AppRoutes.premium),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.all(AppDimens.sdp(14)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFA855F7), Color(0xFF1D4ED8)],
            ),
            borderRadius: BorderRadius.circular(AppDimens.sdp(12)),
          ),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ic_premium_no_ads.svg',
                width: AppDimens.sdp(30),
                height: AppDimens.sdp(30),
              ),
              SizedBox(width: AppDimens.sdp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.premiumBannerTitle,
                      style: AppTextStyles.bold(
                        size: AppDimens.ssp(16),
                        color: AppColors.text500,
                      ),
                    ),
                    SizedBox(height: AppDimens.sdp(2)),
                    Text(
                      s.premiumBannerDesc,
                      style: AppTextStyles.regular(
                        size: AppDimens.ssp(11),
                        color: AppColors.text100,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
