import 'dart:developer';

import 'package:keep_up/constant.dart';
import 'package:flutter/material.dart';
import 'package:keep_up/services/keep_up_api.dart';

class _Task extends Comparable {
  // identificativo
  String id;
  // durata in ore
  int duration;
  // ora di inizio
  int? start;
  // giorno della settimana con indice [0, 6]
  int? weekDay;
  // categoria di task
  String? category;

  _Task(
      {required this.id,
      required this.duration,
      this.start,
      this.weekDay,
      this.category});

  clone() => _Task(
      id: id,
      duration: duration,
      start: start,
      weekDay: weekDay,
      category: category);

  @override
  int compareTo(other) {
    return weekDay! * 24 +
        start! -
        (other as _Task).weekDay! * 24 -
        other.start!;
  }
}

class _TimeRange {
  final int start, end;
  const _TimeRange({required this.start, required this.end});
}

class _DayPart {
  static const morning = 0;
  static const afternoon = 1;
  static const evening = 2;
  static const allDay = 3;
  static const boundaries = <_TimeRange>[
    // morning
    _TimeRange(start: 0, end: 12),
    // afternoon
    _TimeRange(start: 13, end: 19),
    // evening
    _TimeRange(start: 20, end: 24),
    // all day
    _TimeRange(start: 0, end: 24)
  ];
  static const defaultTaskCategoriesDayParts = <String, _TimeRange>{
    // morning
    KeepUpEventCategory.lecture: _TimeRange(start: 0, end: 12),
    // morning
    KeepUpEventCategory.education: _TimeRange(start: 0, end: 12),
    // afternoon
    KeepUpEventCategory.sport: _TimeRange(start: 13, end: 19),
    // evening
    KeepUpEventCategory.other: _TimeRange(start: 20, end: 24)
  };
}

class _Settings {
  final _TimeRange sleepRange;
  final Map<String, _TimeRange> taskDayParts;

  const _Settings(
      {this.sleepRange = const _TimeRange(start: 22, end: 7),
      this.taskDayParts = _DayPart.defaultTaskCategoriesDayParts});
}

class KeepUpScheduler {
  final List<_Task> _fixedTasks = [];

  KeepUpScheduler.fromTimeTable(List<KeepUpEvent> events) {
    for (final event in events) {
      for (final recurrence in event.recurrences) {
        // la durata è calcolata dall'inizio dell'ora, come se il task,
        // benchè inizi alle 11:20 e finisca alle 12:10
        // è calcolato con un tempo di inizio pari a 11:00
        // e durata pari a 2
        final int startHour = recurrence.startTime.hour;
        final int endHour = recurrence
            .endTime!.hour; // + (recurrence.endTime!.minute > 0 ? 1 : 0);
        // aggiunge le ricorrenze programmate tutti i giorni della settimana o
        // solo un giorno alla settimana
        if (recurrence.type == KeepUpRecurrenceType.daily) {
          _fixedTasks.addAll(List.generate(7, (index) {
            return _Task(
                id: event.title,
                duration: endHour - startHour,
                start: startHour,
                weekDay: index);
          }));
        } else if (recurrence.type == KeepUpRecurrenceType.weekly) {
          _fixedTasks.add(_Task(
              id: event.title,
              duration: endHour - startHour,
              start: startHour,
              weekDay: recurrence.weekDay! - 1));
        }
      }
    }
  }

  // pianifica i task dei goal nelle varie settimane
  void scheduleGoals(List<KeepUpGoal> goals) async {
    final user = await KeepUp.instance.getUser();
    // costruisce le preferenze dell'utente
    final sleepRange = _TimeRange(
        start: user!.sleepStartTime!.hour, end: user.sleepEndTime!.hour);
    var tasksDayParts =
        Map<String, _TimeRange>.from(_DayPart.defaultTaskCategoriesDayParts);
    tasksDayParts[KeepUpEventCategory.education] =
        _DayPart.boundaries[user.studyDayPart!];
    tasksDayParts[KeepUpEventCategory.sport] =
        _DayPart.boundaries[user.sportDayPart!];
    // costruisce tasks e goals
    final tasks = _greedyScheduleGoals(_fixedTasks, goals,
        _Settings(sleepRange: sleepRange, taskDayParts: tasksDayParts));
    final goalTasks = <String, List<_Task>>{};
    // raggruppa i task per goal associato
    for (final task in tasks) {
      goalTasks.putIfAbsent(task.id, () => []);
      goalTasks.update(task.id, (tasks) => tasks..add(task));
    }
    // aggiunge le varie ricorrenze generate dai task dell'algoritmo
    for (var goal in goals) {
      if (!goalTasks.containsKey(goal.title)) continue;
      for (final task in goalTasks[goal.title]!) {
        goal.addWeeklySchedule(
            weekDay: task.weekDay! + 1,
            startTime: KeepUpDayTime(hour: task.start!, minute: 0),
            endTime:
                KeepUpDayTime(hour: task.start! + task.duration, minute: 0));
      }
      // aggiorna il goal sul database
      final response = await KeepUp.instance.updateGoal(goal);

      if (response.error) {
        log(response.message!);
      } else {
        log('${goal.title} updated with ${goal.recurrences.length} recurrences');
      }
    }
    // aggiunge le notifiche circa la data di completamento
    KeepUp.instance.enableGoalsCompletionNotification();
  }

  // pianifica i task dei goal nelle varie settimane e restituisce tutti i task
  // pianificati utilizzando un algoritmo random di ordinamento
  List<_Task> _randomScheduleGoals(
      List<_Task> fixedTasks, List<KeepUpGoal> goals, _Settings settings,
      {int tries = 10000}) {
    // i task da posizionare
    final pendingTasks = _pendingTasks(goals);
    // tabella oraria settimanale
    final fixedWeekTable = _fillWeekTable(
        fixedTasks, settings.sleepRange.end + 1, settings.sleepRange.start - 1);
    // la soluzione migliore e il suo costo relativo
    var bestResult = <_Task>[];
    var bestCost = double.infinity;
    // ordina i task preesistenti per ora di inizio
    fixedTasks.sort();
    // numero di ore occupate ogni giorno con i task fissi
    final busyHours = List<int>.filled(7, 0);
    for (final task in fixedTasks) {
      busyHours[task.weekDay!] += task.duration;
    }
    // fa un numero di tentativi per trovare la soluzione migliore
    for (var i = 0; i < tries; ++i) {
      // fa una copia da modificare della table
      final weekTable = fixedWeekTable.toList();
      // task assegnati
      final assignedTasks = <_Task>[];
      // numero di ore occupate da task da piazzare
      final pendingBusyHours = List<int>.filled(7, 0);
      // giorni in cui un task di un dato obiettivo è svolto
      final goalDays = <String, Set<int>>{};
      // ordina casualmente i task in attesa
      pendingTasks.shuffle();
      // tenta di assegnare ogni task in attesa
      for (var task in pendingTasks) {
        goalDays.putIfAbsent(task.id, () => {});
        // array dell'indice dei giorni ordinato per numero di ore occupate
        final dayIndexes = List<int>.generate(7, (index) => index)
          ..sort((a, b) {
            return (busyHours[a] + pendingBusyHours[a]) -
                (busyHours[b] + pendingBusyHours[b]);
          });
        // per ogni giorno cerca di piazzare le ore
        for (final dayIndex in dayIndexes) {
          if (goalDays[task.id]!.contains(dayIndex)) continue;
          // sistema l'attività rispettando il suo vincolo orario
          for (var index =
                  dayIndex * 24 + settings.taskDayParts[task.category]!.start;
              index < dayIndex * 24 + settings.taskDayParts[task.category]!.end;
              ++index) {
            final start = index % 24, end = start + task.duration;
            // verifica che il task possa essere collocato in posizione
            if (start >= settings.taskDayParts[task.category]!.start &&
                end <= settings.taskDayParts[task.category]!.end &&
                _isWeekTableSlotFree(weekTable, index, task.duration)) {
              // il task viene assegnato in tale slot
              task.start = start;
              task.weekDay = dayIndex;
              assignedTasks.add(task.clone());
              goalDays[task.id]!.add(dayIndex);
              pendingBusyHours[dayIndex] += task.duration;
              break;
            }
          }
          // task sistemato in tal caso, prosegue al prossimo
          if (task.start != null) break;
        }
      }

      // calcola il costo della soluzione attuale
      final newCost = _costOf(
          fixedTasks: fixedTasks,
          pendingTask: assignedTasks,
          unplaced: pendingTasks.length - assignedTasks.length,
          settings: settings);
      // confronta con l'attuale migliore ed eventualmente aggiorna
      // la soluzione migliore
      if (newCost < bestCost && assignedTasks.length > bestResult.length) {
        bestCost = newCost;
        bestResult = assignedTasks;
      }
    }

    log('${bestResult.length}/${pendingTasks.length} positioned');
    // stampa la soluzione migliore
    _costOf(
        fixedTasks: fixedTasks,
        pendingTask: bestResult,
        unplaced: pendingTasks.length - bestResult.length,
        settings: settings,
        debug: true);

    return bestResult;
  }

  // pianifica i task dei goal nelle varie settimane e restituisce tutti i task
  // pianificati utilizzando un algoritmo greedy deterministico
  List<_Task> _greedyScheduleGoals(
      List<_Task> fixedTasks, List<KeepUpGoal> goals, _Settings settings) {
    // i task da posizionare sono ordinati in modo decrescente per durata
    // al fine da collocare prima i più pesanti e poi i più leggeri
    final pendingTasks = _pendingTasks(goals)
      ..sort((a, b) {
        return b.duration - a.duration;
      });
    // tabella oraria settimanale
    final weekTable = _fillWeekTable(
        fixedTasks, settings.sleepRange.end + 1, settings.sleepRange.start - 1);
    // task assegnati
    final assignedTasks = <_Task>[];
    // numero di ore occupate da task da piazzare
    final pendingBusyHours = List<int>.filled(7, 0);
    // giorni in cui un task di un dato obiettivo è svolto
    final goalDays = <String, Set<int>>{};
    // ordina i task preesistenti per ora di inizio
    fixedTasks.sort();
    // numero di ore occupate ogni giorno con i task fissi
    final busyHours = List<int>.filled(7, 0);
    for (final task in fixedTasks) {
      busyHours[task.weekDay!] += task.duration;
    }
    // tenta di assegnare ogni task in attesa
    for (var task in pendingTasks) {
      goalDays.putIfAbsent(task.id, () => {});
      // array dell'indice dei giorni ordinato per numero di ore occupate
      final dayIndexes = List<int>.generate(7, (index) => index)
        ..sort((a, b) {
          return (busyHours[a] + pendingBusyHours[a]) -
              (busyHours[b] + pendingBusyHours[b]);
        });
      // per ogni giorno cerca di piazzare le ore
      for (final dayIndex in dayIndexes) {
        if (goalDays[task.id]!.contains(dayIndex)) continue;
        // sistema l'attività rispettando il suo vincolo orario
        for (var index =
                dayIndex * 24 + settings.taskDayParts[task.category]!.start;
            index < dayIndex * 24 + settings.taskDayParts[task.category]!.end;
            ++index) {
          final start = index % 24, end = start + task.duration;
          // verifica che il task possa essere collocato in posizione
          if (start >= settings.taskDayParts[task.category]!.start &&
              end <= settings.taskDayParts[task.category]!.end &&
              _isWeekTableSlotFree(weekTable, index, task.duration)) {
            // il task viene assegnato in tale slot
            task.start = start;
            task.weekDay = dayIndex;
            assignedTasks.add(task.clone());
            goalDays[task.id]!.add(dayIndex);
            pendingBusyHours[dayIndex] += task.duration;
            break;
          }
        }
        // task sistemato in tal caso, prosegue al prossimo
        if (task.start != null) break;
      }
    }

    log('${assignedTasks.length}/${pendingTasks.length} positioned');
    // stampa la soluzione migliore
    _costOf(
        fixedTasks: fixedTasks,
        pendingTask: assignedTasks,
        unplaced: pendingTasks.length - assignedTasks.length,
        settings: settings,
        debug: true);

    return assignedTasks;
  }

  // ottiene i task associati agli obiettivi in attesa di essere pianificati
  static List<_Task> _pendingTasks(List<KeepUpGoal> goals) {
    final result = <_Task>[];
    // per ogni goal genera il giusto numero di task settimanali da pianificare
    for (final goal in goals) {
      for (var i = 0; i < goal.daysPerWeek; ++i) {
        result.add(_Task(
            id: goal.title,
            duration: goal.hoursPerDay,
            category: goal.category));
      }
    }

    return result;
  }

  // popola la tabella di celle orarie della settimana con i task preesistenti,
  // in cui il valore 'true' significa occupata, mentre 'false' libera
  static List<bool> _fillWeekTable(
      List<_Task> fixedTasks, int minAvailableHour, int maxAvailableHour) {
    const nCells = 7 * 24;
    final table = List<bool>.generate(nCells, (_) => false);
    // per ogni task occupa le sue ore
    for (final task in fixedTasks) {
      // sono occupate le ore del task
      final offset = task.weekDay! * 24 + task.start!;
      for (var i = offset; i < offset + task.duration; ++i) {
        table[i] = true;
      }
      // è occupata un ora in più successiva alla fine per lasciare gioco
      table[offset + task.duration] = true;
    }
    // occupa le ore della notte per i 7 giorni della settimana
    for (var d = 0; d < 7; ++d) {
      for (var h = d * 24; h < d * 24 + minAvailableHour; ++h) {
        table[h] = true;
      }
      for (var h = d * 24 + maxAvailableHour; h < d * 24 + 24; ++h) {
        table[h] = true;
      }
    }

    return table;
  }

  // verifica che la tabella sia libera per l'indice e la durata passati
  bool _isWeekTableSlotFree(List<bool> weekTable, int start, int duration) {
    const timeGap = 0;
    // testa le celle, se almeno una è occupata allora restituisce false
    for (var i = start; i < start + duration; ++i) {
      if (weekTable[i]) {
        return false;
      }
    }
    for (var i = start; i < start + duration + timeGap; ++i) {
      weekTable[i] = true;
    }
    // tutte le celle libere, allora lo slot è libero
    return true;
  }

  // calcola il costo di una schedulazione, dati i task prefissati, detti
  // 'fixedTasks', e quelli pianificati siccome appartenenti ad obiettivi,
  // detti 'pendingTasks'.
  // La soluzione è tanto migliore quanto minore è il costo restituito
  double _costOf(
      {required List<_Task> fixedTasks,
      required List<_Task> pendingTask,
      required int unplaced,
      required _Settings settings,
      bool debug = false}) {
    // ore occupate da ogni genere di attività in un giorno
    final busyHours = List.generate(7, (_) => 0);
    // ore occupate da obiettivi di studio
    final educationHours = List.generate(7, (_) => 0);
    // ore occupate da obiettivi di sport
    final sportHours = List.generate(7, (_) => 0);
    // ore occupate altri generi di obiettivi
    final otherHours = List.generate(7, (_) => 0);
    // giorni in cui un task di un dato obiettivo è svolto
    final goalDays = <String, Set<int>>{};
    // numero di task associati ad ogni obiettivo, dovrebbero coincidere con
    // il numero di giorni diversi in cui tali task sono svolti
    final goalTasksCount = <String, int>{};
    // numero di task mal piazzati
    int misplaced = 0;
    // aggiunge le ore occupate dei task preesistenti
    for (final task in fixedTasks) {
      busyHours[task.weekDay!] += task.duration;
    }
    // aggiunge le ore dei task posizionati nella schedulazione
    for (final task in pendingTask) {
      goalDays.putIfAbsent(task.id, () => <int>{});
      goalTasksCount.putIfAbsent(task.id, () => 0);
      // aggiorna le informazioni
      goalDays.update(task.id, (daysSet) => daysSet..add(task.weekDay!));
      goalTasksCount.update(task.id, (tasksCount) => ++tasksCount);
      busyHours[task.weekDay!] += task.duration;
      // aggiorna le informazioni specifiche
      switch (task.category) {
        case KeepUpEventCategory.education:
          educationHours[task.weekDay!] += task.duration;
          break;
        case KeepUpEventCategory.sport:
          sportHours[task.weekDay!] += task.duration;
          break;
        default:
          otherHours[task.weekDay!] += task.duration;
      }
    }
    // verifica che non ci sia pià di un goal task nella stessa giornata
    for (final entry in goalDays.entries) {
      if (entry.value.length < goalTasksCount[entry.key]!) {
        return double.infinity;
      }
    }
    // verifica che tutti i task rispettino i vincoli orari della propria categoria
    for (final task in pendingTask) {
      if (task.start! < settings.taskDayParts[task.category]!.start ||
          task.start! + task.duration >
              settings.taskDayParts[task.category]!.end) {
        misplaced += 1;
      }
    }
    // calcola il peso o costo come combinazione lineare di varianze e pesi
    final cost = unplaced +
        misplaced +
        _variance(busyHours) +
        _variance(educationHours) +
        _variance(sportHours) +
        _variance(otherHours);

    if (debug) {
      final allTasks = (fixedTasks + pendingTask)..sort();
      for (final task in allTasks) {
        log('[${weekDays[task.weekDay!]} ${task.start}:00-${task.duration + task.start!}:00] ${task.id}');
      }
    }

    return cost;
  }

  static double _variance(List<int> values) {
    var mean = 0.0;
    var variance = 0.0;

    for (final val in values) {
      mean += val;
    }

    mean /= values.length;

    for (final val in values) {
      variance += (val - mean) * (val - mean);
    }

    return variance / values.length;
  }
}
