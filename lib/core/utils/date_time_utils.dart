import 'package:intl/intl.dart';

/// Port 1:1 của `util/DateTimeUtils.kt`.
class DateTimeUtils {
  const DateTimeUtils._();

  static final DateFormat _hhmm = DateFormat('HH:mm');
  static final DateFormat _ddMM = DateFormat('dd/MM');
  static final DateFormat _yyyyMMdd = DateFormat('yyyy-MM-dd');
  static final DateFormat _utcParse = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Chuỗi UTC "yyyy-MM-dd HH:mm:ss" hoặc epoch giây → giờ local "HH:mm".
  static String convertUtcToLocalTime(String? utcString) {
    if (utcString == null || utcString.trim().isEmpty) return '';
    final epoch = int.tryParse(utcString);
    if (epoch != null && epoch > 0) return formatEpochToLocalTime(epoch);
    try {
      return _hhmm.format(_utcParse.parseUtc(utcString).toLocal());
    } catch (_) {
      final afterSpace =
          utcString.contains(' ') ? utcString.split(' ').last : utcString;
      final idx = afterSpace.lastIndexOf(':');
      return idx > 0 ? afterSpace.substring(0, idx) : afterSpace;
    }
  }

  /// Chuỗi UTC hoặc epoch giây → ngày local "dd/MM".
  static String convertUtcToLocalDate(String? utcString) {
    if (utcString == null || utcString.trim().isEmpty) return '';
    final epoch = int.tryParse(utcString);
    if (epoch != null && epoch > 0) return formatEpochToLocalDate(epoch);
    try {
      return _ddMM.format(_utcParse.parseUtc(utcString).toLocal());
    } catch (_) {
      final parts = utcString.split(' ').first.split('-');
      return parts.length >= 3 ? '${parts[2]}/${parts[1]}' : '';
    }
  }

  static String formatEpochToLocalTime(int epochSeconds) =>
      _hhmm.format(_fromEpoch(epochSeconds));

  static String formatEpochToLocalDate(int epochSeconds) =>
      _ddMM.format(_fromEpoch(epochSeconds));

  static String formatEpochToLocalDateFull(int epochSeconds) =>
      _yyyyMMdd.format(_fromEpoch(epochSeconds));

  static DateTime _fromEpoch(int epochSeconds) =>
      DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);

  /// Epoch giây → `"YYYY-MM-DD HH:mm:ss"` UTC.
  ///
  /// Đúng định dạng `starting_at` / `kickoffUtc` của backend bóng đá, để dữ
  /// liệu Sofascore đổ vào cùng DTO mà các hàm parse sẵn có vẫn đọc được.
  static String epochToUtcString(int epochSeconds) {
    final d = DateTime.fromMillisecondsSinceEpoch(
      epochSeconds * 1000,
      isUtc: true,
    );
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  // ---- Bổ sung cho tầng UI ----

  static String apiDate(DateTime date) => _yyyyMMdd.format(date);

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Offset múi giờ tính bằng giây — Sofascore dùng trong path `{timezoneOffset}`.
  static String get timezoneOffsetSeconds =>
      DateTime.now().timeZoneOffset.inSeconds.toString();
}
