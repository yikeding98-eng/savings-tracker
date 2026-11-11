import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 每月固定日期的本地提醒。不依赖任何服务端，纯本机通知。
class ReminderService {
  static const int _notifId = 1001;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    await _initLocalTimezone();

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(iOS: iosSettings, android: androidSettings),
    );
  }

  Future<void> _initLocalTimezone() async {
    // 用设备当前 UTC 偏移构造固定时区，避免依赖额外的插件。
    try {
      final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
      final zone = tz.TimeZone(offsetMinutes * 60, isDst: false, abbreviation: 'LOCAL');
      tz.setLocalLocation(
        tz.Location('Local', <int>[0], <int>[0], <tz.TimeZone>[zone]),
      );
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  Future<void> cancelAll() => _plugin.cancel(_notifId);

  /// 立即弹一条通知，用来验证通知权限是否生效
  Future<void> showTestNow() async {
    await _plugin.show(
      1002,
      '提醒测试',
      '如果你看到这条通知，说明提醒功能正常。',
      const NotificationDetails(
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        android: AndroidNotificationDetails(
          'savings_reminder',
          '存款提醒',
          channelDescription: '每月提醒存入存款',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> scheduleMonthly({
    required bool enabled,
    required int day,
    required int hour,
    required int minute,
    required String currency,
    required double remaining,
  }) async {
    await _plugin.cancel(_notifId);
    if (!enabled) return;

    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, day, hour, minute);
    if (!when.isAfter(now)) {
      when = tz.TZDateTime(tz.local, now.year, now.month + 1, day, hour, minute);
    }

    final body = remaining > 0
        ? '距离目标还差 ${remaining.toStringAsFixed(0)} $currency，记得存这个月的钱。'
        : '目标已达成了，记得记录一笔。';

    await _plugin.zonedSchedule(
      _notifId,
      '今天该存钱了',
      body,
      when,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        android: AndroidNotificationDetails(
          'savings_reminder',
          '存款提醒',
          channelDescription: '每月提醒存入存款',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  Future<String?> nextScheduleText({
    required bool enabled,
    required int day,
    required int hour,
    required int minute,
  }) async {
    if (!enabled) return null;
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, day, hour, minute);
    if (!when.isAfter(now)) {
      when = tz.TZDateTime(tz.local, now.year, now.month + 1, day, hour, minute);
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return '${when.month} 月 ${when.day} 日 ${two(when.hour)}:${two(when.minute)}';
  }
}
