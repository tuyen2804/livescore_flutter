import 'dart:async';

import '../../core/services/notification_service.dart';
import '../../data/datasources/local/league_db_helper.dart';
import '../../data/models/local/db_entities.dart';
import 'base_provider.dart';

/// Nhóm thông báo theo ngày — port `NotificationGroup.kt`.
/// Một giải kèm danh sách trận đã bật thông báo.
class NotificationGroup {
  const NotificationGroup({
    required this.dateLabel,
    required this.items,
    this.logoUrl,
  });
  final String dateLabel;
  final List<NotificationDbItem> items;
  final String? logoUrl;
}

/// Port `presentation/notification/NotificationViewModel.kt`.
class NotificationProvider extends BaseProvider {
  NotificationProvider(this._db, this._notifications) {
    unawaited(loadNotifications());
  }

  final LeagueDbHelper _db;
  final NotificationService _notifications;

  List<NotificationDbItem> _items = const [];
  bool _isLoading = false;
  bool _permissionGranted = true;

  List<NotificationDbItem> get items => _items;
  bool get isLoading => _isLoading;
  bool get permissionGranted => _permissionGranted;

  /// Port `NotificationFragment.filterBySport` — chip môn đang chọn
  /// ("all" là mặc định, hiện tất cả).
  String _sportSlug = 'football';
  String get sportSlug => _sportSlug;

  void filterBySport(String slug) => setState(() => _sportSlug = slug);

  /// Port `applyFilterAndPost`: "all" lấy hết; "football" gồm cả bản ghi
  /// chưa gắn môn; còn lại so khớp đúng slug.
  List<NotificationDbItem> get _visibleItems => switch (_sportSlug) {
        'all' => _items,
        'football' => _items
            .where((e) =>
                (e.sportSlug ?? '').isEmpty || e.sportSlug == 'football')
            .toList(growable: false),
        _ => _items
            .where((e) => e.sportSlug == _sportSlug)
            .toList(growable: false),
      };

  bool get isEmpty => _visibleItems.isEmpty;

  /// Bản gốc gom theo **giải** (`NotificationAdapter` dùng `item_league_section`),
  /// giữ nguyên thứ tự giải xuất hiện đầu tiên.
  List<NotificationGroup> get groups {
    final order = <String>[];
    final map = <String, List<NotificationDbItem>>{};
    for (final item in _visibleItems) {
      final key = item.leagueName ?? 'Other';
      if (!map.containsKey(key)) order.add(key);
      map.putIfAbsent(key, () => <NotificationDbItem>[]).add(item);
    }
    return order
        .map((k) => NotificationGroup(
              dateLabel: k,
              logoUrl: map[k]!.first.leagueLogoUrl,
              items: map[k]!,
            ))
        .toList(growable: false);
  }

  Future<void> loadNotifications() async {
    setState(() => _isLoading = true);
    _permissionGranted = await _notifications.isPermissionGranted;
    try {
      _items = await _db.getAllNotifications();
    } catch (_) {
      _items = const [];
    }
    setState(() => _isLoading = false);
  }

  Future<bool> requestPermission() async {
    final granted = await _notifications.requestPermission();
    setState(() => _permissionGranted = granted);
    return granted;
  }

  Future<void> toggle(NotificationDbItem item) async {
    final wasEnabled = await _db.isNotificationEnabled(item.id);
    await _db.toggleNotification(item);
    if (wasEnabled) {
      await _notifications.cancel(item.id);
    } else {
      await _notifications.schedule(item);
    }
    await loadNotifications();
  }

  /// Cập nhật cấu hình chi tiết (báo trước bao phút, các mốc trong trận).
  Future<void> updateConfig(NotificationDbItem item) async {
    await _db.saveNotification(item);
    await _notifications.cancel(item.id);
    await _notifications.schedule(item);
    await loadNotifications();
  }

  Future<void> removeAll() async {
    for (final item in _items) {
      await _db.removeNotification(item.id);
      await _notifications.cancel(item.id);
    }
    await loadNotifications();
  }
}
