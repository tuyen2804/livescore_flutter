import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/ads/ads_constants.dart';
import '../../../core/ads/ads_gate.dart';
import '../../../core/ads/interstitial_ad_manager.dart';
import '../../../core/billing/premium_manager.dart';
import '../../../core/ads/native/native_placements.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/app_router.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/native/native_ad_view.dart';

/// Port `presentation/premium/PremiumFragment.kt` + `fragment_premium.xml`.
///
/// Nền gradient `background_gradient_premium` (#FFA600 → #0E0E10, góc 90°),
/// nút đóng 40sdp góc trái, ảnh `ic_pre` 220x200sdp, tiêu đề 19ssp accent,
/// ba dòng tính năng có dấu tick 13sdp, nút mua 45sdp nền `#FABA2A`.
/// Native `LiveScore_native_noads` dưới cùng đã bỏ theo yêu cầu.
///
/// **Thêm so với bản gốc:** nút *Restore Purchases*. Gói ở đây là
/// non-consumable nên cài lại máy vẫn khôi phục được — App Store bắt buộc
/// phải có lối này.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.fromOnboarding = false});

  final bool fromOnboarding;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late final PremiumManager _premium = sl<PremiumManager>();
  StreamSubscription<bool>? _restoreSub;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _premium.isPremiumNotifier.addListener(_onPremiumChanged);
    _restoreSub = _premium.restoreResult.listen(_onRestoreResult);
    // `onResume { PremiumManager.refresh() }` — hỏi lại giá và giao dịch cũ.
    unawaited(_premium.restore(silent: true));
  }

  @override
  void dispose() {
    _premium.isPremiumNotifier.removeListener(_onPremiumChanged);
    _restoreSub?.cancel();
    super.dispose();
  }

  void _onPremiumChanged() {
    if (!_premium.isPremium || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).premiumThanks)),
    );
    _leave();
  }

  void _onRestoreResult(bool restored) {
    if (!mounted) return;
    final s = S.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored ? s.restorePurchasesSuccess : s.restorePurchasesEmpty,
        ),
      ),
    );
  }

  Future<void> _buy() async {
    final ok = await _premium.buy();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).premiumNotReady)),
      );
    }
  }

  /// Port `close()`: đóng màn thì bắn inter `LiveScore_inter_Noads` rồi mới đi.
  void _close() {
    if (AdsGate.isBlocked || !sl<RemoteConfigService>().interNoAdsEnabled) {
      _leave();
      return;
    }
    unawaited(
      InterstitialAdManager.showIfReady(
        InterPlacement.noAds,
        onDismiss: _leave,
      ),
    );
  }

  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    final navigator = Navigator.of(context);
    if (widget.fromOnboarding) {
      navigator.pushNamedAndRemoveUntil(AppRoutes.main, (route) => false);
    } else {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // Bản gốc: nút Back tương đương nút đóng, cũng bắn inter.
        if (!didPop) _close();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF0E0E10), Color(0xFFFFA600)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: AppDimens.sdp(14),
                      top: AppDimens.sdp(18),
                    ),
                    child: GestureDetector(
                      onTap: _close,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.all(AppDimens.sdp(8)),
                        child: SvgPicture.asset(
                          'assets/icons/ic_close.svg',
                          width: AppDimens.sdp(24),
                          height: AppDimens.sdp(24),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: AppDimens.sdp(20)),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/ic_pre.webp',
                          width: AppDimens.sdp(220),
                          height: AppDimens.sdp(200),
                          errorBuilder: (context, error, stack) => SizedBox(
                            width: AppDimens.sdp(220),
                            height: AppDimens.sdp(200),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            s.premiumAdFreeUpgrade,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bold(
                              size: AppDimens.ssp(19),
                              color: AppColors.brandAccent,
                            ),
                          ),
                        ),
                        SizedBox(height: AppDimens.sdp(20)),
                        // Dòng đầu bản gốc ghi thẳng chuỗi trong XML, không
                        // qua strings.xml nên giữ nguyên tiếng Anh.
                        const _FeatureRow(label: 'Remove bottom banner'),
                        SizedBox(height: AppDimens.sdp(12)),
                        _FeatureRow(
                            label: s.eliminateFullScreenInterstitialAds),
                        SizedBox(height: AppDimens.sdp(12)),
                        _FeatureRow(
                            label: s.unlocksAllFutureAdFreeFeatures),
                        SizedBox(height: AppDimens.sdp(20)),
                      ],
                    ),
                  ),
                ),
                _BuyButton(premium: _premium, onTap: _buy),
                // `LiveScore_native_noads` — bản gốc đặt dưới cùng màn này.
                NativeAdView(
                  placement: NativePlacements.noAds,
                  margin: EdgeInsets.only(top: AppDimens.sdp(8)),
                ),
                // Nút khôi phục — bắt buộc với gói non-consumable trên iOS.
                Padding(
                  padding: EdgeInsets.only(
                    top: AppDimens.sdp(8),
                    bottom: AppDimens.sdp(12),
                  ),
                  child: GestureDetector(
                    onTap: () => _premium.restore(),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: AppDimens.sdp(4)),
                      child: Text(
                        s.restorePurchases,
                        style: AppTextStyles.medium(
                          size: AppDimens.ssp(13),
                          color: AppColors.text100,
                        ).copyWith(decoration: TextDecoration.underline),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `PremiumFeatureRow` + `PremiumFeatureText`: tick 13sdp, chữ 13ssp `text500`,
/// cách nhau 10sdp.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/ic_v.svg',
            width: AppDimens.sdp(13),
            height: AppDimens.sdp(13),
          ),
          SizedBox(width: AppDimens.sdp(10)),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.regular(
                size: AppDimens.ssp(13),
                color: AppColors.text500,
              ),
            ),
          ),
        ],
      );
}

/// `btnBuy` + `progressPrice`: chưa có giá thì hiện vòng quay và khoá nút,
/// có giá thì chữ là `premium_buy` ghép giá.
class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.premium, required this.onTap});

  final PremiumManager premium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: premium.priceText,
      builder: (context, price, _) {
        final loading = price == null || price.isEmpty;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.sdp(20)),
          child: GestureDetector(
            onTap: loading ? null : onTap,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: AppDimens.sdp(45),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFABA2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: loading
                  ? SizedBox(
                      width: AppDimens.sdp(20),
                      height: AppDimens.sdp(20),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.text500,
                      ),
                    )
                  : Text(
                      s.premiumBuy(price).toUpperCase(),
                      style: AppTextStyles.bold(
                        size: AppDimens.ssp(16),
                        color: AppColors.black,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
