import 'dart:developer';

import 'package:keep_up/constant.dart';
import 'package:flutter/material.dart';
import 'package:keep_up/services/keep_up_api.dart';

class _Task {
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
  void scheduleGoals(List<KeepUpGoal> goals) {
    final tasks = _scheduleGoals(_fixedTasks, goals);
  }

  // pianifica i task dei goal nelle varie settimane e restituisce tutti i task
  // pianificati
  List<_Task> _scheduleGoals(List<_Task> fixedTasks, List<KeepUpGoal> goals,
      {int tries = 10000}) {
    // i task da posizionare
    final pendingTasks = _pendingTasks(goals);
    // media giornaliera di goal task posizionabili
    final dailyAverage = pendingTasks.length / 7;
    // tabella oraria settimanale
    final weekTable = _fillWeekTable(fixedTasks, 8, 20);

    for (int i = 0; i < weekTable.length; ++i) {
      print('[${weekTable[i] ? '/' : ' '}] ${weekDays[i ~/ 24]} ${i % 24}:00');
    }

    // la soluzione migliore e il suo costo relativo
    var bestResult = <_Task>[];
    var bestCost = double.infinity;
    var bestCount = 0;
    // ordina i task preesistenti per ora di inizio
    fixedTasks.sort(
        (a, b) => a.weekDay! * 24 + a.start! - b.weekDay! * 24 - b.start!);
    // fa un numero di tentativi per trovare la soluzione migliore
    for (var i = 0; i < tries; ++i) {
      //print('attempt $i');
      // numero di task assegnati ogni giorno
      final dailyAssigned = List<int>.generate(7, (_) => 0);
      // indice di avanzamento nella tabelle di celle orarie della settimana
      int index = 0;
      // numero di task assegnati finora
      int count = 0;
      // ordina casualmente i task in attesa
      pendingTasks.shuffle();
      // tenta di assegnare ogni task in attesa
      for (var task in pendingTasks) {
        // rianalizza settimana dall'inizio se sfora
        if (index >= weekTable.length) index %= weekTable.length;
        // giorno corrente nella tabella
        int day = index ~/ 24;
        // se il numero di task assegnati nel giorno eccede di troppo la media,
        // allora passa al giorno successivo
        if (dailyAssigned[day] > dailyAverage) {
          ++day;
          index = day * 24;
        }
        // tenta di posizionare il task corrente in tale giornata o successive
        while (index < weekTable.length) {
          // se lo slot è libero, posizione il task e avanza l'indice di tabella
          if (_isWeekTableSlotFree(weekTable, index, task.duration)) {
            task.start = index % 24;
            task.weekDay = index ~/ 24;
            // un'ora in più è riempita per lasciare libertà fra task successivi
            index = index + task.duration + 1;
            ++dailyAssigned[day];
            ++count;
            break;
          }
          // avanza almeno di una posizione
          ++index;
          // posizionato il task, si avanza fino alla prossima cella libera
          while (index < weekTable.length && weekTable[index]) {
            ++index;
          }
        }
      }
      // se sono stati posizionati meno task del previsto in tale soluzione,
      // allora viene scartata
      if (count < pendingTasks.length) {
        continue;
      }
      //print('attempt $i, cost to be computed');
      // calcola il costo della soluzione attuale
      final newCost =
          _costOf(fixedTasks: fixedTasks, pendingTask: pendingTasks);
      // confronta con l'attuale migliore ed eventualmente aggiorna
      // la soluzione migliore
      if (newCost < bestCost) {
        bestCount = count;
        bestCost = newCost;
        bestResult = List.generate(pendingTasks.length, (index) {
          return pendingTasks[index].clone();
        });
      }
    }

    if (bestCount < pendingTasks.length) log('some is missing, fuck');
    // stampa la soluzione migliore
    _costOf(fixedTasks: fixedTasks, pendingTask: bestResult, debug: true);

    return bestResult;
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
    // testa le celle, se almeno una è occupata allora restituisce false
    for (var i = start; i < start + duration; ++i) {
      if (weekTable[i]) {
        return false;
      }
    }
    // tutte le celle libera, allora lo slot è libero
    return true;
  }

  // calcola il costo di una schedulazione, dati i task prefissati, detti
  // 'fixedTasks', e quelli pianificati siccome appartenenti ad obiettivi,
  // detti 'pendingTasks'.
  // La soluzione è tanto migliore quanto minore è il costo restituito
  double _costOf(
      {required List<_Task> fixedTasks,
      required List<_Task> pendingTask,
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
        case KeepUpGoalCategory.education:
          educationHours[task.weekDay!] += task.duration;
          break;
        case KeepUpGoalCategory.sport:
          sportHours[task.weekDay!] += task.duration;
          break;
        default:
          otherHours[task.weekDay!] += task.duration;
      }
    }
    // verifica che non ci sia pià di un goal task nella stessa giornata
    for (final entry in goalDays.entries) {
      if (entry.value.length != goalTasksCount[entry.key]) {
        return double.infinity;
      }
    }
    // calcola il peso o costo come prodotto di varianze di distribuzione
    final cost = _variance(busyHours) *
        _variance(educationHours) *
        _variance(sportHours) *
        _variance(otherHours);

    if (debug) {
      final allTasks = (fixedTasks + pendingTask)
        ..sort(
            (a, b) => a.weekDay! * 24 + a.start! - b.weekDay! * 24 - b.start!);
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
