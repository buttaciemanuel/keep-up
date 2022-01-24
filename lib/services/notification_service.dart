import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _notificationService = NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init({required Function(String?) onNotificationSelected}) async {
    const androidInitialize = AndroidInitializationSettings('app_icon');
    const iOSInitialize = IOSInitializationSettings();
    const initilizationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    notificationsPlugin.initialize(initilizationsSettings,
        onSelectNotification: onNotificationSelected);

    tz.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Europe/Rome'));
  }

  Future scheduleDailyNotification(
      {required int id,
      required int hour,
      required int minute,
      required String title,
      required String body,
      required String payload}) async {
    const androidDetails = AndroidNotificationDetails(
        "keepup.id", "keepup.notification.channel",
        channelDescription: "KeepUp Notification channel",
        importance: Importance.max);
    const iOSDetails = IOSNotificationDetails();
    const generalNotificationDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);
    final scheduleTime = tz.TZDateTime.local(1, 1, 1, hour, minute);

    // un quarto d'ora di anticipo
    scheduleTime.subtract(const Duration(minutes: 15));

    notificationsPlugin.zonedSchedule(
        id, title, body, scheduleTime, generalNotificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload);
  }

  Future scheduleWeekDayNotification(
      {required int id,
      required int hour,
      required int minute,
      required int weekDay,
      required String title,
      required String body,
      required String payload}) async {
    const androidDetails = AndroidNotificationDetails(
        "keepup.id", "keepup.notification.channel",
        channelDescription: "KeepUp Notification channel",
        importance: Importance.max);
    const iOSDetails = IOSNotificationDetails();
    const generalNotificationDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);
    var now = tz.TZDateTime.now(tz.local);
    now.add(Duration(days: weekDay - now.weekday));
    final scheduleTime =
        tz.TZDateTime.local(now.year, now.month, now.day, hour, minute);

    // un quarto d'ora di anticipo
    scheduleTime.subtract(const Duration(minutes: 15));

    notificationsPlugin.zonedSchedule(
        id, title, body, scheduleTime, generalNotificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload);
  }

  Future scheduleDayNotification(
      {required int id,
      required int hour,
      required int minute,
      required DateTime date,
      required String title,
      required String body,
      required String payload}) async {
    const androidDetails = AndroidNotificationDetails(
        "keepup.id", "keepup.notification.channel",
        channelDescription: "KeepUp Notification channel",
        importance: Importance.max);
    const iOSDetails = IOSNotificationDetails();
    const generalNotificationDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);
    final scheduleTime =
        tz.TZDateTime.local(date.year, date.month, date.day, hour, minute);

    // un quarto d'ora di anticipo
    scheduleTime.subtract(const Duration(minutes: 15));

    notificationsPlugin.zonedSchedule(
        id, title, body, scheduleTime, generalNotificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload);
  }

  Future<void> cancelNotification({required int id}) async {
    await notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await notificationsPlugin.cancelAll();
  }
}

abstract class NotificationServiceConstant {
  static const dailySurveyId = 0;
  //static const dailySurveyIds = [0, 1, 2, 3, 4, 5, 6];
  static const surveyPayload = 'daily-survey-payload';
  static const taskPayload = 'task-payload';
}
