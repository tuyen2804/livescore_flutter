import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/local/db_entities.dart';

/// Port của `util/NotificationHelper.kt` + `receiver/MatchAlarmReceiver.kt`.
/// Android dùng AlarmManager, Flutter dùng zonedSchedule — cùng một hành vi.
class NotificationService {
  static const String channelId = 'match_notifications';
  static const String channelName = 'Match notifications';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(await _localTimeZone()));

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: darwinInit),
        onDidReceiveNotificationResponse: _onTap,
      );

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          importance: Importance.high,
        ),
      );
      _ready = true;
    } catch (e) {
      dev.log('Notification init failed: $e', name: 'NotificationHelper');
    }
  }

  Future<String> _localTimeZone() async {
    // Suy ra vùng giờ từ offset hiện tại; đủ cho lịch báo trận.
    final offset = DateTime.now().timeZoneOffset;
    for (final name in tz.timeZoneDatabase.locations.keys) {
      final loc = tz.timeZoneDatabase.locations[name]!;
      final now = tz.TZDateTime.now(loc);
      if (now.timeZoneOffset == offset) return name;
    }
    return 'UTC';
  }

  /// Xin quyền POST_NOTIFICATIONS (Android 13+) và exact alarm.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestExactAlarmsPermission();
      return status.isGranted;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  Future<bool> get isPermissionGranted async {
    if (!Platform.isAndroid) return true;
    return Permission.notification.isGranted;
  }

  /// Port `NotificationHelper.scheduleNotification`: một báo trước trận
  /// (`beforeMatchMinutes`) và một báo lúc bóng lăn.
  Future<void> schedule(NotificationDbItem item) async {
    if (!_ready) return;
    final kickoff = item.kickoffTime;
    if (kickoff == null) {
      dev.log(
        "Failed to parse date: '${item.timeStr}' for match ${item.id}",
        name: 'NotificationHelper',
      );
      return;
    }

    final title = '${item.homeName} vs ${item.awayName}';

    if (item.beforeMatchMinutes > 0) {
      final at = kickoff.subtract(Duration(minutes: item.beforeMatchMinutes));
      await _scheduleAt(
        id: item.id * 10,
        at: at,
        title: title,
        body: 'Starts in ${item.beforeMatchMinutes} minutes'
            '${item.leagueName == null ? '' : ' · ${item.leagueName}'}',
        payload: '${item.id}',
      );
    }

    if (item.notifyMatchStart) {
      await _scheduleAt(
        id: item.id * 10 + 1,
        at: kickoff,
        title: title,
        body: 'Kick-off'
            '${item.leagueName == null ? '' : ' · ${item.leagueName}'}',
        payload: '${item.id}',
      );
    }
  }

  Future<void> _scheduleAt({
    required int id,
    required DateTime at,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!at.isAfter(DateTime.now())) {
      dev.log('Alarm $id is in the PAST ($at)', name: 'NotificationHelper');
      return;
    }
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(at, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      dev.log('Scheduled alarm $id at $at', name: 'NotificationHelper');
    } catch (e) {
      dev.log('Schedule $id failed: $e', name: 'NotificationHelper');
    }
  }

  /// Port `NotificationHelper.cancelNotification`.
  Future<void> cancel(int fixtureId) async {
    if (!_ready) return;
    await _plugin.cancel(fixtureId * 10);
    await _plugin.cancel(fixtureId * 10 + 1);
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  /// Callback khi người dùng chạm vào thông báo — điền ở tầng router.
  static void Function(int fixtureId)? onNotificationTap;

  static void _onTap(NotificationResponse response) {
    final id = int.tryParse(response.payload ?? '');
    if (id != null) onNotificationTap?.call(id);
  }
}
