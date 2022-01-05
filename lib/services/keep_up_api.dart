import 'dart:collection';
import 'dart:developer';

import 'package:flutter/material.dart';
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

    user.set(KeepUpUserDataModelKey.fullName, fullName);

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

    if (response.success) {
      log('KeepUp: user login success');
      return KeepUpResponse();
    } else {
      return KeepUpResponse.error(
          'KeepUp: user registration failure: ${response.error!.message}');
    }
  }

  Future<KeepUpResponse> logout(String email, String password) async {
    final currentUser = await ParseUser.currentUser() as ParseUser?;
    final response = await currentUser!.logout();

    if (response.success) {
      log('KeepUp: user logout success');
      return KeepUpResponse();
    } else {
      return KeepUpResponse.error(
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

  Future<bool> _eventAlreadyExists(String eventName) async {
    final query = QueryBuilder.name(KeepUpEventDataModelKey.className);
    query.whereEqualTo(KeepUpEventDataModelKey.title, eventName);
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

    final eventObject = ParseObject(KeepUpEventDataModelKey.className)
      ..set(KeepUpEventDataModelKey.title, event.title)
      ..set(KeepUpEventDataModelKey.startDate, event.startDate)
      ..set(KeepUpEventDataModelKey.endDate, event.endDate)
      ..set(KeepUpEventDataModelKey.description, event.description)
      ..set(KeepUpEventDataModelKey.color, event.color.value)
      ..set(KeepUpEventDataModelKey.creatorId, currentUser!.toPointer());

    final response = await eventObject.save();

    if (!response.success) {
      return KeepUpResponse.error(
          'KeepUp: event creation failure: ${response.error!.message}');
    }

    event.id = eventObject.objectId;

    log('KeepUp: event creation success ${eventObject.objectId}');

    for (final recurrence in event.recurrences) {
      final recurrenceObject =
          ParseObject(KeepUpRecurrenceDataModelKey.className)
            ..set(KeepUpRecurrenceDataModelKey.eventId, eventObject.toPointer())
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
        return KeepUpResponse.error(
            'KeepUp: recurrence creation failure: ${response.error!.message}');
      }

      recurrence.id = recurrenceObject.objectId;
      recurrence.eventId = eventObject.objectId;

      log('KeepUp: recurrence creation success');

      for (final exception in recurrence.exceptions) {
        final exceptionObject = ParseObject(
            KeepUpExceptionDataModelKey.className)
          ..set(KeepUpExceptionDataModelKey.eventId, eventObject.toPointer())
          ..set(KeepUpExceptionDataModelKey.recurrenceId,
              recurrenceObject.toPointer())
          ..set(KeepUpExceptionDataModelKey.onDate, exception.onDate);

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

    final eventObject = ParseObject(KeepUpEventDataModelKey.className)
      ..objectId = event.id
      ..set(KeepUpEventDataModelKey.title, event.title)
      ..set(KeepUpEventDataModelKey.startDate, event.startDate)
      ..set(KeepUpEventDataModelKey.endDate, event.endDate)
      ..set(KeepUpEventDataModelKey.description, event.description)
      ..set(KeepUpEventDataModelKey.color, event.color.value)
      ..set(KeepUpEventDataModelKey.creatorId, currentUser!.toPointer());

    final response = await eventObject.save();

    if (!response.success) {
      return KeepUpResponse.error(
          'KeepUp: event updaye failure: ${response.error!.message}');
    }

    log('KeepUp: event update success ${eventObject.objectId}');

    for (final recurrence in event.recurrences) {
      final recurrenceObject =
          ParseObject(KeepUpRecurrenceDataModelKey.className)
            ..set(KeepUpRecurrenceDataModelKey.eventId, eventObject.toPointer())
            ..set(KeepUpRecurrenceDataModelKey.startTime, recurrence.startTime)
            ..set(KeepUpRecurrenceDataModelKey.endTime, recurrence.endTime)
            ..set(KeepUpRecurrenceDataModelKey.type, recurrence.type.index);

      if (recurrence.id != null) recurrenceObject.objectId = recurrence.id;

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
        return KeepUpResponse.error(
            'KeepUp: recurrence update failure: ${response.error!.message}');
      }

      log('KeepUp: recurrence update success');

      for (final exception in recurrence.exceptions) {
        final exceptionObject = ParseObject(
            KeepUpExceptionDataModelKey.className)
          ..set(KeepUpExceptionDataModelKey.eventId, eventObject.toPointer())
          ..set(KeepUpExceptionDataModelKey.recurrenceId,
              recurrenceObject.toPointer())
          ..set(KeepUpExceptionDataModelKey.onDate, exception.onDate);

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
    // costruisce la query per ottenere l'evento
    final mainQuery = QueryBuilder.name(KeepUpEventDataModelKey.className);
    // costruisce la lista delle ricorrenze
    final recurrencesQuery =
        QueryBuilder.name(KeepUpRecurrenceDataModelKey.className);
    // costruisce la lista delle eccezioni alle ricorrenze
    final exceptionsQuery =
        QueryBuilder.name(KeepUpExceptionDataModelKey.className);

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
    final mainQuery = QueryBuilder.name(KeepUpEventDataModelKey.className)
      ..whereEqualTo(KeepUpEventDataModelKey.id, eventId);
    // costruisce la lista delle ricorrenze
    final recurrencesQuery =
        QueryBuilder.name(KeepUpRecurrenceDataModelKey.className)
          ..whereEqualTo(KeepUpRecurrenceDataModelKey.eventId,
              KeepUpEventDataModelKey.pointerTo(eventId));
    // costruisce la lista delle eccezioni alle ricorrenze
    final exceptionsQuery =
        QueryBuilder.name(KeepUpExceptionDataModelKey.className)
          ..whereEqualTo(KeepUpExceptionDataModelKey.eventId,
              KeepUpEventDataModelKey.pointerTo(eventId));

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
    final goalMetadata = ParseObject(KeepUpGoalDataModelKey.className)
      ..set(KeepUpGoalDataModelKey.eventId,
          KeepUpEventDataModelKey.pointerTo(goal.id!))
      ..set(KeepUpGoalDataModelKey.daysPerWeek, goal.daysPerWeek)
      ..set(KeepUpGoalDataModelKey.hoursPerDay, goal.hoursPerDay)
      ..set(KeepUpGoalDataModelKey.category, goal.category);

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
    final goalMetadata = ParseObject(KeepUpGoalDataModelKey.className)
      ..objectId = goal.metadataId
      ..set(KeepUpGoalDataModelKey.eventId,
          KeepUpEventDataModelKey.pointerTo(goal.id!))
      ..set(KeepUpGoalDataModelKey.daysPerWeek, goal.daysPerWeek)
      ..set(KeepUpGoalDataModelKey.hoursPerDay, goal.hoursPerDay)
      ..set(KeepUpGoalDataModelKey.category, goal.category);

    // salva i metadati
    final parseResponse = await goalMetadata.save();

    if (!parseResponse.success) {
      return KeepUpResponse.error(
          'KeepUp: goal update failure: ${parseResponse.error!.message}');
    }

    return KeepUpResponse();
  }

  /// legge tutti i goal (eventi estesi) dal database
  Future<KeepUpResponse<List<KeepUpGoal>>> getAllGoals(
      {bool getMetadata = false}) async {
    // costruisce la query per ottenere i goal
    final goalQuery = QueryBuilder.name(KeepUpGoalDataModelKey.className);
    // ottiene i metadata sui goal
    final goalObjects = await goalQuery.find();

    if (goalObjects.isEmpty) return KeepUpResponse.result([]);

    goalObjects.sort((a, b) {
      return (a[KeepUpGoalDataModelKey.eventId][KeepUpEventDataModelKey.id]
              as String)
          .compareTo(b[KeepUpGoalDataModelKey.eventId]
              [KeepUpEventDataModelKey.id] as String);
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
          goalObjects[i][KeepUpGoalDataModelKey.eventId]
              [KeepUpEventDataModelKey.id]) {
        result.add(KeepUpGoal(
            id: event.id,
            title: event.title,
            description: event.description,
            startDate: event.startDate,
            endDate: event.endDate,
            color: event.color,
            daysPerWeek: goalObjects[i][KeepUpGoalDataModelKey.daysPerWeek],
            hoursPerDay: goalObjects[i][KeepUpGoalDataModelKey.hoursPerDay],
            category: goalObjects[i][KeepUpGoalDataModelKey.category],
            metadataId: goalObjects[i][KeepUpGoalDataModelKey.id]));
        result.last.recurrences = event.recurrences;
        ++i;
      }
    }

    return KeepUpResponse.result(result);
  }

  /// legge un obiettivo (evento esteso) dal database
  Future<KeepUpResponse<KeepUpGoal>> getGoal({required String eventId}) async {
    // effettua la query sull'evento associato
    final response = await getEvent(eventId: eventId);
    // costruisce la query per estrarre i metadati dell'obiettivo
    final goalQuery = QueryBuilder.name(KeepUpGoalDataModelKey.className)
      ..whereEqualTo(KeepUpGoalDataModelKey.eventId,
          KeepUpEventDataModelKey.pointerTo(eventId));

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
        daysPerWeek: goalObjects.first[KeepUpGoalDataModelKey.daysPerWeek],
        hoursPerDay: goalObjects.first[KeepUpGoalDataModelKey.hoursPerDay],
        category: goalObjects.first[KeepUpGoalDataModelKey.category],
        metadataId: goalObjects.first[KeepUpGoalDataModelKey.id]);

    result.recurrences = response.result!.recurrences;

    return KeepUpResponse.result(result);
  }

  /// il risultato è restituito come List<KeepUpTask> all'interno del campo
  /// 'response' della KeepUpResponse
  Future<KeepUpResponse<List<KeepUpTask>>> getTasks(
      {required DateTime inDate}) async {
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

    if (recurrenceObjects.isEmpty) {
      KeepUpResponse.result(List<KeepUpTask>.empty());
    }

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
          final associatedEvent = eventsObjects.firstWhere((eventObject) {
            return eventObject[KeepUpEventDataModelKey.id] ==
                recurrenceObject[KeepUpRecurrenceDataModelKey.eventId]
                    [KeepUpEventDataModelKey.id];
          });
          return KeepUpTask(
              eventId: recurrenceObject[KeepUpRecurrenceDataModelKey.eventId]
                  [KeepUpEventDataModelKey.id],
              recurrenceId: recurrenceObject[KeepUpRecurrenceDataModelKey.id],
              color: Color(associatedEvent[KeepUpEventDataModelKey.color]),
              title: associatedEvent[KeepUpEventDataModelKey.title],
              date: inDate,
              startTime: KeepUpDayTime.fromJson(
                  recurrenceObject[KeepUpRecurrenceDataModelKey.startTime]),
              endTime: KeepUpDayTime.fromJson(
                  recurrenceObject[KeepUpRecurrenceDataModelKey.endTime]));
        })
        .toSet()
        .toList();

    tasks.sort((a, b) => a.startTime.compareTo(b.startTime));

    return KeepUpResponse.result(tasks);
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

  KeepUpUser(this.fullname, this.email, this.sessionToken);
}

class KeepUpEvent {
  String? id;
  String title;
  DateTime startDate;
  DateTime? endDate;
  String? description;
  Color color;
  List<KeepUpRecurrence> recurrences = [];

  KeepUpEvent(
      {this.id,
      required this.title,
      required this.startDate,
      this.endDate,
      this.description,
      required this.color});

  factory KeepUpEvent.fromJson(dynamic json) {
    return KeepUpEvent(
        id: json[KeepUpEventDataModelKey.id],
        title: json[KeepUpEventDataModelKey.title],
        startDate: json[KeepUpEventDataModelKey.startDate],
        endDate: json[KeepUpEventDataModelKey.endDate],
        description: json[KeepUpEventDataModelKey.description],
        color: Color(json[KeepUpEventDataModelKey.color]));
  }

  void addDailySchedule(
      {required KeepUpDayTime startTime, KeepUpDayTime? endTime}) {
    recurrences
        .removeWhere((element) => element.type == KeepUpRecurrenceType.daily);
    recurrences.add(KeepUpRecurrence(
        type: KeepUpRecurrenceType.daily,
        startTime: startTime,
        endTime: endTime));
  }

  void addWeeklySchedule(
      {required int weekDay,
      required KeepUpDayTime startTime,
      KeepUpDayTime? endTime}) {
    recurrences.removeWhere((element) =>
        element.type == KeepUpRecurrenceType.weekly &&
        element.weekDay == weekDay);
    recurrences.add(KeepUpRecurrence(
        type: KeepUpRecurrenceType.weekly,
        weekDay: weekDay,
        startTime: startTime,
        endTime: endTime));
  }

  void addMonthlySchedule(
      {required int day,
      required KeepUpDayTime startTime,
      KeepUpDayTime? endTime}) {
    recurrences.removeWhere((element) =>
        element.type == KeepUpRecurrenceType.monthly && element.day == day);
    recurrences.add(KeepUpRecurrence(
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
    recurrences.removeWhere((element) =>
        element.type == KeepUpRecurrenceType.none &&
        element.day == day &&
        element.month == month &&
        element.year == year);
    recurrences.add(KeepUpRecurrence(
        type: KeepUpRecurrenceType.none,
        day: day,
        month: month,
        year: year,
        weekDay: date.weekday,
        startTime: startTime,
        endTime: endTime));
  }
}

class KeepUpGoalCategory {
  static const education = 'Educazione';
  static const sport = 'Sport';
  static const other = 'Altro';
  static const values = [education, sport, other];
}

class KeepUpGoal extends KeepUpEvent {
  int daysPerWeek;
  int hoursPerDay;
  String category;
  String? metadataId;

  KeepUpGoal(
      {String? id,
      required String title,
      required DateTime startDate,
      DateTime? endDate,
      String? description,
      required Color color,
      this.daysPerWeek = 3,
      this.hoursPerDay = 1,
      this.category = KeepUpGoalCategory.education,
      this.metadataId})
      : super(
            id: id,
            title: title,
            startDate: startDate,
            endDate: endDate,
            description: description,
            color: color);

  factory KeepUpGoal.fromEvent(KeepUpEvent event) {
    return KeepUpGoal(
        id: event.id,
        title: event.title,
        description: event.description,
        startDate: event.startDate,
        endDate: event.endDate,
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
    exceptions.add(KeepUpRecurrenceException(
        eventId: eventId, recurrenceId: recurrenceId, onDate: onDate));
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
        id: json[KeepUpExceptionDataModelKey.id],
        eventId: json[KeepUpExceptionDataModelKey.eventId]
            [KeepUpEventDataModelKey.id],
        recurrenceId: json[KeepUpExceptionDataModelKey.recurrenceId]
            [KeepUpEventDataModelKey.id],
        onDate: json[KeepUpExceptionDataModelKey.onDate]);
  }
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
  static const description = 'description';
  static const color = 'color';

  static Map<String, dynamic> pointerTo(String objectId) {
    return {'__type': 'Pointer', 'className': className, 'objectId': objectId};
  }
}

abstract class KeepUpRecurrenceDataModelKey {
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

abstract class KeepUpGoalDataModelKey {
  static const className = 'Goal';
  static const id = 'objectId';
  static const eventId = 'eventId';
  static const category = 'category';
  static const daysPerWeek = 'daysPerWeek';
  static const hoursPerDay = 'hoursPerDay';

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
}

class KeepUpTask {
  String eventId;
  String recurrenceId;
  String title;
  DateTime date;
  KeepUpDayTime startTime, endTime;
  Color color;

  KeepUpTask(
      {required this.eventId,
      required this.recurrenceId,
      required this.title,
      required this.date,
      required this.startTime,
      required this.endTime,
      required this.color});

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
