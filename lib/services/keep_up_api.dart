import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class KeepUp {
  static const _keyApplicationId = '7lriFNc0muHJqnpBYmDJjkCdBP4ptEXEYaSiIZKR';
  static const _keyClientKey = 'Hboaa5QGH79mvRQQfEXCUcjXnZlrXSlZk0axzQri';
  static const _keyParseServerUrl = 'https://parseapi.back4app.com';
  static const _keyParseLocalServerUrl = 'http://localhost:1337/parse/';

  static final KeepUp _instance = KeepUp._();

  KeepUp._();

  static KeepUp get instance => _instance;

  Future<KeepUp> init() async {
    await Parse().initialize(_keyApplicationId, _keyParseLocalServerUrl,
        clientKey: _keyClientKey, autoSendSessionId: true, debug: true);
    return this;
  }

  Future<void> register(String fullName, String email, String password) async {
    final user = ParseUser.createUser(email, password, email);

    user.set(KeepUpUserDataModelKey.fullName, fullName);

    final response = await user.signUp();

    if (response.success) {
      log('KeepUp: user registration success');
    } else {
      return Future.error(
          'KeepUp: user registration failure: ${response.error!.message}');
    }
  }

  Future<void> login(String email, String password) async {
    final user = ParseUser(email, password, email);
    final response = await user.login();

    if (response.success) {
      log('KeepUp: user login success');
    } else {
      return Future.error(
          'KeepUp: user registration failure: ${response.error!.message}');
    }
  }

  Future<void> logout(String email, String password) async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    final response = await currentUser!.logout();

    if (response.success) {
      log('KeepUp: user logout success');
    } else {
      return Future.error(
          'KeepUp: user logout failure: ${response.error!.message}');
    }
  }

  Future<KeepUpUser?> getUser() async {
    // Controlla che ci sia un utente salvato in cache
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    if (currentUser == null) {
      return null;
    }
    // Controlla che il token di sessione associato sia ancora valido
    final parseResponse =
        await ParseUser.getCurrentUserFromServer(currentUser.sessionToken!);
    if (parseResponse?.success == null || !parseResponse!.success) {
      await currentUser.logout();
      return null;
    } else {
      return KeepUpUser(currentUser.get(KeepUpUserDataModelKey.fullName),
          currentUser.emailAddress!, currentUser.sessionToken!);
    }
  }

  Future<void> createEvent(KeepUpEvent event) async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;

    final eventObject = ParseObject(KeepUpEventDataModelKey.className)
      ..set(KeepUpEventDataModelKey.title, event.title)
      ..set(KeepUpEventDataModelKey.startDate, event.startDate)
      ..set(KeepUpEventDataModelKey.endDate, event.endDate)
      ..set(KeepUpEventDataModelKey.creatorId, currentUser!.objectId);

    final response = await eventObject.save();

    if (!response.success) {
      return Future.error(
          'KeepUp: event creation failure: ${response.error!.message}');
    }

    log('KeepUp: event creation success');

    for (final recurrence in event._recurrences) {
      final recurrenceObject = ParseObject(
          KeepUpRecurrenceDataModelKey.className)
        ..set(KeepUpRecurrenceDataModelKey.eventId, eventObject.objectId)
        ..set(KeepUpRecurrenceDataModelKey.description, recurrence.description)
        ..set(KeepUpRecurrenceDataModelKey.startTime, recurrence.startTime)
        ..set(KeepUpRecurrenceDataModelKey.endTime, recurrence.endTime);

      switch (recurrence.type) {
        case KeepUpRecurrenceType.none:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModelKey.day, recurrence.day)
            ..set(KeepUpRecurrenceDataModelKey.month, recurrence.month)
            ..set(KeepUpRecurrenceDataModelKey.year, recurrence.year)
            ..set(KeepUpRecurrenceDataModelKey.weekDay, recurrence.weekDay);
          break;
        case KeepUpRecurrenceType.daily:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModelKey.day, '*')
            ..set(KeepUpRecurrenceDataModelKey.month, '*')
            ..set(KeepUpRecurrenceDataModelKey.year, '*')
            ..set(KeepUpRecurrenceDataModelKey.weekDay, '*');
          break;
        case KeepUpRecurrenceType.weekly:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModelKey.day, null)
            ..set(KeepUpRecurrenceDataModelKey.month, '*')
            ..set(KeepUpRecurrenceDataModelKey.year, '*')
            ..set(KeepUpRecurrenceDataModelKey.weekDay, recurrence.weekDay);
          break;
        case KeepUpRecurrenceType.monthly:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModelKey.day, recurrence.day)
            ..set(KeepUpRecurrenceDataModelKey.month, recurrence.month)
            ..set(KeepUpRecurrenceDataModelKey.year, '*')
            ..set(KeepUpRecurrenceDataModelKey.weekDay, null);
          break;
        default:
      }

      final response = await recurrenceObject.save();

      if (!response.success) {
        return Future.error(
            'KeepUp: recurrence creation failure: ${response.error!.message}');
      }

      log('KeepUp: recurrence creation success');

      for (final exception in recurrence._exceptions) {
        final exceptionObject =
            ParseObject(KeepUpExceptionDataModelKey.className)
              ..set(KeepUpExceptionDataModelKey.eventId, eventObject.objectId)
              ..set(KeepUpExceptionDataModelKey.recurrenceId,
                  recurrenceObject.objectId)
              ..set(KeepUpExceptionDataModelKey.onDate, exception.onDate);

        final response = await exceptionObject.save();

        if (!response.success) {
          return Future.error(
              'KeepUp: exception creation failure: ${response.error!.message}');
        } else {
          log('KeepUp: exception creation success');
        }
      }
    }
  }
}

class KeepUpUser {
  String fullname;
  String email;
  String sessionToken;

  KeepUpUser(this.fullname, this.email, this.sessionToken);
}

class KeepUpEvent {
  int? id;
  final String title;
  final DateTime startDate;
  final DateTime? endDate;
  final List<KeepUpRecurrence> _recurrences = [];

  KeepUpEvent(
      {this.id, required this.title, required this.startDate, this.endDate});

  void addDailySchedule({required TimeOfDay startTime, TimeOfDay? endTime}) {
    _recurrences.add(KeepUpRecurrence(
        type: KeepUpRecurrenceType.daily,
        startTime: startTime,
        endTime: endTime));
  }

  void addWeeklySchedule(
      {required int weekDay,
      required TimeOfDay startTime,
      TimeOfDay? endTime}) {
    _recurrences.add(KeepUpRecurrence(
        type: KeepUpRecurrenceType.weekly,
        weekDay: weekDay,
        startTime: startTime,
        endTime: endTime));
  }

  void addMonthlySchedule(
      {required int day, required TimeOfDay startTime, TimeOfDay? endTime}) {
    _recurrences.add(KeepUpRecurrence(
        type: KeepUpRecurrenceType.monthly,
        day: day,
        startTime: startTime,
        endTime: endTime));
  }

  void addSchedule(
      {required int day,
      required int month,
      required int year,
      required TimeOfDay startTime,
      TimeOfDay? endTime}) {
    final date = DateTime(year, month, day);
    _recurrences.add(KeepUpRecurrence(
        type: KeepUpRecurrenceType.none,
        day: day,
        month: month,
        year: year,
        weekDay: date.weekday,
        startTime: startTime,
        endTime: endTime));
  }
}

enum KeepUpRecurrenceType { none, daily, weekly, monthly }

class KeepUpRecurrence {
  int? id;
  int? eventId;
  final KeepUpRecurrenceType type;
  final String? description;
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final int? day;
  final int? month;
  final int? year;
  final int? weekDay;
  final List<KeepUpRecurrenceException> _exceptions = [];

  KeepUpRecurrence(
      {this.id,
      this.eventId,
      required this.type,
      this.description,
      required this.startTime,
      this.endTime,
      this.day,
      this.month,
      this.year,
      this.weekDay});

  void addException(
      {int? eventId, int? recurrenceId, required DateTime onDate}) {
    _exceptions.add(KeepUpRecurrenceException(
        eventId: eventId, recurrenceId: recurrenceId, onDate: onDate));
  }
}

class KeepUpRecurrenceException {
  final int? eventId;
  final int? recurrenceId;
  final DateTime onDate;

  KeepUpRecurrenceException(
      {this.eventId, this.recurrenceId, required this.onDate});
}

abstract class KeepUpUserDataModelKey {
  static const className = 'User';
  static const id = 'objectId';
  static const username = 'username';
  static const email = 'email';
  static const password = 'password';
  static const fullName = 'fullName';
}

abstract class KeepUpEventDataModelKey {
  static const className = 'Event';
  static const id = 'id';
  static const title = 'title';
  static const startDate = 'startDate';
  static const endDate = 'endDate';
  static const creatorId = 'creatorId';
}

abstract class KeepUpRecurrenceDataModelKey {
  static const className = 'Recurrence';
  static const id = 'id';
  static const eventId = 'eventId';
  static const description = 'description';
  static const startTime = 'startTime';
  static const endTime = 'endTime';
  //static const interval = 'interval';
  static const day = 'day';
  static const month = 'month';
  static const year = 'year';
  static const weekDay = 'weekDay';
}

abstract class KeepUpExceptionDataModelKey {
  static const className = 'Exception';
  static const eventId = 'eventId';
  static const recurrenceId = 'recurrenceId';
  static const onDate = 'onDate';
}
