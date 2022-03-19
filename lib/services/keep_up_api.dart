import 'dart:collection';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:keep_up/constant.dart';
import 'package:keep_up/services/notification_service.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

class KeepUp {
  static const _keyApplicationId = '7lriFNc0muHJqnpBYmDJjkCdBP4ptEXEYaSiIZKR';
  static const _keyClientKey = 'Hboaa5QGH79mvRQQfEXCUcjXnZlrXSlZk0axzQri';
  static const _keyParseServerUrl = 'https://parseapi.back4app.com';
  static const _keyParseLocalServerUrl = 'http://192.168.1.227:1337/parse/';

  static final KeepUp _instance = KeepUp._();

  KeepUp._();

  static KeepUp get instance => _instance;

  Future<KeepUp> init() async {
    await Parse().initialize(_keyApplicationId, _keyParseLocalServerUrl,
        clientKey: _keyClientKey, autoSendSessionId: true, debug: true);
    return this;
  }

  Future<KeepUpResponse> register(
      String fullName, String email, String password) async {
    final user = ParseUser.createUser(email, password, email);

    user.set(KeepUpUserDataModel.fullName, fullName);
    user.set(KeepUpUserDataModel.notifySurveyTime, null);
    user.set(KeepUpUserDataModel.notifyTasks, false);

    final response = await user.signUp();

    if (response.success) {
      log('KeepUp: user registration success');
      return KeepUpResponse();
    } else {
      return KeepUpResponse.error(
          'KeepUp: user registration failure: ${response.error!.message}');
    }
  }

  Future<KeepUpResponse> login(String email, String password) async {
    final user = ParseUser(email, password, email);
    final response = await user.login();

    if (!response.success) {
      return KeepUpResponse.error(
          'KeepUp: user login failure: ${response.error!.message}');
    }

    log('KeepUp: user login success');

    // abilita tutte le notifiche al login
    _enableAllNotifications();

    return KeepUpResponse();
  }

  Future<KeepUpResponse> logout() async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    final response = await currentUser!.logout();

    if (!response.success) {
      return KeepUpResponse.error(
          'KeepUp: user logout failure: ${response.error!.message}');
    }

    log('KeepUp: user logout success');

    // se l'utente non è loggato, rimuove tutte le notifiche
    NotificationService().cancelAllNotifications();

    return KeepUpResponse();
  }

  Future<KeepUpResponse> deleteUser({required String reason}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser;
    // crea l'utente eliminato con informazioni
    final deletedUserInfo = ParseObject(KeepUpDeletedUserDataModel.className)
      ..set(KeepUpDeletedUserDataModel.email, currentUser.emailAddress!)
      ..set(KeepUpDeletedUserDataModel.fullName,
          currentUser.get(KeepUpUserDataModel.fullName))
      ..set(KeepUpDeletedUserDataModel.id, currentUser.objectId)
      ..set(KeepUpDeletedUserDataModel.reason, reason);
    final events = await getAllEvents();
    // elimina tutti gli eventi dell'utente e info annesse
    for (final event in events.result!) {
      deleteEvent(eventId: event.id!);
    }
    // query per cancellare il tracking di progressi
    final deleteTracesQuery =
        QueryBuilder.name(KeepUpDailyTraceDataModel.className)
          ..whereEqualTo(KeepUpDailyTraceDataModel.userId,
              KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // query per cancellare i thread creati dall'utente
    final deleteUserThreadsQuery =
        QueryBuilder.name(KeepUpThreadDataModel.className)
          ..whereEqualTo(KeepUpThreadDataModel.creatorId,
              KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // query per cancellare la partecipazione dell'utente
    final deleteUserThreadPartecipantQuery =
        QueryBuilder.name(KeepUpThreadPartecipantDataModel.className)
          ..whereEqualTo(KeepUpThreadPartecipantDataModel.userId,
              KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // query per cancellare le visualizzazioni di thread dell'utente
    final deleteUserThreadViewsQuery =
        QueryBuilder.name(KeepUpThreadViewDataModel.className)
          ..whereEqualTo(KeepUpThreadViewDataModel.userId,
              KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // query per cancellare i messaggi inviati dall'utente
    final deleteUserMessagesQuery =
        QueryBuilder.name(KeepUpThreadMessageDataModel.className)
          ..whereEqualTo(KeepUpThreadMessageDataModel.senderId,
              KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // query per cancellare i like dell'utente
    final deleteUserMessagesLikesQuery =
        QueryBuilder.name(KeepUpThreadMessageLikeDataModel.className)
          ..whereEqualTo(KeepUpThreadMessageLikeDataModel.userId,
              KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // esegue tutte le query
    deleteTracesQuery.find().then((objects) {
      for (var object in objects) {
        object.delete();
      }
    });

    deleteUserThreadsQuery.find().then((objects) {
      for (var object in objects) {
        object.delete();
      }
    });

    deleteUserThreadViewsQuery.find().then((objects) {
      for (var object in objects) {
        object.delete();
      }
    });

    deleteUserMessagesQuery.find().then((objects) {
      for (var object in objects) {
        object.delete();
      }
    });

    deleteUserMessagesLikesQuery.find().then((objects) {
      for (var object in objects) {
        object.delete();
      }
    });

    deleteUserThreadPartecipantQuery.find().then((objects) {
      for (var object in objects) {
        object.delete();
      }
    });
    // elimina l'account
    final response = await currentUser.delete();
    // salva l'account eliminato nell'altra tabella
    deletedUserInfo.save();

    if (!response.success) {
      return KeepUpResponse.error(
          'KeepUp: user delete failure: ${response.error!.message}');
    }

    log('KeepUp: user delete success');

    return KeepUpResponse();
  }

  Future<KeepUpResponse> changePassword(
      String oldPassword, String newPassword) async {
    // Controlla che ci sia un utente salvato in cache
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    if (currentUser == null) {
      return KeepUpResponse.error('KeepUp: no user logged in');
    }
    // Controlla che il token di sessione associato sia ancora valido
    final parseResponse =
        await ParseUser.getCurrentUserFromServer(currentUser.sessionToken!);
    if (parseResponse?.success == null || !parseResponse!.success) {
      await currentUser.logout();
      return KeepUpResponse.error('KeepUp: no user logged in');
    }
    // effettua login per verificare che la vecchia password sia corretta
    final loginResponse = await ParseUser(
            currentUser.emailAddress, oldPassword, currentUser.emailAddress)
        .login();

    if (!loginResponse.success) {
      return KeepUpResponse.error(
          'KeepUp: user login failure: ${loginResponse.error!.message}');
    }
    // setta la nuova password
    currentUser.password = newPassword;
    // salva la nuova password
    final updateResponse = await currentUser.save();

    if (!updateResponse.success) {
      return KeepUpResponse.error(
          'KeepUp: user update failure: ${updateResponse.error!.message}');
    }
    // effettua nuovamente il login, altrimenti sembra causare sessione invalida
    final newLoginResponse = await ParseUser(
            currentUser.emailAddress, newPassword, currentUser.emailAddress)
        .login();

    if (!newLoginResponse.success) {
      return KeepUpResponse.error(
          'KeepUp: user login failure: ${loginResponse.error!.message}');
    }

    return KeepUpResponse();
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
      return KeepUpUser(
        currentUser.get(KeepUpUserDataModel.fullName),
        currentUser.emailAddress!,
        currentUser.sessionToken!,
        currentUser.get(KeepUpUserDataModel.notifySurveyTime) != null
            ? KeepUpDayTime.fromJson(
                currentUser.get(KeepUpUserDataModel.notifySurveyTime))
            : null,
        currentUser.get(KeepUpUserDataModel.notifyTasks),
      );
    }
  }

  Future<KeepUpResponse> updateUser(KeepUpUser updatedUser) async {
    // Controlla che ci sia un utente salvato in cache
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    if (currentUser == null) {
      return KeepUpResponse.error('no user logged in');
    }
    // Controlla che il token di sessione associato sia ancora valido
    final parseResponse =
        await ParseUser.getCurrentUserFromServer(currentUser.sessionToken!);
    if (parseResponse?.success == null || !parseResponse!.success) {
      await currentUser.logout();
      return KeepUpResponse.error('no user logged in');
    } else {
      final oldNotifySurveyTime =
          currentUser.get(KeepUpUserDataModel.notifySurveyTime);
      final oldNotifyTasks = currentUser.get(KeepUpUserDataModel.notifyTasks);
      // setta i nuovi valori
      currentUser.set(KeepUpUserDataModel.fullName, updatedUser.fullname);
      currentUser.set(
          KeepUpUserDataModel.notifySurveyTime, updatedUser.notifySurveyTime);
      currentUser.set(KeepUpUserDataModel.notifyTasks, updatedUser.notifyTasks);
      // salva l'utente
      final response = await currentUser.save();
      if (!response.success) {
        return KeepUpResponse.error(
            'user update failure: ${response.error!.message}');
      }
      // programma le notifiche
      if (updatedUser.notifySurveyTime != null) {
        _enableSurveyNotification(time: updatedUser.notifySurveyTime!);
      }
      // elimina le notifiche
      else {
        _cancelSurveyNotification();
      }
      // programma le notifiche per le attività
      if (updatedUser.notifyTasks) {
        _enableTasksNotification();
      }
      // elimina le notifiche per le attività
      else {
        _cancelTasksNotification();
      }

      return KeepUpResponse();
    }
  }

  Future _enableAllNotifications() async {
    final currentUser = await getUser() as KeepUpUser;

    // abilita le notifiche sui task quotidiani
    if (currentUser.notifyTasks) {
      await _enableTasksNotification();
    }

    // abilita le notifiche sul survey
    if (currentUser.notifySurveyTime != null) {
      await _enableSurveyNotification(time: currentUser.notifySurveyTime!);
    }

    // abilita le notifiche sul completamento dei goal
    await enableGoalsCompletionNotification();
  }

  Future _enableSurveyNotification({required KeepUpDayTime time}) async {
    NotificationService().scheduleDailyNotification(
        id: NotificationServiceConstant.dailySurveyId,
        hour: time.hour,
        minute: time.minute,
        title: 'Ehi, come va?',
        body: 'Raccontami come è andata la tua giornata!',
        payload: NotificationServiceConstant.surveyPayload);
  }

  Future _cancelSurveyNotification() async {
    NotificationService()
        .cancelNotification(id: NotificationServiceConstant.dailySurveyId);
  }

  Future _enableTasksNotification() async {
    var now = DateTime.now().getDateOnly();

    for (int i = 0; i < 7; ++i, now = now.add(const Duration(days: 1))) {
      final response = await getTasks(inDate: now);

      if (response.error) continue;

      for (final task in response.result!) {
        if (task.recurrenceType == KeepUpRecurrenceType.none) {
          NotificationService().scheduleDayNotification(
              id: task.recurrenceId.hashCode + 7,
              hour: task.startTime.hour,
              minute: task.startTime.minute,
              date: task.date.toLocal(),
              title: task.title,
              body:
                  'Hai questa attività in programma alle ${task.startTime.toString()}.',
              payload: NotificationServiceConstant.taskPayload);
        } else if (task.recurrenceType == KeepUpRecurrenceType.weekly) {
          NotificationService().scheduleWeekDayNotification(
              id: task.recurrenceId.hashCode + 7,
              hour: task.startTime.hour,
              minute: task.startTime.minute,
              weekDay: task.date.weekday,
              title: task.title,
              body:
                  'Hai questa attività in programma alle ${task.startTime.toString()}.',
              payload: NotificationServiceConstant.taskPayload);
        } else if (task.recurrenceType == KeepUpRecurrenceType.daily) {
          NotificationService().scheduleDailyNotification(
              id: task.recurrenceId.hashCode + 7,
              hour: task.startTime.hour,
              minute: task.startTime.minute,
              title: task.title,
              body:
                  'Hai questa attività in programma alle ${task.startTime.toString()}.',
              payload: NotificationServiceConstant.taskPayload);
        }
      }
    }
  }

  Future enableGoalsCompletionNotification() async {
    final response = await getAllGoals();

    if (response.error) return response;
    // la notifica di raggiungimento di un obiettivo è settata alle 20:00
    for (final goal in response.result!) {
      if (goal.endDate != null) {
        final scheduleTime = goal.endDate!.getDateOnly();
        NotificationService().scheduleDayNotification(
            id: goal.metadataId.hashCode + 7,
            hour: 20,
            minute: 10,
            date: scheduleTime.toLocal(),
            title: goal.title,
            body: 'Hai completato il tuo obiettivo ${goal.title}!',
            payload: NotificationServiceConstant.composeGoalCompletionPayload(
                goal.metadataId!));
      }
    }

    return KeepUpResponse();
  }

  Future _cancelTasksNotification() async {
    final query = QueryBuilder.name(KeepUpRecurrenceDataModel.className);
    final recurrences = await query.find();

    for (final recurrence in recurrences) {
      NotificationService()
          .cancelNotification(id: recurrence.objectId.hashCode + 7);
    }
  }

  Future _cancelTaskNotification(KeepUpTask task) async {
    NotificationService()
        .cancelNotification(id: task.recurrenceId.hashCode + 7);
  }

  Future<bool> _eventAlreadyExists(String eventName) async {
    final query = QueryBuilder.name(KeepUpEventDataModel.className);
    query.whereEqualTo(KeepUpEventDataModel.title, eventName);
    final response = await query.count();
    return response.count > 0;
  }

  /// crea un nuovo evento da zero
  Future<KeepUpResponse> createEvent(KeepUpEvent event) async {
    final isDuplicated = await _eventAlreadyExists(event.title);

    if (isDuplicated) {
      return KeepUpResponse.error(
          'KeepUp: event creation failure: duplicated event name');
    }

    final currentUser = await ParseUser.currentUser() as ParseUser?;

    final eventObject = ParseObject(KeepUpEventDataModel.className)
      ..set(KeepUpEventDataModel.title, event.title)
      ..set(KeepUpEventDataModel.startDate, event.startDate.getDateOnly())
      ..set(KeepUpEventDataModel.endDate, event.endDate?.getDateOnly())
      ..set(KeepUpEventDataModel.description, event.description)
      ..set(KeepUpEventDataModel.color, event.color.value)
      ..set(KeepUpEventDataModel.category, event.category)
      ..set(KeepUpEventDataModel.creatorId, currentUser!.toPointer());

    final response = await eventObject.save();

    if (!response.success) {
      return KeepUpResponse.error(
          'KeepUp: event creation failure: ${response.error!.message}');
    }

    event.id = eventObject.objectId;

    log('KeepUp: event creation success ${eventObject.objectId}');

    for (final recurrence in event.recurrences) {
      final recurrenceObject = ParseObject(KeepUpRecurrenceDataModel.className)
        ..set(KeepUpRecurrenceDataModel.eventId, eventObject.toPointer())
        ..set(KeepUpRecurrenceDataModel.startTime, recurrence.startTime)
        ..set(KeepUpRecurrenceDataModel.endTime, recurrence.endTime)
        ..set(KeepUpRecurrenceDataModel.type, recurrence.type.index);

      switch (recurrence.type) {
        case KeepUpRecurrenceType.none:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModel.day, recurrence.day.toString())
            ..set(KeepUpRecurrenceDataModel.month, recurrence.month.toString())
            ..set(KeepUpRecurrenceDataModel.year, recurrence.year.toString())
            ..set(KeepUpRecurrenceDataModel.weekDay,
                recurrence.weekDay.toString());
          break;
        case KeepUpRecurrenceType.daily:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModel.day, '*')
            ..set(KeepUpRecurrenceDataModel.month, '*')
            ..set(KeepUpRecurrenceDataModel.year, '*')
            ..set(KeepUpRecurrenceDataModel.weekDay, '*');
          break;
        case KeepUpRecurrenceType.weekly:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModel.day, null)
            ..set(KeepUpRecurrenceDataModel.month, '*')
            ..set(KeepUpRecurrenceDataModel.year, '*')
            ..set(KeepUpRecurrenceDataModel.weekDay,
                recurrence.weekDay.toString());
          break;
        case KeepUpRecurrenceType.monthly:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModel.day, recurrence.day.toString())
            ..set(KeepUpRecurrenceDataModel.month, recurrence.month.toString())
            ..set(KeepUpRecurrenceDataModel.year, '*')
            ..set(KeepUpRecurrenceDataModel.weekDay, null);
          break;
        default:
      }

      final response = await recurrenceObject.save();

      if (!response.success) {
        return KeepUpResponse.error(
            'KeepUp: recurrence creation failure: ${response.error!.message}');
      }

      recurrence.id = recurrenceObject.objectId;
      recurrence.eventId = eventObject.objectId;

      log('KeepUp: recurrence creation success');

      for (final exception in recurrence.exceptions) {
        final exceptionObject = ParseObject(KeepUpExceptionDataModel.className)
          ..set(KeepUpExceptionDataModel.eventId, eventObject.toPointer())
          ..set(KeepUpExceptionDataModel.recurrenceId,
              recurrenceObject.toPointer())
          ..set(KeepUpExceptionDataModel.onDate, exception.onDate);

        final response = await exceptionObject.save();

        if (!response.success) {
          return KeepUpResponse.error(
              'KeepUp: exception creation failure: ${response.error!.message}');
        } else {
          log('KeepUp: exception creation success');
        }

        exception.id = exceptionObject.objectId;
        exception.eventId = eventObject.objectId;
        exception.recurrenceId = recurrenceObject.objectId;
      }
    }

    return KeepUpResponse();
  }

  /// aggiorna un evento nel database
  Future<KeepUpResponse> updateEvent(KeepUpEvent event) async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;

    final eventObject = ParseObject(KeepUpEventDataModel.className)
      ..objectId = event.id
      ..set(KeepUpEventDataModel.title, event.title)
      ..set(KeepUpEventDataModel.startDate, event.startDate.getDateOnly())
      ..set(KeepUpEventDataModel.endDate, event.endDate?.getDateOnly())
      ..set(KeepUpEventDataModel.description, event.description)
      ..set(KeepUpEventDataModel.color, event.color.value)
      ..set(KeepUpEventDataModel.category, event.category)
      ..set(KeepUpEventDataModel.creatorId, currentUser!.toPointer());

    final response = await eventObject.save();

    if (!response.success) {
      return KeepUpResponse.error(
          'KeepUp: event updaye failure: ${response.error!.message}');
    }

    log('KeepUp: event update success ${eventObject.objectId}');

    for (final recurrence in event.recurrences) {
      final recurrenceObject = ParseObject(KeepUpRecurrenceDataModel.className)
        ..set(KeepUpRecurrenceDataModel.eventId, eventObject.toPointer())
        ..set(KeepUpRecurrenceDataModel.startTime, recurrence.startTime)
        ..set(KeepUpRecurrenceDataModel.endTime, recurrence.endTime)
        ..set(KeepUpRecurrenceDataModel.type, recurrence.type.index);

      if (recurrence.id != null) recurrenceObject.objectId = recurrence.id;

      switch (recurrence.type) {
        case KeepUpRecurrenceType.none:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModel.day, recurrence.day.toString())
            ..set(KeepUpRecurrenceDataModel.month, recurrence.month.toString())
            ..set(KeepUpRecurrenceDataModel.year, recurrence.year.toString())
            ..set(KeepUpRecurrenceDataModel.weekDay,
                recurrence.weekDay.toString());
          break;
        case KeepUpRecurrenceType.daily:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModel.day, '*')
            ..set(KeepUpRecurrenceDataModel.month, '*')
            ..set(KeepUpRecurrenceDataModel.year, '*')
            ..set(KeepUpRecurrenceDataModel.weekDay, '*');
          break;
        case KeepUpRecurrenceType.weekly:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModel.day, null)
            ..set(KeepUpRecurrenceDataModel.month, '*')
            ..set(KeepUpRecurrenceDataModel.year, '*')
            ..set(KeepUpRecurrenceDataModel.weekDay,
                recurrence.weekDay.toString());
          break;
        case KeepUpRecurrenceType.monthly:
          recurrenceObject
            ..set(KeepUpRecurrenceDataModel.day, recurrence.day.toString())
            ..set(KeepUpRecurrenceDataModel.month, recurrence.month.toString())
            ..set(KeepUpRecurrenceDataModel.year, '*')
            ..set(KeepUpRecurrenceDataModel.weekDay, null);
          break;
        default:
      }

      final response = await recurrenceObject.save();

      if (!response.success) {
        return KeepUpResponse.error(
            'KeepUp: recurrence update failure: ${response.error!.message}');
      }

      log('KeepUp: recurrence update success');

      for (final exception in recurrence.exceptions) {
        final exceptionObject = ParseObject(KeepUpExceptionDataModel.className)
          ..set(KeepUpExceptionDataModel.eventId, eventObject.toPointer())
          ..set(KeepUpExceptionDataModel.recurrenceId,
              recurrenceObject.toPointer())
          ..set(KeepUpExceptionDataModel.onDate, exception.onDate);

        if (exception.id != null) exceptionObject.objectId = exception.id;

        final response = await exceptionObject.save();

        if (!response.success) {
          return KeepUpResponse.error(
              'KeepUp: exception creation failure: ${response.error!.message}');
        } else {
          log('KeepUp: exception creation success');
        }
      }
    }

    return KeepUpResponse();
  }

  /// legge tutti gli eventi dell'utente dal database
  Future<KeepUpResponse<List<KeepUpEvent>>> getAllEvents(
      {bool getMetadata = false}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser;
    // query per verificare appartenenza all'utente loggato
    final isUserEventQuery = QueryBuilder.name(KeepUpEventDataModel.className)
      ..whereEqualTo(KeepUpEventDataModel.creatorId,
          KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // costruisce la query per ottenere l'evento
    final mainQuery = QueryBuilder.name(KeepUpEventDataModel.className)
      ..whereEqualTo(KeepUpEventDataModel.creatorId,
          KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // costruisce la lista delle ricorrenze
    final recurrencesQuery = QueryBuilder.name(
        KeepUpRecurrenceDataModel.className)
      ..whereMatchesQuery(KeepUpRecurrenceDataModel.eventId, isUserEventQuery);
    // costruisce la lista delle eccezioni alle ricorrenze
    final exceptionsQuery = QueryBuilder.name(
        KeepUpExceptionDataModel.className)
      // seleziona solo le eccezioni di ricorrenze del'utente loggato
      ..whereMatchesQuery(KeepUpExceptionDataModel.eventId, isUserEventQuery);

    // effettua le query
    final events = (await mainQuery.find()).map((e) => KeepUpEvent.fromJson(e));

    if (!getMetadata) {
      return KeepUpResponse.result(
          events.toList()..sort((a, b) => a.title.compareTo(b.title)));
    }

    final recurrences = (await recurrencesQuery.find())
        .map((e) => KeepUpRecurrence.fromJson(e));
    final exceptions = (await exceptionsQuery.find())
        .map((e) => KeepUpRecurrenceException.fromJson(e));
    final eventMap = HashMap<String, KeepUpEvent>();
    final recurrenceMap = HashMap<String, KeepUpRecurrence>();

    for (final event in events) {
      eventMap.putIfAbsent(event.id!, () => event);
    }

    for (final recurrence in recurrences) {
      recurrenceMap.putIfAbsent(recurrence.id!, () => recurrence);
    }

    for (final exception in exceptions) {
      recurrenceMap.update(exception.recurrenceId!, (value) {
        value.exceptions.add(exception);
        return value;
      });
    }

    for (final recurrence in recurrenceMap.entries) {
      eventMap.update(recurrence.value.eventId!, (value) {
        value.recurrences.add(recurrence.value);
        return value;
      });
    }

    return KeepUpResponse.result(
        eventMap.values.toList()..sort((a, b) => a.title.compareTo(b.title)));
  }

  /// legge un evento con tutte le ricorrenze relative dal database
  Future<KeepUpResponse<KeepUpEvent>> getEvent(
      {required String eventId}) async {
    // costruisce la query per ottenere l'evento
    final mainQuery = QueryBuilder.name(KeepUpEventDataModel.className)
      ..whereEqualTo(KeepUpEventDataModel.id, eventId);
    // costruisce la lista delle ricorrenze
    final recurrencesQuery =
        QueryBuilder.name(KeepUpRecurrenceDataModel.className)
          ..whereEqualTo(KeepUpRecurrenceDataModel.eventId,
              KeepUpEventDataModel.pointerTo(eventId));
    // costruisce la lista delle eccezioni alle ricorrenze
    final exceptionsQuery =
        QueryBuilder.name(KeepUpExceptionDataModel.className)
          ..whereEqualTo(KeepUpExceptionDataModel.eventId,
              KeepUpEventDataModel.pointerTo(eventId));

    // effettua le query
    final eventObjects = await mainQuery.find();
    final recurrenceObjects = await recurrencesQuery.find();
    final exceptionObjects = await exceptionsQuery.find();

    if (eventObjects.isEmpty) {
      return KeepUpResponse.error('KeepUp: no event found with such id');
    }

    final event = KeepUpEvent.fromJson(eventObjects.first);
    final recurrencesMap = HashMap<String, KeepUpRecurrence>();

    for (final recurrenceObject in recurrenceObjects) {
      final recurrence = KeepUpRecurrence.fromJson(recurrenceObject);
      recurrencesMap.putIfAbsent(recurrence.id!, () => recurrence);
    }

    for (final exceptionObject in exceptionObjects) {
      final exception = KeepUpRecurrenceException.fromJson(exceptionObject);
      recurrencesMap.update(exception.recurrenceId!, (value) {
        value.exceptions.add(exception);
        return value;
      });
    }

    for (final recurrence in recurrencesMap.values) {
      event.recurrences.add(recurrence);
    }

    return KeepUpResponse.result(event);
  }

  /// crea un nuovo evento goal da zero
  Future<KeepUpResponse> createGoal(KeepUpGoal goal) async {
    // prima si assicura che la creazione dell'evento avvenga senza problemi
    final response = await createEvent(goal);

    if (response.error) return response;

    // crea i metadati
    final goalMetadata = ParseObject(KeepUpGoalDataModel.className)
      ..set(
          KeepUpGoalDataModel.eventId, KeepUpEventDataModel.pointerTo(goal.id!))
      ..set(KeepUpGoalDataModel.daysPerWeek, goal.daysPerWeek)
      ..set(KeepUpGoalDataModel.hoursPerDay, goal.hoursPerDay)
      ..set(KeepUpGoalDataModel.rating, goal.rating)
      ..set(KeepUpGoalDataModel.ratingsCount, goal.ratingsCount)
      ..set(KeepUpGoalDataModel.completionDate, null);

    // salva i metadati
    final parseResponse = await goalMetadata.save();

    if (!parseResponse.success) {
      return KeepUpResponse.error(
          'KeepUp: goal creation failure: ${parseResponse.error!.message}');
    }

    return KeepUpResponse();
  }

  /// aggiorno un evento goal
  Future<KeepUpResponse> updateGoal(KeepUpGoal goal) async {
    // prima si assicura che la creazione dell'evento avvenga senza problemi
    final response = await updateEvent(goal);

    if (response.error) return response;

    // aggiorna i metadati
    final goalMetadata = ParseObject(KeepUpGoalDataModel.className)
      ..objectId = goal.metadataId
      ..set(
          KeepUpGoalDataModel.eventId, KeepUpEventDataModel.pointerTo(goal.id!))
      ..set(KeepUpGoalDataModel.daysPerWeek, goal.daysPerWeek)
      ..set(KeepUpGoalDataModel.hoursPerDay, goal.hoursPerDay)
      ..set(KeepUpGoalDataModel.rating, goal.rating)
      ..set(KeepUpGoalDataModel.ratingsCount, goal.ratingsCount)
      ..set(KeepUpGoalDataModel.completionDate, goal.completionDate);

    // salva i metadati
    final parseResponse = await goalMetadata.save();

    if (!parseResponse.success) {
      return KeepUpResponse.error(
          'KeepUp: goal update failure: ${parseResponse.error!.message}');
    }

    return KeepUpResponse();
  }

  /// setta la data di completamento del goal
  Future<KeepUpResponse> setGoalCompletion(
      {required String goalMetadataId, required DateTime date}) async {
    // aggiorna i metadati
    final goalMetadata = ParseObject(KeepUpGoalDataModel.className)
      ..objectId = goalMetadataId
      ..set(KeepUpGoalDataModel.completionDate, date);

    // salva i metadati
    final parseResponse = await goalMetadata.save();

    if (!parseResponse.success) {
      return KeepUpResponse.error(
          'KeepUp: goal update failure: ${parseResponse.error!.message}');
    }

    // elimina la notifica
    NotificationService().cancelNotification(id: goalMetadataId.hashCode + 7);

    return KeepUpResponse();
  }

  /// legge tutti i goal (eventi estesi) dal database
  Future<KeepUpResponse<List<KeepUpGoal>>> getAllGoals(
      {bool getMetadata = false}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser;
    // query per verificare appartenenza all'utente loggato
    final isUserEventQuery = QueryBuilder.name(KeepUpEventDataModel.className)
      ..whereEqualTo(KeepUpEventDataModel.creatorId,
          KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // costruisce la query per ottenere i goal
    final goalQuery = QueryBuilder.name(KeepUpGoalDataModel.className)
      ..whereMatchesQuery(KeepUpGoalDataModel.eventId, isUserEventQuery);
    // ottiene i metadata sui goal
    final goalObjects = await goalQuery.find();

    if (goalObjects.isEmpty) return KeepUpResponse.result([]);

    goalObjects.sort((a, b) {
      return (a[KeepUpGoalDataModel.eventId][KeepUpEventDataModel.id] as String)
          .compareTo(b[KeepUpGoalDataModel.eventId][KeepUpEventDataModel.id]
              as String);
    });

    // ora ottiene tutti gli eventi per poi effettuare il merge estraendo
    // solo i goal
    final response = await getAllEvents(getMetadata: getMetadata);

    if (response.error || response.result == null) {
      return KeepUpResponse.error('KeepUp: unable to get events');
    }

    final events = response.result!;

    events.sort((a, b) {
      return a.id!.compareTo(b.id!);
    });

    final result = <KeepUpGoal>[];
    int i = 0;

    // effettua il merge per estrarre i eventi che sono goal
    for (final event in events) {
      if (i >= goalObjects.length) break;
      if (event.id ==
          goalObjects[i][KeepUpGoalDataModel.eventId]
              [KeepUpEventDataModel.id]) {
        result.add(KeepUpGoal(
            id: event.id,
            title: event.title,
            description: event.description,
            startDate: event.startDate,
            endDate: event.endDate,
            color: event.color,
            category: event.category,
            daysPerWeek: goalObjects[i][KeepUpGoalDataModel.daysPerWeek],
            hoursPerDay: goalObjects[i][KeepUpGoalDataModel.hoursPerDay],
            rating: goalObjects[i][KeepUpGoalDataModel.rating],
            ratingsCount: goalObjects[i][KeepUpGoalDataModel.ratingsCount],
            completionDate: goalObjects[i][KeepUpGoalDataModel.completionDate],
            metadataId: goalObjects[i][KeepUpGoalDataModel.id]));
        result.last.recurrences = event.recurrences;
        ++i;
      }
    }

    result.sort((a, b) {
      if (a.completionDate == null && b.completionDate != null) return -1;
      if (a.completionDate != null && b.completionDate == null) return 1;
      if (a.completionDate != null && b.completionDate != null) {
        return a.completionDate!.compareTo(b.completionDate!);
      }
      if (a.endDate != null && b.endDate != null) {
        return a.endDate!.compareTo(b.endDate!);
      }
      return -1;
    });

    return KeepUpResponse.result(result);
  }

  /// ottiene tutti i goal non ancora pianificati
  Future<KeepUpResponse<List<KeepUpGoal>>> getAllUnscheduledGoals() async {
    // ottiene tutti i goal
    final response = await getAllGoals(getMetadata: true);

    if (response.error) return response;

    // filtra eliminando tutti gli obiettivi già pianificati
    final goals = response.result!.where((goal) {
      return goal.recurrences.isEmpty &&
          (goal.endDate == null ||
              goal.endDate!
                      .getDateOnly()
                      .compareTo(DateTime.now().getDateOnly()) >
                  0);
    }).toList();

    return KeepUpResponse.result(goals);
  }

  /// legge un obiettivo (evento esteso) dal database
  Future<KeepUpResponse<KeepUpGoal>> getGoal({required String eventId}) async {
    // effettua la query sull'evento associato
    final response = await getEvent(eventId: eventId);
    // costruisce la query per estrarre i metadati dell'obiettivo
    final goalQuery = QueryBuilder.name(KeepUpGoalDataModel.className)
      ..whereEqualTo(
          KeepUpGoalDataModel.eventId, KeepUpEventDataModel.pointerTo(eventId));

    final goalObjects = await goalQuery.find();

    if (goalObjects.isEmpty || response.error || response.result == null) {
      return KeepUpResponse.error('KeepUp: no event found with such id');
    }

    final result = KeepUpGoal(
        id: response.result!.id,
        title: response.result!.title,
        description: response.result!.description,
        startDate: response.result!.startDate,
        endDate: response.result!.endDate,
        color: response.result!.color,
        category: response.result!.category,
        daysPerWeek: goalObjects.first[KeepUpGoalDataModel.daysPerWeek],
        hoursPerDay: goalObjects.first[KeepUpGoalDataModel.hoursPerDay],
        rating: goalObjects.first[KeepUpGoalDataModel.rating],
        ratingsCount: goalObjects.first[KeepUpGoalDataModel.ratingsCount],
        completionDate: goalObjects.first[KeepUpGoalDataModel.completionDate],
        metadataId: goalObjects.first[KeepUpGoalDataModel.id]);

    result.recurrences = response.result!.recurrences;

    return KeepUpResponse.result(result);
  }

  /// elimina un task, il che significa che cancella l'entry della sua ricorrenza
  Future<KeepUpResponse> cancelTask({required KeepUpTask task}) async {
    final target = ParseObject(KeepUpRecurrenceDataModel.className)
      ..objectId = task.recurrenceId;
    final response = await target.delete();

    // elimina qualunque eccezione presente oggi se il task era solo per oggi
    if (task.recurrenceType == KeepUpRecurrenceType.none) {
      final cancelExceptionQuery =
          QueryBuilder.name(KeepUpExceptionDataModel.className)
            ..whereEqualTo(KeepUpExceptionDataModel.eventId,
                KeepUpEventDataModel.pointerTo(task.eventId))
            ..whereEqualTo(
                KeepUpExceptionDataModel.onDate, task.date.getDateOnly());

      final results = await cancelExceptionQuery.find();

      for (final exceptionEntry in results) {
        exceptionEntry.delete();
      }
    }

    // elimina la notifica associata in ogni caso
    _cancelTaskNotification(task);

    if (response.success) {
      return KeepUpResponse();
    } else {
      return KeepUpResponse.error(
          'KeepUp: task cancel failure: ${response.error!.message}');
    }
  }

  /// elimina un evento dal database, anche se goal
  Future<KeepUpResponse> deleteEvent({required String eventId}) async {
    // costruisce la query per eliminare le ricorrenze associate
    final deleteRecurrencesQuery =
        QueryBuilder.name(KeepUpRecurrenceDataModel.className)
          ..whereEqualTo(KeepUpRecurrenceDataModel.eventId,
              KeepUpEventDataModel.pointerTo(eventId));
    // costruisce la query per eliminare le eccezioni associate
    final deleteExceptionsQuery =
        QueryBuilder.name(KeepUpExceptionDataModel.className)
          ..whereEqualTo(KeepUpExceptionDataModel.eventId,
              KeepUpEventDataModel.pointerTo(eventId));
    // costruisce la query per eliminare il goal associato, se presente
    final deleteGoalQuery = QueryBuilder.name(KeepUpGoalDataModel.className)
      ..whereEqualTo(
          KeepUpGoalDataModel.eventId, KeepUpEventDataModel.pointerTo(eventId));
    // costruisce la query per eliminare l'evento
    final target = ParseObject(KeepUpEventDataModel.className)
      ..objectId = eventId;

    deleteRecurrencesQuery.find().then((objects) {
      for (var object in objects) {
        object.delete();
      }
    });

    await deleteExceptionsQuery.find().then((objects) {
      for (var object in objects) {
        object.delete();
      }
    });

    await deleteGoalQuery.find().then((objects) {
      for (var object in objects) {
        object.delete();
      }
    });

    final response = await target.delete();

    if (response.success) {
      return KeepUpResponse();
    } else {
      return KeepUpResponse.error(
          'KeepUp: event deletetion failure: ${response.error!.message}');
    }
  }

  /// il risultato è restituito come List<KeepUpTask> all'interno del campo
  /// 'response' della KeepUpResponse
  Future<KeepUpResponse<List<KeepUpTask>>> getTasks(
      {required DateTime inDate}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    // costruisce la lista di eventi appartenenti all'utente
    final isUserEventQuery = QueryBuilder.name(KeepUpEventDataModel.className)
      ..whereEqualTo(KeepUpEventDataModel.creatorId,
          KeepUpUserDataModel.pointerTo(currentUser!.objectId!));
    // questa query restituisce le eccezioni in tale data da escludere
    final exceptionsQuery = QueryBuilder.name(
        KeepUpExceptionDataModel.className)
      ..whereEqualTo(KeepUpExceptionDataModel.onDate, inDate.getDateOnly())
      // seleziona solo le eccezioni di ricorrenze del'utente loggato
      ..whereMatchesQuery(KeepUpExceptionDataModel.eventId, isUserEventQuery);
    // effettua le query
    final exceptionObjects = await exceptionsQuery.find();
    // questa query restituisce gli eventi dell'utente in data
    final eventsQuery = QueryBuilder.name(KeepUpEventDataModel.className)
      // seleziona solo le eccezioni di ricorrenze del'utente loggato
      ..whereEqualTo(KeepUpEventDataModel.creatorId,
          KeepUpUserDataModel.pointerTo(currentUser.objectId!))
      // filtra le date
      ..whereLessThanOrEqualTo(
          KeepUpEventDataModel.startDate, inDate.getDateOnly());
    // effettua la query
    final eventsObjects = await eventsQuery.find();
    // costruisce la query principale
    final mainQuery = QueryBuilder.name(KeepUpRecurrenceDataModel.className)
      // seleziona le colonne relative al nome evento, ora fine e ora inizio
      ..includeObject(
          [KeepUpEventDataModel.className, KeepUpExceptionDataModel.className])
      // seleziona le ricorrenze degli eventi dell'utente loggato
      ..whereContainedIn(KeepUpRecurrenceDataModel.eventId,
          eventsObjects.map((e) => e[KeepUpEventDataModel.id]).toList())
      // scarta le eccezioni in quella data
      ..whereNotContainedIn(
          KeepUpRecurrenceDataModel.id,
          exceptionObjects
              .map((e) => e[KeepUpExceptionDataModel.recurrenceId]
                  [KeepUpRecurrenceDataModel.id])
              .toList());

    // effettua la query principale
    final recurrenceObjects = await mainQuery.find();

    if (recurrenceObjects.isEmpty) {
      KeepUpResponse.result(List<KeepUpTask>.empty());
    }

    // filtra le occorrenze
    final tasks = recurrenceObjects
        .where((recurrenceObject) {
          final endEventDate = eventsObjects.firstWhere((eventObject) {
            return eventObject[KeepUpEventDataModel.id] ==
                recurrenceObject[KeepUpRecurrenceDataModel.eventId]
                    [KeepUpEventDataModel.id];
          })[KeepUpEventDataModel.endDate];

          return (endEventDate != null
                  ? inDate.compareTo(endEventDate as DateTime) <= 0
                  : true) &&
              (recurrenceObject[KeepUpRecurrenceDataModel.day] == '*' ||
                  recurrenceObject[KeepUpRecurrenceDataModel.day] ==
                      inDate.day.toString() ||
                  recurrenceObject[KeepUpRecurrenceDataModel.weekDay] == '*' ||
                  recurrenceObject[KeepUpRecurrenceDataModel.weekDay] ==
                      inDate.weekday.toString()) &&
              (recurrenceObject[KeepUpRecurrenceDataModel.month] == '*' ||
                  recurrenceObject[KeepUpRecurrenceDataModel.month] ==
                      inDate.month.toString()) &&
              (recurrenceObject[KeepUpRecurrenceDataModel.year] == '*' ||
                  recurrenceObject[KeepUpRecurrenceDataModel.year] ==
                      inDate.year.toString());
        })
        .map((recurrenceObject) {
          final associatedEvent = eventsObjects.firstWhere((eventObject) {
            return eventObject[KeepUpEventDataModel.id] ==
                recurrenceObject[KeepUpRecurrenceDataModel.eventId]
                    [KeepUpEventDataModel.id];
          });
          return KeepUpTask(
              eventId: recurrenceObject[KeepUpRecurrenceDataModel.eventId]
                  [KeepUpEventDataModel.id],
              recurrenceId: recurrenceObject[KeepUpRecurrenceDataModel.id],
              color: Color(associatedEvent[KeepUpEventDataModel.color]),
              title: associatedEvent[KeepUpEventDataModel.title],
              date: inDate,
              startTime: KeepUpDayTime.fromJson(
                  recurrenceObject[KeepUpRecurrenceDataModel.startTime]),
              endTime: KeepUpDayTime.fromJson(
                  recurrenceObject[KeepUpRecurrenceDataModel.endTime]),
              recurrenceType: KeepUpRecurrenceType
                  .values[recurrenceObject[KeepUpRecurrenceDataModel.type]]);
        })
        .toSet()
        .toList();

    tasks.sort((a, b) => a.startTime.compareTo(b.startTime));

    // ottiene le statistiche sugli oggetti dall'inizio della settimana
    // FIXME: algoritmo parecchio lento, forse conviene sistemare lo schema
    final weekStart = inDate.subtract(Duration(days: inDate.weekday - 1));
    final weekTraces = await getDailyTraces(from: weekStart, until: inDate);
    final recurrenceToEventMap = <String, String>{};
    final completedEventTasksMap = <String, int>{};

    if (!weekTraces.error) {
      // ora costruisce le statistiche da tutte le tracce giornaliere
      for (final trace in weekTraces.result!) {
        for (final recurrenceId in trace.completedTasks) {
          if (recurrenceToEventMap.containsKey(recurrenceId)) {
            completedEventTasksMap.update(recurrenceToEventMap[recurrenceId]!,
                (value) {
              return ++value;
            });
          } else {
            final query = QueryBuilder.name(KeepUpRecurrenceDataModel.className)
              ..whereEqualTo(KeepUpRecurrenceDataModel.id, recurrenceId);
            final result = await query.find();
            if (result.isNotEmpty) {
              final eventId = result.first[KeepUpRecurrenceDataModel.eventId]
                  [KeepUpEventDataModel.id];
              recurrenceToEventMap.putIfAbsent(recurrenceId, () => eventId);
              if (completedEventTasksMap.containsKey(eventId)) {
                completedEventTasksMap.update(eventId, (value) => ++value);
              } else {
                completedEventTasksMap.putIfAbsent(eventId, () => 1);
              }
            }
          }
        }
      }
      // ora preleva il numero di occorrenze settimanali per goal
      for (final task in tasks) {
        final isGoalQuery = QueryBuilder.name(KeepUpGoalDataModel.className)
          ..whereEqualTo(KeepUpGoalDataModel.eventId,
              KeepUpEventDataModel.pointerTo(task.eventId));
        final result = await isGoalQuery.find();
        // aggiorna l'evento associato al task e scrive la statistica
        if (result.isNotEmpty) {
          task.totalWeeklyCount = result.first[KeepUpGoalDataModel.daysPerWeek];
          task.completedWeeklyCount = completedEventTasksMap[task.eventId] ?? 0;
        }
      }
    }

    return KeepUpResponse.result(tasks);
  }

  /// ottiene tutti le tracce giornaliere fino alla data specificata inclusa,
  /// utilizzando una data di inizio se specificata
  Future<KeepUpResponse<List<KeepUpDailyTrace>>> getDailyTraces(
      {required DateTime until, DateTime? from}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    // costruisce la query
    final query = QueryBuilder.name(KeepUpDailyTraceDataModel.className)
      ..whereEqualTo(KeepUpDailyTraceDataModel.userId,
          KeepUpUserDataModel.pointerTo(currentUser!.objectId!))
      ..whereLessThanOrEqualTo(
          KeepUpDailyTraceDataModel.date, until.getDateOnly())
      ..orderByAscending(KeepUpDailyTraceDataModel.date);

    if (from != null) {
      query.whereGreaterThanOrEqualsTo(
          KeepUpDailyTraceDataModel.date, from.getDateOnly());
    }
    // effettua la query principale
    final objects = await query.find();

    if (objects.isEmpty) {
      KeepUpResponse.result(List<KeepUpDailyTrace>.empty());
    }

    return KeepUpResponse.result(
        objects.map((object) => KeepUpDailyTrace.fromJson(object)).toList());
  }

  /// ottiene la daily trace nel determinato giorno
  Future<KeepUpResponse<KeepUpDailyTrace?>> getDailyTrace(
      {required DateTime inDate}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    // costruisce la query
    final query = QueryBuilder.name(KeepUpDailyTraceDataModel.className)
      ..whereEqualTo(KeepUpDailyTraceDataModel.userId,
          KeepUpUserDataModel.pointerTo(currentUser!.objectId!))
      ..whereEqualTo(KeepUpDailyTraceDataModel.date, inDate.getDateOnly());
    // effettua la query principale
    final objects = await query.find();

    if (objects.isEmpty) {
      return KeepUpResponse.result(null);
    }

    return KeepUpResponse.result(KeepUpDailyTrace.fromJson(objects.first));
  }

  /// aggiorna o crea la daily trace nel determinato giorno
  Future<KeepUpResponse> updateDailyTrace(KeepUpDailyTrace trace) async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    final object = ParseObject(KeepUpDailyTraceDataModel.className)
      ..objectId = trace.id
      ..set(KeepUpDailyTraceDataModel.userId,
          KeepUpUserDataModel.pointerTo(currentUser!.objectId!))
      ..set(KeepUpDailyTraceDataModel.completedTasks, trace.completedTasks)
      ..set(KeepUpDailyTraceDataModel.date, trace.date.getDateOnly())
      ..set(KeepUpDailyTraceDataModel.mood, trace.mood)
      ..set(KeepUpDailyTraceDataModel.notes, trace.notes);

    // salva i metadati
    final parseResponse = await object.save();

    // setta l'id se non era settato perchè doveva essere ancora creato
    trace.id = object.objectId;

    if (!parseResponse.success) {
      return KeepUpResponse.error(
          'KeepUp: daily trace update failure: ${parseResponse.error!.message}');
    }

    return KeepUpResponse();
  }

  _addThreadView(String threadId, String userId) async {
    // costruisce la query per verificare l'unicità della entry
    final query = QueryBuilder.name(KeepUpThreadViewDataModel.className)
      ..whereEqualTo(KeepUpThreadViewDataModel.threadId,
          KeepUpThreadDataModel.pointerTo(threadId))
      ..whereEqualTo(KeepUpThreadViewDataModel.userId,
          KeepUpUserDataModel.pointerTo(userId));
    // ottiene la risposta
    final response = await query.count();
    // se non presente, allora la aggiunge
    if (response.count == 0) {
      final object = ParseObject(KeepUpThreadViewDataModel.className)
        ..set(KeepUpThreadViewDataModel.threadId,
            KeepUpThreadDataModel.pointerTo(threadId))
        ..set(KeepUpThreadViewDataModel.userId,
            KeepUpUserDataModel.pointerTo(userId));
      // lo salva
      await object.save();
    }
  }

  Future<int> _getThreadViewsCount(String threadId) async {
    // costruisce la query per verificare l'unicità della entry
    final query = QueryBuilder.name(KeepUpThreadViewDataModel.className)
      ..whereEqualTo(KeepUpThreadViewDataModel.threadId,
          KeepUpThreadDataModel.pointerTo(threadId));
    // ottiene la risposta
    final response = await query.count();
    // se non presente, allora la aggiunge
    return response.count;
  }

  _flipThreadMessageLike(String messageId, String userId) async {
    // costruisce la query per verificare l'unicità della entry
    final query = QueryBuilder.name(KeepUpThreadMessageLikeDataModel.className)
      ..whereEqualTo(KeepUpThreadMessageLikeDataModel.messageId,
          KeepUpThreadMessageDataModel.pointerTo(messageId))
      ..whereEqualTo(KeepUpThreadMessageLikeDataModel.userId,
          KeepUpUserDataModel.pointerTo(userId));
    // ottiene la risposta
    final response = await query.find();
    // se il like è assente, lo inserisce
    if (response.isEmpty) {
      final object = ParseObject(KeepUpThreadMessageLikeDataModel.className)
        ..set(KeepUpThreadMessageLikeDataModel.messageId,
            KeepUpThreadMessageDataModel.pointerTo(messageId))
        ..set(KeepUpThreadMessageLikeDataModel.userId,
            KeepUpUserDataModel.pointerTo(userId));
      // lo salva
      await object.save();
    }
    // se il like è presente, lo rimuove
    else {
      await response.first.delete();
    }
  }

  Future<bool> _userLikesThreadMessage(String messageId, String userId) async {
    // costruisce la query per verificare l'unicità della entry
    final query = QueryBuilder.name(KeepUpThreadMessageLikeDataModel.className)
      ..whereEqualTo(KeepUpThreadMessageLikeDataModel.messageId,
          KeepUpThreadMessageDataModel.pointerTo(messageId))
      ..whereEqualTo(KeepUpThreadMessageLikeDataModel.userId,
          KeepUpUserDataModel.pointerTo(userId));
    // ottiene la risposta
    final response = await query.count();
    // restituisce il risultato
    return response.count > 0;
  }

  Future<int> _getThreadMessageLikesCount(String messageId) async {
    // costruisce la query per verificare l'unicità della entry
    final query = QueryBuilder.name(KeepUpThreadMessageLikeDataModel.className)
      ..whereEqualTo(KeepUpThreadMessageLikeDataModel.messageId,
          KeepUpThreadMessageDataModel.pointerTo(messageId));
    // ottiene la risposta
    final response = await query.count();
    // se non presente, allora la aggiunge
    return response.count;
  }

  Future<String?> _getUserName(String userId) async {
    final response =
        await ParseObject(KeepUpUserDataModel.className).getObject(userId);
    // restituisce null in caso di errore o il nome
    return response.results?.first[KeepUpUserDataModel.fullName];
  }

  /// l'utente può cominciare un nuovo thread e pubblica il primo messaggio
  Future<KeepUpResponse> beginThread(
      {required String title,
      required String body,
      required List<String> tags,
      required bool anonymous}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser;
    // costruisce le entry per il thread
    final threadObject = ParseObject(KeepUpThreadDataModel.className)
      ..set(KeepUpThreadDataModel.title, title)
      ..set(KeepUpThreadDataModel.tags, tags)
      ..set(KeepUpThreadDataModel.creatorId,
          KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // salva il thread per ottenere il suo id
    var response = await threadObject.save();

    if (!response.success) {
      return KeepUpResponse.error(
          'KeepUp: thread creation failure: ${response.error!.message}');
    }

    // costruisce il primo messaggio, ovvero quello del creatore
    final firstMessageObject =
        ParseObject(KeepUpThreadMessageDataModel.className)
          ..set(KeepUpThreadMessageDataModel.threadId,
              KeepUpThreadDataModel.pointerTo(threadObject.objectId!))
          ..set(KeepUpThreadMessageDataModel.senderId,
              KeepUpUserDataModel.pointerTo(currentUser.objectId!))
          ..set(KeepUpThreadMessageDataModel.anonymous, anonymous)
          ..set(KeepUpThreadMessageDataModel.body, body);
    // salva il primo messaggio
    response = await firstMessageObject.save();

    if (!response.success) {
      return KeepUpResponse.error(
          'KeepUp: thread message creation failure: ${response.error!.message}');
    }

    // imposta il creatore come partecipante
    final partecipantObject =
        ParseObject(KeepUpThreadPartecipantDataModel.className)
          ..set(KeepUpThreadPartecipantDataModel.threadId,
              KeepUpThreadDataModel.pointerTo(threadObject.objectId!))
          ..set(KeepUpThreadPartecipantDataModel.userId,
              KeepUpUserDataModel.pointerTo(currentUser.objectId!))
          ..set(KeepUpThreadPartecipantDataModel.lastReadMessageDate,
              firstMessageObject.createdAt);
    // salva la relazione
    response = await partecipantObject.save();

    if (!response.success) {
      return KeepUpResponse.error(
          'KeepUp: thread partecipant creation failure: ${response.error!.message}');
    }

    return KeepUpResponse();
  }

  /// l'utente può pubblicare un messaggio nel thread ed è aggiunto eventualmente
  /// ai partecipante
  /// l'utente può cominciare un nuovo thread
  Future<KeepUpResponse> pulishThreadMessage(
      {required String threadId,
      required String body,
      required bool anonymous}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser;
    // costruisce il messaggio
    final messageObject = ParseObject(KeepUpThreadMessageDataModel.className)
      ..set(KeepUpThreadMessageDataModel.threadId,
          KeepUpThreadDataModel.pointerTo(threadId))
      ..set(KeepUpThreadMessageDataModel.senderId,
          KeepUpUserDataModel.pointerTo(currentUser.objectId!))
      ..set(KeepUpThreadMessageDataModel.anonymous, anonymous)
      ..set(KeepUpThreadMessageDataModel.body, body);
    // salva il primo messaggio
    var response = await messageObject.save();

    if (!response.success) {
      return KeepUpResponse.error(
          'KeepUp: thread message creation failure: ${response.error!.message}');
    }

    // aggiunge il partecipante se non è presente
    final partecipantQuery =
        QueryBuilder.name(KeepUpThreadPartecipantDataModel.className)
          ..whereEqualTo(KeepUpThreadPartecipantDataModel.threadId,
              KeepUpThreadDataModel.pointerTo(threadId))
          ..whereEqualTo(KeepUpThreadPartecipantDataModel.userId,
              KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // effettua la ricerca
    final partecipantResponse = await partecipantQuery.find();
    // se non presente, lo aggiunge
    if (partecipantResponse.isEmpty) {
      final partecipantObject =
          ParseObject(KeepUpThreadPartecipantDataModel.className)
            ..set(KeepUpThreadPartecipantDataModel.threadId,
                KeepUpThreadDataModel.pointerTo(threadId))
            ..set(KeepUpThreadPartecipantDataModel.userId,
                KeepUpUserDataModel.pointerTo(currentUser.objectId!))
            ..set(KeepUpThreadPartecipantDataModel.lastReadMessageDate,
                messageObject.createdAt);
      // salva la relazione
      response = await partecipantObject.save();
    }
    // altrimenti aggiorna
    else {
      final partecipantObject = partecipantResponse.first;
      partecipantObject.set(
          KeepUpThreadPartecipantDataModel.lastReadMessageDate,
          messageObject.createdAt);
      // salva la relazione
      response = await partecipantObject.save();
    }

    if (!response.success) {
      return KeepUpResponse.error(
          'KeepUp: thread partecipant creation failure: ${response.error!.message}');
    }

    return KeepUpResponse();
  }

  /// l'utente può dare un giudizio ad un messaggio di un thread
  Future<KeepUpResponse> likeThreadMessage({required String messageId}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser;
    // chiama la funzione che flippa il like a seconda che sia presente o meno
    await _flipThreadMessageLike(messageId, currentUser.objectId!);
    return KeepUpResponse();
  }

  /// restituisce i thread in cui l'utente loggato ha partecipato
  Future<KeepUpResponse<List<KeepUpThread>>> getUserThreads(
      {bool asCreator = false}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser;
    // costruisce la query per scaricare i thread in cui partecipa l'utente
    final query = QueryBuilder.name(KeepUpThreadPartecipantDataModel.className)
      ..whereEqualTo(KeepUpThreadPartecipantDataModel.userId,
          KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // effettua la query
    var parseResults = await query.find();
    // ottiene la lista dei thread in cui l'utente partecipa
    final userThreadsIds = parseResults
        .map((partecipant) =>
            partecipant[KeepUpThreadPartecipantDataModel.threadId]
                [KeepUpThreadDataModel.id])
        .toList();
    // costruisce la query per scaricare tali thread
    final threadsQuery = QueryBuilder.name(KeepUpThreadDataModel.className)
      ..whereContainedIn(KeepUpThreadDataModel.id, userThreadsIds)
      ..orderByDescending(KeepUpThreadDataModel.creationDate);
    // se specifica i thread creati da lui, allora filtra la query
    if (asCreator) {
      threadsQuery.whereEqualTo(KeepUpThreadDataModel.creatorId,
          KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    }
    // effettua la query
    parseResults = await threadsQuery.find();
    // costruisce i thread ordinati per data di creazione decrescente
    // e ottiene il numero di messaggi associati
    final threads =
        parseResults.map((object) => KeepUpThread.fromJson(object)).toList();
    // ottiene le informazioni sui vari thread
    for (final t in threads) {
      // query per il numero di messaggi
      final messagesQuery =
          QueryBuilder.name(KeepUpThreadMessageDataModel.className)
            ..whereEqualTo(KeepUpThreadMessageDataModel.threadId,
                KeepUpThreadDataModel.pointerTo(t.id!));
      // query per il numero di partecipanti
      final partecipantsQuery =
          QueryBuilder.name(KeepUpThreadPartecipantDataModel.className)
            ..whereEqualTo(KeepUpThreadPartecipantDataModel.threadId,
                KeepUpThreadDataModel.pointerTo(t.id!));
      // effettua la query
      final authorResponse = await _getUserName(t.creatorId!);
      final messagesResponse = await messagesQuery.count();
      final partecipantsResponse = await partecipantsQuery.count();
      // query per ottenere il primo messaggio
      messagesQuery
        ..orderByAscending(KeepUpThreadMessageDataModel.creationDate)
        ..setLimit(1);
      // effettua la query sul primo messaggio
      final messages = await messagesQuery.find();
      // setta i valori
      t.viewsCount = await _getThreadViewsCount(t.id!);
      t.messagesCount = messagesResponse.count;
      t.partecipantsCount = partecipantsResponse.count;
      // ottiene il primo messaggio
      if (messages.isNotEmpty) {
        t.question = KeepUpThreadMessage.fromJson(messages.first);
      }
      // ottiene il nome dell'autore
      if (authorResponse != null) {
        // se il thread è dell'utente loggato allora viene mostrato 'Tu'
        if (t.creatorId! == currentUser.objectId!) {
          t.authorName = 'Tu';
        }
        // se l'utente è un altro ed è anonimo allora il suo nome non è mostrato
        else if (t.question!.anonymous) {
          t.authorName = 'Anonimo';
        }
        // altrimenti è mostrato il nome
        else {
          t.authorName = authorResponse;
        }
      }
    }

    return KeepUpResponse.result(threads);
  }

  /// restituisce tutti i messaggi nel thread specificato,
  /// specificando se l'utente li ha letti o meno, e quindi leggendoli
  Future<KeepUpResponse<List<KeepUpThreadMessage>>> getThreadMessages(
      {required String threadId}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser;
    // costruisce la query per capire se l'utente partecipa al thread o meno
    final partecipantQuery =
        QueryBuilder.name(KeepUpThreadPartecipantDataModel.className)
          ..whereEqualTo(KeepUpThreadPartecipantDataModel.userId,
              KeepUpUserDataModel.pointerTo(currentUser.objectId!));
    // effettua la query
    var parseResults = await partecipantQuery.find();
    DateTime? lastMessageReadDate;
    // l'utente è partecipante
    if (parseResults.isNotEmpty) {
      lastMessageReadDate = parseResults
          .first[KeepUpThreadPartecipantDataModel.lastReadMessageDate];
    }
    // costruisce la query per scaricare i messaggi del thread specificato
    final query = QueryBuilder.name(KeepUpThreadMessageDataModel.className)
      ..whereEqualTo(KeepUpThreadMessageDataModel.threadId,
          KeepUpThreadDataModel.pointerTo(threadId));
    // effettua la query
    parseResults = await query.find();
    // la lista dei messaggi è ordinati per data decrescente
    final messages = parseResults
        .map((object) => KeepUpThreadMessage.fromJson(object))
        .toList();
    // i nome degli autori dei messaggi sono tenuti in cache
    final usersNames = <String, String>{};
    // per ogni messaggio
    for (final message in messages) {
      // ottiene il nome dell'autore
      // se il messaggio è dell'utente loggato allora viene mostrato 'Tu'
      if (message.senderId == currentUser.objectId) {
        message.senderName = 'Tu';
      }
      // se l'utente è un altro ed è anonimo allora il suo nome non è mostrato
      else if (message.anonymous) {
        message.senderName = 'Anonimo';
      }
      // se il nome è in cache
      else if (usersNames.containsKey(message.senderId!)) {
        message.senderName = usersNames[message.senderId]!;
      }
      // altrimenti è mostrato il nome
      else {
        final name = await _getUserName(message.senderId!);
        message.senderName = name!;
        usersNames.putIfAbsent(message.senderId!, () => name);
      }
      // setta la visualizzazione o meno sul messaggio
      message.isRead = lastMessageReadDate == null
          ? null
          : lastMessageReadDate.compareTo(message.creationDate) >= 0;
      // ottiene il numero di likes
      message.likes = await _getThreadMessageLikesCount(message.id!);
      // ottiene se l'utente loggato ha messo o meno like al messaggio
      message.isLiked =
          await _userLikesThreadMessage(message.id!, currentUser.objectId!);
    }
    // siccome scarica i messaggi del thread, aggiunge la visualizzazione
    _addThreadView(threadId, currentUser.objectId!);

    return KeepUpResponse.result(messages);
  }

  /// restituisce i thread che corrispondono ai tag specificati
  /// (and logico dei tag su ciascun thread)
  Future<KeepUpResponse<List<KeepUpThread>>> getThreadsByTags(
      {required List<String> tags, String? filter, int limit = 30}) async {
    final currentUser = await ParseUser.currentUser() as ParseUser;
    // costruisce la query per scaricare tali thread
    final threadsQuery = QueryBuilder.name(KeepUpThreadDataModel.className);
    // se i tags sono vuoti o contiene all, allora il match avviene con tutti
    if (tags.isNotEmpty && !tags.contains(KeepUpThreadTags.all)) {
      threadsQuery.whereArrayContainsAll(KeepUpThreadDataModel.tags, tags);
    }
    // applica il filtro se presente
    if (filter != null) {
      threadsQuery.whereContains(KeepUpThreadDataModel.title, filter);
    }
    // li ordina dal più recente al meno
    threadsQuery.orderByDescending(KeepUpThreadDataModel.creationDate);
    // limita il numero
    threadsQuery.setLimit(limit);
    // effettua la query
    final parseResults = await threadsQuery.find();
    // costruisce i thread ordinati per data di creazione decrescente
    // e ottiene il numero di messaggi associati in ordine
    final threads =
        parseResults.map((object) => KeepUpThread.fromJson(object)).toList();
    // ottiene le informazioni sui vari thread
    for (final t in threads) {
      final messagesQuery =
          QueryBuilder.name(KeepUpThreadMessageDataModel.className)
            ..whereEqualTo(KeepUpThreadMessageDataModel.threadId,
                KeepUpThreadDataModel.pointerTo(t.id!));
      // query per il numero di partecipanti
      final partecipantsQuery =
          QueryBuilder.name(KeepUpThreadPartecipantDataModel.className)
            ..whereEqualTo(KeepUpThreadPartecipantDataModel.threadId,
                KeepUpThreadDataModel.pointerTo(t.id!));
      // effettua la query
      final authorResponse = await _getUserName(t.creatorId!);
      final messagesResponse = await messagesQuery.count();
      final partecipantsResponse = await partecipantsQuery.count();
      // query per ottenere il primo messaggio
      messagesQuery
        ..orderByAscending(KeepUpThreadMessageDataModel.creationDate)
        ..setLimit(1);
      // effettua la query sul primo messaggio
      final messages = await messagesQuery.find();
      // setta i valori
      t.viewsCount = await _getThreadViewsCount(t.id!);
      t.messagesCount = messagesResponse.count;
      t.partecipantsCount = partecipantsResponse.count;
      // ottiene il primo messaggio
      if (messages.isNotEmpty) {
        t.question = KeepUpThreadMessage.fromJson(messages.first);
      }
      // ottiene il nome dell'autore
      if (authorResponse != null) {
        // se il thread è dell'utente loggato allora viene mostrato 'Tu'
        if (t.creatorId! == currentUser.objectId!) {
          t.authorName = 'Tu';
        }
        // se l'utente è un altro ed è anonimo allora il suo nome non è mostrato
        else if (t.question!.anonymous) {
          t.authorName = 'Anonimo';
        }
        // altrimenti è mostrato il nome
        else {
          t.authorName = authorResponse;
        }
      }
    }

    return KeepUpResponse.result(threads);
  }
}

/// Questa classe è utilizzata per ricevere una risposta attraverso una
/// future in seguito ad una richiesta http
class KeepUpResponse<T> {
  // conferma la presenza di un errore nella richesta
  bool error = false;
  // contiene il messaggio di errore eventualmente
  String? message;
  // contiene il risultato della richiesta (e.g. i task di un certo giorno)
  T? result;

  /// costruisce una risposta errata
  KeepUpResponse.error(this.message) {
    error = true;
  }

  /// costruisce una risposta corretta con risultato
  KeepUpResponse.result(this.result);

  /// costruisce una risposta corretta priva di risultato
  KeepUpResponse() {
    result = null;
  }
}

class KeepUpUser {
  String fullname;
  String email;
  String sessionToken;
  KeepUpDayTime? notifySurveyTime;
  bool notifyTasks;

  KeepUpUser(this.fullname, this.email, this.sessionToken,
      this.notifySurveyTime, this.notifyTasks);
}

class KeepUpEvent {
  String? id;
  String title;
  DateTime startDate;
  DateTime? endDate;
  String? description;
  Color color;
  String category;
  List<KeepUpRecurrence> recurrences = [];

  KeepUpEvent(
      {this.id,
      required this.title,
      required this.startDate,
      this.endDate,
      this.description,
      required this.color,
      this.category = KeepUpEventCategory.other});

  factory KeepUpEvent.fromJson(dynamic json) {
    return KeepUpEvent(
        id: json[KeepUpEventDataModel.id],
        title: json[KeepUpEventDataModel.title],
        startDate: json[KeepUpEventDataModel.startDate],
        endDate: json[KeepUpEventDataModel.endDate],
        description: json[KeepUpEventDataModel.description],
        color: Color(json[KeepUpEventDataModel.color]),
        category: json[KeepUpEventDataModel.category]);
  }

  void addDailySchedule(
      {required KeepUpDayTime startTime, KeepUpDayTime? endTime}) {
    recurrences
        .removeWhere((element) => element.type == KeepUpRecurrenceType.daily);
    final any = recurrences
        .where((element) => element.type == KeepUpRecurrenceType.daily);

    if (any.isNotEmpty) {
      any.first.startTime = startTime;
      any.first.endTime = endTime;
    } else {
      recurrences.add(KeepUpRecurrence(
          type: KeepUpRecurrenceType.daily,
          startTime: startTime,
          endTime: endTime));
    }
  }

  void addWeeklySchedule(
      {required int weekDay,
      required KeepUpDayTime startTime,
      KeepUpDayTime? endTime}) {
    final any = recurrences.where((element) =>
        element.type == KeepUpRecurrenceType.weekly &&
        element.weekDay == weekDay);

    if (any.isNotEmpty) {
      any.first.startTime = startTime;
      any.first.endTime = endTime;
    } else {
      recurrences.add(KeepUpRecurrence(
          type: KeepUpRecurrenceType.weekly,
          weekDay: weekDay,
          startTime: startTime,
          endTime: endTime));
    }
  }

  void addMonthlySchedule(
      {required int day,
      required KeepUpDayTime startTime,
      KeepUpDayTime? endTime}) {
    final any = recurrences.where((element) =>
        element.type == KeepUpRecurrenceType.monthly && element.day == day);

    if (any.isNotEmpty) {
      any.first.startTime = startTime;
      any.first.endTime = endTime;
    } else {
      recurrences.add(KeepUpRecurrence(
          type: KeepUpRecurrenceType.monthly,
          day: day,
          startTime: startTime,
          endTime: endTime));
    }
  }

  void addSchedule(
      {required int day,
      required int month,
      required int year,
      required KeepUpDayTime startTime,
      KeepUpDayTime? endTime}) {
    final any = recurrences.where((element) =>
        element.type == KeepUpRecurrenceType.none &&
        element.day == day &&
        element.month == month &&
        element.year == year);
    if (any.isNotEmpty) {
      for (var recurrence in any) {
        recurrence.startTime = startTime;
        recurrence.endTime = endTime;
      }
    } else {
      recurrences.add(KeepUpRecurrence(
          type: KeepUpRecurrenceType.none,
          day: day,
          month: month,
          year: year,
          weekDay: null,
          startTime: startTime,
          endTime: endTime));
    }
  }
}

class KeepUpEventCategory {
  static const education = 'Educazione';
  static const sport = 'Sport';
  static const lecture = 'Lezione';
  static const other = 'Altro';
  static const values = [education, sport, lecture, other];
}

class KeepUpGoal extends KeepUpEvent {
  int daysPerWeek;
  int hoursPerDay;
  String? metadataId;
  int? ratingsCount;
  num? rating;
  DateTime? completionDate;

  KeepUpGoal(
      {String? id,
      required String title,
      required DateTime startDate,
      DateTime? endDate,
      String? description,
      required Color color,
      String category = KeepUpEventCategory.other,
      this.daysPerWeek = 3,
      this.hoursPerDay = 1,
      this.metadataId,
      this.ratingsCount = 0,
      this.rating = 0,
      this.completionDate})
      : super(
            id: id,
            title: title,
            startDate: startDate,
            endDate: endDate,
            description: description,
            category: category,
            color: color);

  factory KeepUpGoal.fromEvent(KeepUpEvent event) {
    return KeepUpGoal(
        id: event.id,
        title: event.title,
        description: event.description,
        startDate: event.startDate,
        endDate: event.endDate,
        category: event.category,
        color: event.color);
  }

  KeepUpEvent toEvent() => this;
}

enum KeepUpRecurrenceType { daily, weekly, monthly, none }

class KeepUpRecurrence {
  String? id;
  String? eventId;
  KeepUpRecurrenceType type;
  KeepUpDayTime startTime;
  KeepUpDayTime? endTime;
  int? day;
  int? month;
  int? year;
  int? weekDay;
  final List<KeepUpRecurrenceException> exceptions = [];

  KeepUpRecurrence(
      {this.id,
      this.eventId,
      required this.type,
      required this.startTime,
      this.endTime,
      this.day,
      this.month,
      this.year,
      this.weekDay});

  factory KeepUpRecurrence.fromJson(dynamic json) {
    final result = KeepUpRecurrence(
        id: json[KeepUpRecurrenceDataModel.id],
        eventId: json[KeepUpRecurrenceDataModel.eventId]
            [KeepUpEventDataModel.id],
        startTime:
            KeepUpDayTime.fromJson(json[KeepUpRecurrenceDataModel.startTime]),
        endTime:
            KeepUpDayTime.fromJson(json[KeepUpRecurrenceDataModel.endTime]),
        type:
            KeepUpRecurrenceType.values[json[KeepUpRecurrenceDataModel.type]]);

    switch (result.type) {
      case KeepUpRecurrenceType.none:
        result.day = int.parse(json[KeepUpRecurrenceDataModel.day]);
        result.month = int.parse(json[KeepUpRecurrenceDataModel.month]);
        result.year = int.parse(json[KeepUpRecurrenceDataModel.year]);
        break;
      case KeepUpRecurrenceType.daily:
        break;
      case KeepUpRecurrenceType.weekly:
        result.weekDay = int.parse(json[KeepUpRecurrenceDataModel.weekDay]);
        break;
      case KeepUpRecurrenceType.monthly:
        result.day = int.parse(json[KeepUpRecurrenceDataModel.day]);
        result.month = int.parse(json[KeepUpRecurrenceDataModel.month]);
        break;
      default:
    }

    return result;
  }

  void addException({required DateTime onDate}) {
    exceptions.where((exception) => exception.onDate == onDate);
    exceptions.add(KeepUpRecurrenceException(
        eventId: eventId, recurrenceId: id, onDate: onDate));
  }
}

class KeepUpRecurrenceException {
  String? id;
  String? eventId;
  String? recurrenceId;
  DateTime onDate;

  KeepUpRecurrenceException(
      {this.id, this.eventId, this.recurrenceId, required this.onDate});

  factory KeepUpRecurrenceException.fromJson(dynamic json) {
    return KeepUpRecurrenceException(
        id: json[KeepUpExceptionDataModel.id],
        eventId: json[KeepUpExceptionDataModel.eventId]
            [KeepUpEventDataModel.id],
        recurrenceId: json[KeepUpExceptionDataModel.recurrenceId]
            [KeepUpEventDataModel.id],
        onDate: json[KeepUpExceptionDataModel.onDate]);
  }
}

class KeepUpDailyTrace {
  String? id;
  String? userId;
  DateTime date;
  List<String> completedTasks;
  int? mood;
  String? notes;

  KeepUpDailyTrace(
      {this.id,
      this.userId,
      required this.date,
      required this.completedTasks,
      this.mood,
      this.notes});

  factory KeepUpDailyTrace.fromJson(dynamic json) {
    return KeepUpDailyTrace(
        id: json[KeepUpDailyTraceDataModel.id],
        userId: json[KeepUpDailyTraceDataModel.userId][KeepUpUserDataModel.id],
        date: json[KeepUpDailyTraceDataModel.date],
        completedTasks:
            List.from(json[KeepUpDailyTraceDataModel.completedTasks]),
        mood: json[KeepUpDailyTraceDataModel.mood],
        notes: json[KeepUpDailyTraceDataModel.notes]);
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

  KeepUpDayTime.fromTimeOfDay(TimeOfDay time)
      : hour = time.hour,
        minute = time.minute;

  Map<String, dynamic> toJson() {
    return {'hour': hour, 'minute': minute};
  }

  TimeOfDay toTimeOfDay() => TimeOfDay(hour: hour, minute: minute);

  Duration elapsed(KeepUpDayTime other) {
    final minutes = hour * 60 + minute;
    final otherMinutes = other.hour * 60 + other.minute;
    return Duration(minutes: minutes - otherMinutes);
  }

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

  @override
  String toString() {
    return '${hour < 10 ? '0$hour' : hour}:${minute < 10 ? '0$minute' : minute}';
  }
}

class KeepUpTask {
  String eventId;
  String recurrenceId;
  String title;
  DateTime date;
  KeepUpDayTime startTime, endTime;
  Color color;
  KeepUpRecurrenceType recurrenceType;
  int? totalWeeklyCount;
  int? completedWeeklyCount;

  KeepUpTask(
      {required this.eventId,
      required this.recurrenceId,
      required this.title,
      required this.date,
      required this.startTime,
      required this.endTime,
      required this.color,
      required this.recurrenceType,
      this.totalWeeklyCount,
      this.completedWeeklyCount});

  @override
  int get hashCode =>
      Object.hash(title, startTime.hour, startTime.minute, date);

  @override
  bool operator ==(Object other) {
    return (other as KeepUpTask).title == title &&
        other.startTime == startTime &&
        other.date == date;
  }
}

extension MyDateTimeExtension on DateTime {
  DateTime getDateOnly() => DateTime.utc(year, month, day);
}

class KeepUpThread {
  String? id;
  String? creatorId;
  String title;
  List<String> tags;
  DateTime creationDate;
  int? viewsCount;
  int? messagesCount;
  int? partecipantsCount;
  String? authorName;
  KeepUpThreadMessage? question;

  KeepUpThread(
      {this.id,
      this.creatorId,
      required this.title,
      required this.tags,
      required this.creationDate});

  factory KeepUpThread.fromJson(dynamic json) {
    return KeepUpThread(
        id: json[KeepUpThreadDataModel.id],
        creatorId: json[KeepUpThreadDataModel.creatorId]
            [KeepUpUserDataModel.id],
        creationDate: json[KeepUpThreadDataModel.creationDate],
        tags: List.from(json[KeepUpThreadDataModel.tags]),
        title: json[KeepUpThreadDataModel.title]);
  }
}

class KeepUpThreadMessage {
  String? id;
  String? senderId;
  String? threadId;
  String body;
  bool anonymous;
  DateTime creationDate;
  int? likes;
  String? senderName;
  bool? isRead;
  bool? isLiked;

  KeepUpThreadMessage(
      {this.id,
      this.senderId,
      this.threadId,
      required this.body,
      required this.anonymous,
      required this.creationDate,
      this.isRead = false});

  factory KeepUpThreadMessage.fromJson(dynamic json) {
    return KeepUpThreadMessage(
        id: json[KeepUpThreadMessageDataModel.id],
        senderId: json[KeepUpThreadMessageDataModel.senderId]
            [KeepUpUserDataModel.id],
        threadId: json[KeepUpThreadMessageDataModel.threadId]
            [KeepUpThreadDataModel.id],
        creationDate: json[KeepUpThreadDataModel.creationDate],
        body: json[KeepUpThreadMessageDataModel.body],
        anonymous: json[KeepUpThreadMessageDataModel.anonymous]);
  }
}

abstract class KeepUpUserDataModel {
  static const className = '_User';
  static const id = 'objectId';
  static const username = 'username';
  static const email = 'email';
  static const password = 'password';
  static const fullName = 'fullName';
  static const notifySurveyTime = 'notifySurveyTime';
  static const notifyTasks = 'notifyTasks';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': '_User', 'objectId': objectId};
  }
}

abstract class KeepUpDeletedUserDataModel {
  static const className = 'DeletedUser';
  static const id = 'userId';
  static const email = 'email';
  static const fullName = 'fullName';
  static const reason = 'reason';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpEventDataModel {
  static const className = 'Event';
  static const id = 'objectId';
  static const title = 'title';
  static const startDate = 'startDate';
  static const endDate = 'endDate';
  static const creatorId = 'creatorId';
  static const description = 'description';
  static const color = 'color';
  static const category = 'category';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpRecurrenceDataModel {
  static const className = 'Recurrence';
  static const id = 'objectId';
  static const eventId = 'eventId';
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

abstract class KeepUpExceptionDataModel {
  static const className = 'Exception';
  static const id = 'objectId';
  static const eventId = 'eventId';
  static const recurrenceId = 'recurrenceId';
  static const onDate = 'onDate';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpGoalDataModel {
  static const className = 'Goal';
  static const id = 'objectId';
  static const eventId = 'eventId';
  static const daysPerWeek = 'daysPerWeek';
  static const hoursPerDay = 'hoursPerDay';
  static const ratingsCount = 'ratingsCount';
  static const rating = 'rating';
  static const completionDate = 'completionDate';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpDailyTraceDataModel {
  static const className = 'DailyTrace';
  static const id = 'objectId';
  static const userId = 'userId';
  static const completedTasks = 'completedTasks';
  static const date = 'date';
  static const mood = 'mood';
  static const notes = 'notes';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpThreadDataModel {
  static const className = 'Thread';
  static const id = 'objectId';
  static const creatorId = 'creatorId';
  static const title = 'title';
  static const tags = 'tags';
  static const creationDate = 'createdAt';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpThreadPartecipantDataModel {
  static const className = 'ThreadPartecipant';
  static const id = 'objectId';
  static const userId = 'userId';
  static const threadId = 'threadId';
  static const lastReadMessageDate = 'lastReadMessageDate';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpThreadViewDataModel {
  static const className = 'ThreadView';
  static const id = 'objectId';
  static const userId = 'userId';
  static const threadId = 'threadId';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpThreadMessageLikeDataModel {
  static const className = 'ThreadMessageLike';
  static const id = 'objectId';
  static const userId = 'userId';
  static const messageId = 'messageId';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpThreadMessageDataModel {
  static const className = 'ThreadMessage';
  static const id = 'objectId';
  static const senderId = 'senderId';
  static const threadId = 'threadId';
  static const body = 'body';
  static const anonymous = 'anonymous';
  static const creationDate = 'createdAt';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpThreadTags {
  static const all = 'Tutti';
  static const computerScience = 'Informatica';
  static const electronics = 'Elettronica';
  static const physics = 'Fisica';
  static const math = 'Matematica';
  static const literature = 'Letturatura';
  static const lifestyle = 'Lifestyle';
  static const sport = 'Sport';
  static const competition = 'Competizione';
  static const values = [
    all,
    computerScience,
    electronics,
    physics,
    math,
    literature,
    lifestyle,
    sport,
    competition
  ];
}
