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

  final _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init({required Function(String?) onNotificationSelected}) async {
    const androidInitialize = AndroidInitializationSettings('app_icon');
    const iOSInitialize = IOSInitializationSettings();
    const initilizationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    _notificationsPlugin.initialize(initilizationsSettings,
        onSelectNotification: onNotificationSelected);

    tz.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Europe/Rome'));
  }

  Future scheduleNotification(
      {required int id,
      required int hour,
      required int minute,
      required String title,
      required String body}) async {
    const androidDetails = AndroidNotificationDetails(
        "keepup.id", "keepup.notification.channel",
        channelDescription: "KeepUp Notification channel",
        importance: Importance.max);
    const iOSDetails = IOSNotificationDetails();
    const generalNotificationDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);
    final notificationTime = tz.TZDateTime.local(1, 1, 1, hour, minute);

    _notificationsPlugin.zonedSchedule(
        id, title, body, notificationTime, generalNotificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.time);
  }

  Future<void> cancelNotification({required int id}) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}

class NotificationServiceId {
  static const dailySurveyIds = [0, 1, 2, 3, 4, 5, 6];
}
