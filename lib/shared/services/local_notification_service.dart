import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Инициализация плагина
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_stat_notification_icon');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        // Обработка нажатия на уведомление
        print('Notification tapped: ${response.payload}');
      },
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    debugPrint('Local time zone: $timeZoneName');
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

  // Показ FCM-уведомления как локального
  Future<void> showFCMNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fcm_channel',
      'FCM Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _notificationsPlugin.show(
      DateTime.now().hashCode,
      title,
      body,
      notificationDetails,
    );
  }

  // Future<void> scheduleOneTimeNotification({
  //   required int id,
  //   required String title,
  //   required String body,
  //   required DateTime scheduledDateTime,
  // }) async {
  //   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
  //     'one_time_channel_id',
  //     'One Time Notifications',
  //     importance: Importance.max,
  //     priority: Priority.high,
  //   );
  //   const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
  //     presentAlert: true,
  //     presentBadge: true,
  //     presentSound: true,
  //   );
  //   const NotificationDetails notificationDetails = NotificationDetails(
  //     android: androidDetails,
  //     iOS: iosDetails,
  //   );

  //   tz.TZDateTime scheduledDate = tz.TZDateTime.from(scheduledDateTime, tz.local);

  //   debugPrint('Scheduling notification for $scheduledDate');

  //   await _notificationsPlugin.zonedSchedule(
  //     id,
  //     title,
  //     body,
  //     tz.TZDateTime.from(scheduledDateTime, tz.local),
  //     notificationDetails,
  //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //   );
  // }

  // Future<void> scheduleWeeklyNotifications({
  //   required int baseId,
  //   required String title,
  //   required String body,
  //   required TimeOfDay time,
  //   required List<int> weekdays,
  // }) async {
  //   for (final weekday in weekdays) {
  //     final id = baseId + weekday;
  //     await _scheduleWeeklyRecurringNotification(
  //       id: id,
  //       title: title,
  //       body: body,
  //       time: time,
  //       weekday: weekday,
  //     );
  //   }
  // }

  // Future<void> _scheduleWeeklyRecurringNotification({
  //   required int id,
  //   required String title,
  //   required String body,
  //   required TimeOfDay time,
  //   required int weekday,
  // }) async {
  //   final now = tz.TZDateTime.now(tz.local);

  //   tz.TZDateTime scheduledDate = tz.TZDateTime(
  //     tz.local,
  //     now.year,
  //     now.month,
  //     now.day,
  //     time.hour,
  //     time.minute,
  //   );

  //   while (scheduledDate.weekday != weekday + 1) {
  //     scheduledDate = scheduledDate.add(const Duration(days: 1));
  //   }

  //   debugPrint('Scheduling Weekly notification for $scheduledDate');

  //   await _notificationsPlugin.zonedSchedule(
  //     id,
  //     title,
  //     body,
  //     scheduledDate,
  //     const NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         'weekly_channel_id',
  //         'Weekly Notifications',
  //         importance: Importance.max,
  //         priority: Priority.high,
  //       ),
  //       iOS: DarwinNotificationDetails(),
  //     ),
  //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //     matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
  //   );
  // }

  // void getSchedules()async{
  //   final notifications = await _notificationsPlugin.getActiveNotifications();
  //   for (final notification in notifications) {
  //     debugPrint('Notification ID: ${notification.id}');
  //   }

  //   final notifications2 = await _notificationsPlugin.pendingNotificationRequests();
  //   for (final notification in notifications2) {
  //     debugPrint('Notification2 ID: ${notification.id}');
  //   }
  // }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> setDailyDiaryReminder(bool dairyPushSetting, {bool force = false}) async {
    if (!dairyPushSetting) {
      print('Настройки уведомления дневника отключана');
      return;
    }
    if (!force) {
      bool alreadyHas = false;
      final schedules = await _notificationsPlugin.pendingNotificationRequests();
      for (final notification in schedules) {
        debugPrint('Notification ID: ${notification.id}');
        alreadyHas = notification.id == dairyReminderId;
      }

      if (alreadyHas) {
        print('напоминание уже поставлено');
        return;
      }
    }

    if (force) {
      await _notificationsPlugin.cancel(dairyReminderId);
    }

    final now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduledTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20, 0, 0);

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    debugPrint('Scheduling Weekly notification for $scheduledTime');

    await _notificationsPlugin.zonedSchedule(
      dairyReminderId,
      'Время для дневника!',
      'Не забудьте оставить запись в своем дневнике сегодня.',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'diary_reminder_channel',
          'Напоминания о дневнике',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> toggleDailyDiaryReminders(bool isEnabled) async {
    if (isEnabled) {
      await setDailyDiaryReminder(true, force: true); // Включаем напоминания
      print('Ежедневные напоминания о дневнике включены.');
    } else {
      await _notificationsPlugin.cancel(dairyReminderId); // Отменяем все напоминания
      print('Ежедневные напоминания о дневнике отключены.');
    }
  }
}
