import 'package:flutter/material.dart';

import '../../core/ads/ads_constants.dart';
import '../../core/ads/reward_ad_manager.dart';
import 'reward_dialogs.dart';

/// Gom đúng chuỗi dialog mà `PredictionFragment` và `MatchInfoFragment` cùng
/// dùng, để hai nơi không lệch nhau:
///
/// `RewardDialog` → (Watch now) → `RewardLoadingDialog` +
/// `RewardAdManager.loadAndShow` → `onUserEarned` **hoặc** `onDismiss` đều
/// mở khoá (bản gốc gọi `completePrediction("reward_earned")` và
/// `completePrediction("reward_dismiss")`), còn `onUnavailable` thì hiện
/// `RewardNotAvailableDialog` với nút Retry quay lại bước nạp.
class RewardFlow {
  const RewardFlow._();

  /// [onGranted] chỉ được gọi đúng một lần cho cả chuỗi.
  static void start(
    BuildContext context, {
    required VoidCallback onGranted,
  }) {
    var granted = false;
    void grantOnce() {
      if (granted) return;
      granted = true;
      onGranted();
    }

    void load() {
      final dismissLoading = RewardLoadingDialog.show(context);
      RewardAdManager.loadAndShow(
        RewardPlacement.inApp,
        onUserEarned: () {
          dismissLoading();
          grantOnce();
        },
        onDismiss: () {
          dismissLoading();
          grantOnce();
        },
        onUnavailable: () {
          dismissLoading();
          if (!context.mounted) return;
          RewardNotAvailableDialog.show(context, onRetry: load);
        },
      );
    }

    RewardDialog.show(context, onWatchNow: load);
  }
}
