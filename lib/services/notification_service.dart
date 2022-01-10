import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:keep_up/screens/home_screen.dart';

class NotificationService {
  static final _notificationService = NotificationService._internal();
  late BuildContext _context;

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future notificationSelected(String? payload) async {
    log('notification ${payload}');
  }

  Future<void> init(BuildContext context) async {
    const androidInitialize = AndroidInitializationSettings('app_icon');
    const iOSInitialize = IOSInitializationSettings();
    const initilizationsSettings =
        InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    _notificationsPlugin.initialize(initilizationsSettings,
        onSelectNotification: notificationSelected);

    _context = context;

    tz.initializeTimeZones();

    _scheduleNotification();
  }

  Future _scheduleNotification() async {
    const androidDetails = AndroidNotificationDetails(
        "Channel ID", "Desi programmer",
        channelDescription: "This is my channel", importance: Importance.max);
    const iOSDetails = IOSNotificationDetails();
    const generalNotificationDetails =
        NotificationDetails(android: androidDetails, iOS: iOSDetails);
    final currentDateTime =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 20));

    _notificationsPlugin.zonedSchedule(
        1, 'KeepUp', 'Hello, boy', currentDateTime, generalNotificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.time);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
