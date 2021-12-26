import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_up/main.dart';
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
      ..set(KeepUpEventDataModelKey.creatorId, currentUser!.toPointer());

    final response = await eventObject.save();

    if (!response.success) {
      return Future.error(
          'KeepUp: event creation failure: ${response.error!.message}');
    }

    log('KeepUp: event creation success ${eventObject.objectId}');

    for (final recurrence in event._recurrences) {
      final recurrenceObject = ParseObject(
          KeepUpRecurrenceDataModelKey.className)
        ..set(KeepUpRecurrenceDataModelKey.eventId, eventObject.toPointer())
        ..set(KeepUpRecurrenceDataModelKey.description, recurrence.description)
        ..set(KeepUpRecurrenceDataModelKey.startTime, recurrence.startTime)
        ..set(KeepUpRecurrenceDataModelKey.endTime, recurrence.endTime)
        ..set(KeepUpRecurrenceDataModelKey.type, recurrence.type.index);

      switch (recurrence.type) {
        case KeepUpRecurrenceType.none:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModelKey.day, recurrence.day.toString())
            ..set(
                KeepUpRecurrenceDataModelKey.month, recurrence.month.toString())
            ..set(KeepUpRecurrenceDataModelKey.year, recurrence.year.toString())
            ..set(KeepUpRecurrenceDataModelKey.weekDay,
                recurrence.weekDay.toString());
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
            ..set(KeepUpRecurrenceDataModelKey.weekDay,
                recurrence.weekDay.toString());
          break;
        case KeepUpRecurrenceType.monthly:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModelKey.day, recurrence.day.toString())
            ..set(
                KeepUpRecurrenceDataModelKey.month, recurrence.month.toString())
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
        final exceptionObject = ParseObject(
            KeepUpExceptionDataModelKey.className)
          ..set(KeepUpExceptionDataModelKey.eventId, eventObject.toPointer())
          ..set(KeepUpExceptionDataModelKey.recurrenceId,
              recurrenceObject.toPointer())
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

  Future<List<KeepUpTask>> getTasks({required DateTime inDate}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    // costruisce la lista di eventi appartenenti all'utente
    final isUserEventQuery =
        QueryBuilder.name(KeepUpEventDataModelKey.className)
          ..whereEqualTo(KeepUpEventDataModelKey.creatorId,
              KeepUpUserDataModelKey.pointerTo(currentUser!.objectId!));
    // questa query restituisce le eccezioni in tale data da escludere
    final exceptionsQuery =
        QueryBuilder.name(KeepUpExceptionDataModelKey.className)
          ..keysToReturn([KeepUpExceptionDataModelKey.recurrenceId])
          ..whereEqualTo(KeepUpExceptionDataModelKey.onDate, inDate)
          // seleziona solo le eccezioni di ricorrenze del'utente loggato
          ..whereMatchesQuery(
              KeepUpExceptionDataModelKey.eventId, isUserEventQuery);
    // effettua le query
    final exceptionObjects = await exceptionsQuery.find();
    // questa query restituisce gli eventi dell'utente in data
    final eventsQuery = QueryBuilder.name(KeepUpEventDataModelKey.className)
      // seleziona solo le eccezioni di ricorrenze del'utente loggato
      ..whereEqualTo(KeepUpEventDataModelKey.creatorId,
          KeepUpUserDataModelKey.pointerTo(currentUser.objectId!))
      // filtra le date
      ..whereLessThanOrEqualTo(KeepUpEventDataModelKey.startDate, inDate);
    // effettua la query
    final eventsObjects = await eventsQuery.find();
    // costruisce la query principale
    final mainQuery = QueryBuilder.name(KeepUpRecurrenceDataModelKey.className)
      // seleziona le colonne relative al nome evento, ora fine e ora inizio
      ..includeObject([
        KeepUpEventDataModelKey.className,
        KeepUpExceptionDataModelKey.className
      ])
      // seleziona le ricorrenze degli eventi dell'utente loggato
      ..whereContainedIn(KeepUpRecurrenceDataModelKey.eventId,
          eventsObjects.map((e) => e[KeepUpEventDataModelKey.id]).toList())
      // scarta le eccezioni in quella data
      ..whereNotContainedIn(
          KeepUpRecurrenceDataModelKey.id,
          exceptionObjects
              .map((e) => e[KeepUpExceptionDataModelKey.recurrenceId])
              .toList());

    // effettua la query principale
    final recurrenceObjects = await mainQuery.find();

    if (recurrenceObjects.isEmpty) return [];

    // filtra le occorrenze
    final tasks = recurrenceObjects
        .where((recurrenceObject) {
          final endEventDate = eventsObjects.firstWhere((eventObject) {
            return eventObject[KeepUpEventDataModelKey.id] ==
                recurrenceObject[KeepUpRecurrenceDataModelKey.eventId]
                    [KeepUpEventDataModelKey.id];
          })[KeepUpEventDataModelKey.endDate];

          return (endEventDate != null
                  ? inDate.compareTo(endEventDate as DateTime) <= 0
                  : true) &&
              (recurrenceObject[KeepUpRecurrenceDataModelKey.day] == '*' ||
                  recurrenceObject[KeepUpRecurrenceDataModelKey.day] ==
                      inDate.day.toString() ||
                  recurrenceObject[KeepUpRecurrenceDataModelKey.weekDay] ==
                      '*' ||
                  recurrenceObject[KeepUpRecurrenceDataModelKey.weekDay] ==
                      inDate.weekday.toString()) &&
              (recurrenceObject[KeepUpRecurrenceDataModelKey.month] == '*' ||
                  recurrenceObject[KeepUpRecurrenceDataModelKey.month] ==
                      inDate.month.toString()) &&
              (recurrenceObject[KeepUpRecurrenceDataModelKey.year] == '*' ||
                  recurrenceObject[KeepUpRecurrenceDataModelKey.year] ==
                      inDate.year.toString());
        })
        .map((recurrenceObject) {
          return KeepUpTask(
              title: eventsObjects.firstWhere((eventObject) {
                return eventObject[KeepUpEventDataModelKey.id] ==
                    recurrenceObject[KeepUpRecurrenceDataModelKey.eventId]
                        [KeepUpEventDataModelKey.id];
              })[KeepUpEventDataModelKey.title],
              startTime: KeepUpDayTime.fromJson(
                  recurrenceObject[KeepUpRecurrenceDataModelKey.startTime]),
              endTime: KeepUpDayTime.fromJson(
                  recurrenceObject[KeepUpRecurrenceDataModelKey.startTime]));
        })
        .toSet()
        .toList();

    tasks.sort((a, b) => a.startTime.compareTo(b.startTime));

    return tasks;

    /*final response = await mainQuery.query();

    if (response.success && response.results != null) {
      for (var o in response.results!) {
        log((o as ParseObject).toString());
      }
    } else {
      log('query failed: ${response.error!.message}');
    }*/
  }
}

class KeepUpUser {
  String fullname;
  String email;
  String sessionToken;

  KeepUpUser(this.fullname, this.email, this.sessionToken);
}

class KeepUpEvent {
  String? id;
  final String title;
  final DateTime startDate;
  final DateTime? endDate;
  final List<KeepUpRecurrence> _recurrences = [];

  KeepUpEvent(
      {this.id, required this.title, required this.startDate, this.endDate});

  void addDailySchedule(
      {required KeepUpDayTime startTime, KeepUpDayTime? endTime}) {
    _recurrences.add(KeepUpRecurrence(
        type: KeepUpRecurrenceType.daily,
        startTime: startTime,
        endTime: endTime));
  }

  void addWeeklySchedule(
      {required int weekDay,
      required KeepUpDayTime startTime,
      KeepUpDayTime? endTime}) {
    _recurrences.add(KeepUpRecurrence(
        type: KeepUpRecurrenceType.weekly,
        weekDay: weekDay,
        startTime: startTime,
        endTime: endTime));
  }

  void addMonthlySchedule(
      {required int day,
      required KeepUpDayTime startTime,
      KeepUpDayTime? endTime}) {
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
      required KeepUpDayTime startTime,
      KeepUpDayTime? endTime}) {
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

enum KeepUpRecurrenceType { daily, weekly, monthly, none }

class KeepUpRecurrence {
  String? id;
  String? eventId;
  KeepUpRecurrenceType type;
  String? description;
  KeepUpDayTime startTime;
  KeepUpDayTime? endTime;
  int? day;
  int? month;
  int? year;
  int? weekDay;
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

  factory KeepUpRecurrence.fromJson(dynamic json) {
    final result = KeepUpRecurrence(
        id: json[KeepUpRecurrenceDataModelKey.id],
        eventId: json[KeepUpRecurrenceDataModelKey.eventId]
            [KeepUpEventDataModelKey.id],
        startTime: KeepUpDayTime.fromJson(
            json[KeepUpRecurrenceDataModelKey.startTime]),
        endTime:
            KeepUpDayTime.fromJson(json[KeepUpRecurrenceDataModelKey.endTime]),
        type: KeepUpRecurrenceType
            .values[json[KeepUpRecurrenceDataModelKey.type]]);

    switch (result.type) {
      case KeepUpRecurrenceType.none:
        result.day = int.parse(json[KeepUpRecurrenceDataModelKey.day]);
        result.month = int.parse(json[KeepUpRecurrenceDataModelKey.month]);
        result.year = int.parse(json[KeepUpRecurrenceDataModelKey.year]);
        result.weekDay = int.parse(json[KeepUpRecurrenceDataModelKey.weekDay]);
        break;
      case KeepUpRecurrenceType.daily:
        break;
      case KeepUpRecurrenceType.weekly:
        result.weekDay = int.parse(json[KeepUpRecurrenceDataModelKey.weekDay]);
        break;
      case KeepUpRecurrenceType.monthly:
        result.day = int.parse(json[KeepUpRecurrenceDataModelKey.day]);
        result.month = int.parse(json[KeepUpRecurrenceDataModelKey.month]);
        break;
      default:
    }

    return result;
  }

  void addException(
      {String? eventId, String? recurrenceId, required DateTime onDate}) {
    _exceptions.add(KeepUpRecurrenceException(
        eventId: eventId, recurrenceId: recurrenceId, onDate: onDate));
  }
}

class KeepUpRecurrenceException {
  final String? eventId;
  final String? recurrenceId;
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

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': '_User', 'objectId': objectId};
  }
}

abstract class KeepUpEventDataModelKey {
  static const className = 'Event';
  static const id = 'objectId';
  static const title = 'title';
  static const startDate = 'startDate';
  static const endDate = 'endDate';
  static const creatorId = 'creatorId';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpRecurrenceDataModelKey {
  static const className = 'Recurrence';
  static const id = 'objectId';
  static const eventId = 'eventId';
  static const description = 'description';
  static const startTime = 'startTime';
  static const endTime = 'endTime';
  static const type = 'type';
  static const day = 'day';
  static const month = 'month';
  static const year = 'year';
  static const weekDay = 'weekDay';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpExceptionDataModelKey {
  static const className = 'Exception';
  static const id = 'objectId';
  static const eventId = 'eventId';
  static const recurrenceId = 'recurrenceId';
  static const onDate = 'onDate';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

class KeepUpDayTime {
  final int hour, minute;

  KeepUpDayTime({required this.hour, required this.minute});

  KeepUpDayTime.fromDateTime(DateTime dateTime)
      : hour = dateTime.hour,
        minute = dateTime.minute;

  KeepUpDayTime.fromJson(Map<String, dynamic> json)
      : hour = json['hour'],
        minute = json['minute'];

  Map<String, dynamic> toJson() {
    return {'hour': hour, 'minute': minute};
  }

  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);

  int compareTo(KeepUpDayTime other) {
    if (hour < other.hour) return -1;
    if (hour > other.hour) return 1;
    if (minute < other.minute) return -1;
    if (minute > other.minute) return 1;
    return 0;
  }

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  bool operator ==(Object other) {
    return (other as KeepUpDayTime).hour == hour && other.minute == minute;
  }
}

class KeepUpTask {
  String title;
  KeepUpDayTime startTime, endTime;

  KeepUpTask(
      {required this.title, required this.startTime, required this.endTime});

  @override
  int get hashCode => Object.hash(title, startTime.hour, startTime.minute);

  @override
  bool operator ==(Object other) {
    return (other as KeepUpTask).title == title && other.startTime == startTime;
  }
}
