import 'dart:async';
import 'dart:developer' as dev;

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Port `ads/ConsentManager.kt` (UMP / Google User Messaging Platform).
///
/// Giữ nguyên ba hằng số và toàn bộ nhánh xử lý của bản Kotlin:
/// - hard timeout 10 giây, chỉ chạy khi **không** vào nhánh retry;
/// - form load lỗi mã 2 (INTERNAL_ERROR) thì thử lại tối đa 2 lần, cách nhau 1s;
/// - mọi nhánh lỗi đều `finish(true)` để không chặn quảng cáo.
///
/// Phần `applyMolocoPrivacy()` bị bỏ vì bản Flutter không nhúng mediation
/// Moloco — không có SDK nào để đẩy cờ privacy sang.
class ConsentManager {
  const ConsentManager._();

  static const int _maxRetry = 2;
  static const Duration _retryDelay = Duration(seconds: 1);
  static const Duration _hardTimeout = Duration(seconds: 10);

  static const String _tag = 'Consent';

  static Future<void> requestConsent(void Function(bool) onResult) async {
    var finished = false;
    Timer? hardTimeoutTimer;

    void finish(bool result) {
      if (finished) return;
      finished = true;
      hardTimeoutTimer?.cancel();
      onResult(result);
    }

    hardTimeoutTimer = Timer(_hardTimeout, () {
      dev.log('HARD TIMEOUT → fallback allow ads', name: _tag);
      finish(true);
    });

    final params = ConsentRequestParameters(
      tagForUnderAgeOfConsent: false,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          final status = await ConsentInformation.instance.getConsentStatus();
          final formAvailable =
              await ConsentInformation.instance.isConsentFormAvailable();
          final canRequest =
              await ConsentInformation.instance.canRequestAds();
          dev.log('Consent status: $status', name: _tag);
          dev.log('Form available: $formAvailable', name: _tag);
          dev.log('Can request ads: $canRequest', name: _tag);

          if (formAvailable && status == ConsentStatus.required) {
            // Vào retry → huỷ hard timeout đúng như bản gốc.
            hardTimeoutTimer?.cancel();
            _loadAndShowFormWithRetry(retry: 0, onResult: finish);
          } else {
            finish(canRequest);
          }
        } catch (e) {
          dev.log('Consent info error: $e', name: _tag);
          finish(true);
        }
      },
      (error) {
        dev.log('Consent info error: ${error.message}', name: _tag);
        finish(true);
      },
    );
  }

  static void _loadAndShowFormWithRetry({
    required int retry,
    required void Function(bool) onResult,
  }) {
    ConsentForm.loadConsentForm(
      (form) {
        dev.log('Consent form loaded (retry=$retry)', name: _tag);
        form.show((_) async {
          onResult(await ConsentInformation.instance.canRequestAds());
        });
      },
      (error) {
        dev.log(
          'Load form failed (retry=$retry): code=${error.errorCode}',
          name: _tag,
        );
        if (error.errorCode == 2 && retry < _maxRetry) {
          Timer(_retryDelay, () {
            _loadAndShowFormWithRetry(retry: retry + 1, onResult: onResult);
          });
        } else {
          onResult(true);
        }
      },
    );
  }
}

/// Port `object ConsentState` — MainActivity chạy consent một lần, Splash
/// ngồi chờ kết quả qua flow này.
class ConsentState {
  const ConsentState._();

  static bool initialized = false;
  static bool? result;

  static final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  /// Phát lại giá trị đã có cho subscriber tới sau — `MutableStateFlow` của
  /// Kotlin có sẵn hành vi này, `Stream` của Dart thì không.
  static Stream<bool> get stream async* {
    final current = result;
    if (current != null) yield current;
    yield* _controller.stream;
  }

  static void setResult(bool value) {
    result = value;
    _controller.add(value);
  }
}
