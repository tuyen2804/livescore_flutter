import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../data/datasources/local/app_prefs.dart';

/// Cổng duy nhất cho in-app purchase gói No-ads.
///
/// **Khác bản mẫu một cách có chủ đích.** `PremiumManager.kt` khai gói là
/// CONSUMABLE, mua xong `consume` ngay nên Google không còn lưu gì; nguồn sự
/// thật là cache local, và xoá app là mất quyền, phải mua lại — bản gốc cũng
/// ghi rõ "dung y do, nen khong co nut Restore".
///
/// Bản này làm ngược lại vì App Store bắt buộc phải có Restore Purchases:
/// - gói là **non-consumable**, mua xong chỉ `completePurchase` chứ không tiêu
///   thụ, nên cửa hàng giữ lại quyền sở hữu vĩnh viễn;
/// - mỗi lần mở app đều gọi [restore] để đồng bộ lại từ cửa hàng, cài lại máy
///   hay đổi máy vẫn nhận đúng quyền đã mua;
/// - có [restore] công khai cho nút "Restore Purchases".
///
/// Cache trong [AppPrefs] chỉ còn là bộ đệm để chặn quảng cáo ngay lúc khởi
/// động, không phải nguồn sự thật.
class PremiumManager {
  PremiumManager(this._prefs);

  static const String _tag = 'PremiumManager';

  /// Product id trên Google Play Console / App Store Connect.
  /// Loại: In-app product, one-time (non-consumable).
  static const String productIdNoAds = 'com.score2new.noads';

  /// Cờ bật/tắt toàn bộ tính năng Premium — port `FEATURE_ENABLED`.
  /// false = ẩn mọi lối vào màn No-ads và không khởi tạo billing.
  static const bool featureEnabled = true;

  static const String keyIsPremium = 'is_premium';

  final AppPrefs _prefs;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _productDetails;

  final ValueNotifier<bool> isPremiumNotifier = ValueNotifier<bool>(false);

  /// Giá đã format theo tiền tệ của user; null = chưa lấy được từ cửa hàng.
  final ValueNotifier<String?> priceText = ValueNotifier<String?>(null);

  /// true trong lúc đang chờ cửa hàng trả lời (mua hoặc khôi phục).
  final ValueNotifier<bool> isBusy = ValueNotifier<bool>(false);

  /// Bắn ra khi khôi phục xong: true = tìm thấy giao dịch, false = không có gì.
  final StreamController<bool> _restoreResult =
      StreamController<bool>.broadcast();
  Stream<bool> get restoreResult => _restoreResult.stream;

  /// Lý do giá chưa hiện — port `priceFailureReason`, lọc log bằng
  /// `flutter logs | grep PremiumManager`.
  String? priceFailureReason = 'Chưa chạy bước nào: init() chưa được gọi';

  bool get isPremium => isPremiumNotifier.value;

  void _failPrice(String reason) {
    priceFailureReason = reason;
    priceText.value = null;
    dev.log('GIÁ CHƯA HIỆN — $reason', name: _tag);
  }

  /// Gọi một lần lúc khởi động app.
  Future<void> init() async {
    // Đọc cache trước để chặn quảng cáo ngay, đồng bộ với cửa hàng sau.
    _applyPremium(_prefs.getBool(keyIsPremium));

    if (!featureEnabled) {
      dev.log('init(): featureEnabled=false → bỏ qua billing', name: _tag);
      return;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      _failPrice('cửa hàng in-app purchase không khả dụng trên máy này');
      return;
    }

    _subscription ??= _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (Object e) => dev.log('purchaseStream lỗi: $e', name: _tag),
    );

    await _queryProductDetails();

    // Non-consumable: hỏi lại cửa hàng để cài lại app vẫn giữ quyền.
    await restore(silent: true);
  }

  Future<void> _queryProductDetails() async {
    final response = await _iap.queryProductDetails({productIdNoAds});

    if (response.error != null) {
      _failPrice('queryProductDetails lỗi: ${response.error!.message}');
      return;
    }
    if (response.notFoundIDs.contains(productIdNoAds)) {
      _productDetails = null;
      _failPrice(
        'cửa hàng không tìm thấy product "$productIdNoAds". Nguyên nhân thường '
        'gặp: (a) product chưa tạo hoặc chưa Active; (b) chưa có bản nào của '
        'bundle id này lên store, kể cả track nội bộ; (c) đang chạy bản không '
        'đúng chữ ký đã upload; (d) tài khoản trên máy không nằm trong danh '
        'sách tester.',
      );
      return;
    }

    final details = response.productDetails
        .where((p) => p.id == productIdNoAds)
        .firstOrNull;
    if (details == null) {
      _productDetails = null;
      _failPrice('cửa hàng trả về danh sách product rỗng');
      return;
    }

    _productDetails = details;
    priceFailureReason = null;
    priceText.value = details.price;
    dev.log('Giá gói = ${details.price}', name: _tag);
  }

  /// Mở màn thanh toán. false = chưa sẵn sàng (mất mạng / chưa có giá).
  Future<bool> buy() async {
    if (!featureEnabled) return false;
    final details = _productDetails;
    if (details == null) {
      dev.log(
        'buy(): chưa sẵn sàng — lý do giá chưa hiện: $priceFailureReason',
        name: _tag,
      );
      await _queryProductDetails();
      return false;
    }

    isBusy.value = true;
    try {
      // buyNonConsumable: cửa hàng giữ quyền sở hữu, khôi phục được về sau.
      return await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
    } catch (e) {
      dev.log('buy() lỗi: $e', name: _tag);
      isBusy.value = false;
      return false;
    }
  }

  /// Nút "Restore Purchases" — App Store bắt buộc phải có với non-consumable.
  /// [silent] = gọi ngầm lúc khởi động, không bắn kết quả ra UI.
  Future<void> restore({bool silent = false}) async {
    if (!featureEnabled) return;
    if (!silent) isBusy.value = true;
    _restorePending = !silent;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      dev.log('restore() lỗi: $e', name: _tag);
      if (!silent) {
        isBusy.value = false;
        _restorePending = false;
        _restoreResult.add(false);
      }
    }
  }

  bool _restorePending = false;

  void _onPurchaseUpdated(List<PurchaseDetails> purchases) {
    var restored = false;

    for (final purchase in purchases) {
      if (purchase.productID != productIdNoAds) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          // Giao dịch chờ duyệt (thẻ chờ, phụ huynh duyệt...). Chưa cấp quyền.
          dev.log('Giao dịch đang chờ xử lý', name: _tag);
          continue;

        case PurchaseStatus.error:
          dev.log('Mua thất bại: ${purchase.error?.message}', name: _tag);
          isBusy.value = false;
          break;

        case PurchaseStatus.canceled:
          dev.log('User huỷ mua', name: _tag);
          isBusy.value = false;
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _applyPremium(true);
          restored = true;
          isBusy.value = false;
          dev.log(
            purchase.status == PurchaseStatus.restored
                ? 'Khôi phục được quyền No-ads'
                : 'Mua thành công gói No-ads',
            name: _tag,
          );
          break;
      }

      // Bắt buộc với mọi trạng thái kết thúc, nếu không cửa hàng sẽ phát lại.
      // Non-consumable nên KHÔNG gọi consume — quyền phải nằm lại ở cửa hàng.
      if (purchase.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(purchase));
      }
    }

    if (_restorePending) {
      _restorePending = false;
      isBusy.value = false;
      _restoreResult.add(restored);
    }
  }

  void _applyPremium(bool value) {
    isPremiumNotifier.value = value;
    unawaited(_prefs.setBool(keyIsPremium, value));
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    unawaited(_restoreResult.close());
  }
}
