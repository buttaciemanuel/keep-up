import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/task_card.dart';
import 'package:keep_up/constant.dart';
import 'package:keep_up/screens/define_event_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _initialDate = DateTime.now();
  late DateTime _selectedDate;
  KeepUpDailyTrace? _todayTrace;

  @override
  void initState() {
    super.initState();
    _selectedDate = _initialDate;
    _fetchTodayTrace();
  }

  Future<void> _fetchTodayTrace() async {
    if (_todayTrace == null) {
      // legge la daily trace o ne crea una vuota
      final response =
          await KeepUp.instance.getDailyTrace(inDate: _initialDate);

      setState(() {
        _todayTrace = response.result ??
            KeepUpDailyTrace(date: _initialDate, completedTasks: []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dateFormatter =
        DateFormat.MMMMEEEEd(Localizations.localeOf(context).toLanguageTag());
    return AppScrollView(
      children: [
        SizedBox(height: 0.05 * size.height),
        Row(children: [
          Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Oggi',
                      style: Theme.of(context).textTheme.headline1))),
          IconButton(
              iconSize: 32.0,
              padding: EdgeInsets.zero,
              tooltip: 'Aggiungi',
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) {
                          return DefineEventScreen(
                              fromDate: _selectedDate,
                              showOnlyForDay: true,
                              fromDayIndex: _selectedDate.weekday - 1);
                        }))
                    .then((_) => setState(() {}));
              },
              icon: const Icon(Icons.add, color: AppColors.primaryColor))
        ]),
        SizedBox(height: 0.02 * size.height),
        AppCalendarDaySelector(
          initialDate: _initialDate,
          selectedDate: _selectedDate,
          onSelected: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: FutureBuilder<KeepUpResponse>(
                future: KeepUp.instance.getTasks(inDate: _selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.hasData && _todayTrace != null) {
                    final tasks = snapshot.data!.result as List<KeepUpTask>;

                    if (tasks.isEmpty) {
                      return Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 0.05 * size.height),
                            Image.asset('assets/images/no_tasks.png',
                                height: 0.25 * size.height,
                                width: 0.7 * size.width),
                            SizedBox(height: 0.05 * size.height),
                            Text('Giornata libera!',
                                style: Theme.of(context).textTheme.headline3),
                            SizedBox(height: 0.02 * size.height),
                            Text('Aggiungi qualche evento in alto.',
                                style: Theme.of(context).textTheme.subtitle2)
                          ]);
                    }

                    return Column(
                        mainAxisSize: MainAxisSize.max,
                        children: tasks.map((task) {
                          return GestureDetector(
                              onTap: () {
                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        fullscreenDialog: true,
                                        builder: (context) {
                                          return DefineEventScreen(
                                              fromTask: task,
                                              showOnlyForDay: true,
                                              fromDate: _selectedDate,
                                              fromDayIndex:
                                                  _selectedDate.weekday - 1);
                                        }))
                                    .then((_) => setState(() {}));
                              },
                              child: AppTaskCard(
                                  active: (_selectedDate == _initialDate &&
                                          KeepUpDayTime.fromDateTime(
                                                      _initialDate)
                                                  .compareTo(task.endTime) >
                                              0)
                                      ? _todayTrace!.completedTasks
                                          .contains(task.recurrenceId)
                                      : null,
                                  color: task.color,
                                  title: task.title,
                                  time: task.startTime.toTimeOfDay(),
                                  endTime: task.endTime.toTimeOfDay(),
                                  onCheckTask: (value) {
                                    setState(() {
                                      if (value!) {
                                        _todayTrace!.completedTasks
                                            .add(task.recurrenceId);
                                      } else {
                                        _todayTrace!.completedTasks
                                            .remove(task.recurrenceId);
                                      }
                                    });
                                  },
                                  onCancelTask: (context) {
                                    setState(() {
                                      KeepUp.instance.cancelTask(task: task);
                                    });
                                  }));
                        }).toList());
                  } else {
                    return Column(
                        mainAxisSize: MainAxisSize.max,
                        children: List.generate(
                            3,
                            (index) => SkeletonLoader(
                                child: AppTaskCard(
                                    title: '',
                                    time:
                                        const TimeOfDay(hour: 0, minute: 0)))));
                  }
                }))
      ],
    );
  }
}

class AppCalendarDaySelector extends StatefulWidget {
  final DateTime initialDate;
  final DateTime selectedDate;
  final ScrollController? controller;

  final Function(DateTime) onSelected;

  const AppCalendarDaySelector(
      {Key? key,
      required this.initialDate,
      this.controller,
      required this.onSelected,
      required this.selectedDate})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppCalendarDaySelectorState();
}

class _AppCalendarDaySelectorState extends State<AppCalendarDaySelector> {
  static const _cardWidth = 80.0;
  final _controller = ScrollController();
  DateTime _currentDate = DateTime.now();

  @override
  void initState() {
    _controller.addListener(() {
      setState(() {
        _currentDate = widget.initialDate
            .add(Duration(days: _controller.offset ~/ _cardWidth));
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _monthFormatter =
        DateFormat.MMMM(Localizations.localeOf(context).toLanguageTag());
    return Column(children: [
      Align(
          alignment: Alignment.centerLeft,
          child: Text(_monthFormatter.format(_currentDate).capitalize(),
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: AppColors.fieldTextColor,
                  fontWeight: FontWeight.bold))),
      Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          height: 90,
          child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final currentDate =
                    widget.initialDate.add(Duration(days: index));
                final textStyle = Theme.of(context).textTheme.button!.copyWith(
                    color: widget.selectedDate == currentDate
                        ? Colors.white
                        : AppColors.fieldTextColor,
                    fontSize: 16);
                return GestureDetector(
                    onTap: () {
                      widget.onSelected(currentDate);
                    },
                    child: SizedBox(
                        width: _cardWidth,
                        child: Card(
                          color: widget.selectedDate == currentDate
                              ? AppColors.primaryColor
                              : AppColors.fieldBackgroundColor,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                      weekDays[currentDate.weekday - 1]
                                          .substring(0, 3),
                                      style: textStyle),
                                  const SizedBox(height: 5),
                                  Text(
                                    currentDate.day.toString(),
                                    style: textStyle,
                                  )
                                ]),
                          ),
                        )));
              }))
    ]);
  }
}

extension StringCapitalizeExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
