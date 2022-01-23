import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
    final notificationTime = tz.TZDateTime.local(1, 1, 1, hour, minute);

    notificationsPlugin.zonedSchedule(
        id, title, body, notificationTime, generalNotificationDetails,
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
    var notificationTime = tz.TZDateTime.local(1, 1, 1, hour, minute);
    notificationTime = notificationTime
        .subtract(Duration(days: notificationTime.weekday))
        .add(Duration(days: weekDay));

    notificationsPlugin.zonedSchedule(
        id, title, body, notificationTime, generalNotificationDetails,
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
    var notificationTime =
        tz.TZDateTime.local(date.day, date.month, date.year, hour, minute);

    notificationsPlugin.zonedSchedule(
        id, title, body, notificationTime, generalNotificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
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
