import 'dart:developer' as dev;

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Port khối `RequestConfiguration` trong `MyApplication.onCreate` của bản
/// Kotlin.
///
/// Ở bản mẫu, **toàn bộ 27 id trong danh sách đều đang bị comment**, tức app
/// phát hành chạy với danh sách rỗng. Danh sách đó chép lại ở [knownDevices]
/// để tra khi cần, còn [ids] mới là thứ thật sự được nạp.
///
/// Vì sao phải khai: thiết bị nằm trong danh sách sẽ nhận **quảng cáo thử**
/// thay vì quảng cáo thật. Bấm vào quảng cáo thật trên máy của chính mình bị
/// AdMob tính là traffic không hợp lệ và có thể bị khoá tài khoản.
///
/// ## Lấy id của máy đang cắm
///
/// Chạy app rồi lọc logcat, AdMob tự in ra dòng hướng dẫn kèm id:
///
/// ```bash
/// adb logcat -s Ads | grep -i "setTestDeviceIds"
/// ```
///
/// Nó in đại loại `Use RequestConfiguration.Builder().setTestDeviceIds(
/// Arrays.asList("33BE2250B43518CCDA7DE426D04EE231"))`. Chép chuỗi 32 ký tự
/// đó bỏ vào [ids].
///
/// Trên iOS thì id nằm trong Xcode console với tiền tố
/// `GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers`.
class AdsTestDevices {
  const AdsTestDevices._();

  /// Danh sách thật sự nạp vào SDK. **Phải để rỗng khi phát hành.**
  ///
  /// Lưu ý: chỉ **AVD của Android Studio** mới được SDK tự nhận là thiết bị
  /// thử (nhận diện qua `ro.kernel.qemu`, `ro.hardware=goldfish/ranchu`,
  /// fingerprint chứa `generic`). Các emulator bên thứ ba như **LDPlayer giả
  /// hết build prop thành máy thật** (`ro.product.model=PHY110`,
  /// `ro.hardware=qcom`, không có `/dev/qemu_pipe`) nên **vẫn nhận quảng cáo
  /// thật** — bắt buộc phải khai tay id vào đây.
  static const List<String> ids = <String>[
    // Máy ảo LDPlayer đang dùng để test (đã xác nhận bằng log
    // `I/Ads: Use RequestConfiguration.Builder().setTestDeviceIds(...)`).
    // Id này cũng nằm trong danh sách bị comment của bản Kotlin và trong
    // `ConsentDebugSettings.addTestDeviceHashedId` — máy của team gốc.
    'A7661CEF06EF6EDCD3DB932D51284AFB',
  ];

  /// 27 id đang bị comment trong `MyApplication.kt`, giữ lại để đối chiếu.
  /// Không được nạp tự động: không rõ máy nào còn dùng, mà thừa id thì có
  /// máy thật lại nhận quảng cáo thử và báo cáo doanh thu sai.
  static const List<String> knownDevices = <String>[
    '3DB522DA9EC062203E724E013A39A1DD',
    '652CC931734A025284137EC0829DBB84',
    'AFD5DCC1571EAE16D4706B8AF52A0CC7',
    '4C454BB46310F9CAED255E62452BEEA3',
    '583C7AE0FC50BC1F2F994D47E7C302A8',
    'F377372F1FCCB85710A04FC353FC0A50',
    '3D1A1A81971380C6C98AA6C7563C63B3',
    '89CE1C46E698DB82CA1CFEF78FE61018',
    '5E0D01B7A24FF7820342F498D7C88A65',
    '5487B281BC6755256ABA0EC516F66FBA',
    'A7661CEF06EF6EDCD3DB932D51284AFB',
    'B423420A7097E058E5FC1757529CA39B',
    '9AD553436CA6A0FE031EFA1797F79519',
    'C68D2E2A449766FF01A517BBCEA97523',
    '13C6E6CA9A05C62EDE4E515CA56073E2',
    'B42806ABD9B85FEDD5ACA46941069E33',
    '9FEE217D4CC8783EA521D42C9A2C0D45',
    '83E99D983476515FD6BA2AE337D156AE',
    'CB71E6FB3523B1CA1FDE958221D47AA8',
    '3FADA94F4C3418D72005A1F45FCB7F47',
    'D7C561694748985D7E44084BE23D9E28',
    '05EF8EA6BB360D1177FE441BA7224E7D',
    'DC466FF057AAD696D3ADBF66623902F1',
    '91DDB8800A77D0DF4C005EE52EAB8781',
    '5BDA74097201226A26450319E4A64CA1',
    'ECA7D07CF54E2147A87FEA9685C75614',
    'F433FFA83EB6A655EE8159D63F485F20',
  ];

  /// Gọi **trước** `MobileAds.instance.initialize()`, đúng thứ tự của bản gốc
  /// (`MobileAds.setRequestConfiguration(...)` rồi mới `MobileAds.initialize`).
  static Future<void> apply() async {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: ids),
    );
    if (ids.isEmpty) {
      dev.log(
        'Chưa khai test device — máy thật sẽ nhận quảng cáo THẬT. '
        'Lấy id bằng: adb logcat -s Ads | grep setTestDeviceIds',
        name: 'AdsTestDevices',
      );
    } else {
      dev.log('Test devices: ${ids.length}', name: 'AdsTestDevices');
    }
  }
}
