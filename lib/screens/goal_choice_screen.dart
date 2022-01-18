import 'dart:collection';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/task_card.dart';
import 'package:keep_up/screens/define_goal_screen.dart';
import 'package:keep_up/screens/schedule_loading_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/services/keep_up_scheduler.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/constant.dart';

class StudentGoalChoiceScreen extends StatefulWidget {
  const StudentGoalChoiceScreen({Key? key}) : super(key: key);

  @override
  _StudentGoalChoiceScreenState createState() =>
      _StudentGoalChoiceScreenState();
}

class _StudentGoalChoiceScreenState extends State<StudentGoalChoiceScreen> {
  static const _goalCreationSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore nel creare l\'attività'));

  List<KeepUpEvent>? _recommendedGoals;
  final _selectedGoals = HashSet<String>();

  Future<List<KeepUpEvent>> _getRecommendedGoals() async {
    if (_recommendedGoals != null) return _recommendedGoals!;

    final response = await KeepUp.instance.getAllEvents(getMetadata: true);

    _recommendedGoals = [];

    for (final event in response.result!) {
      if (event.category != KeepUpEventCategory.lecture) continue;
      // consiglia l'obiettivo preparazione solo per quegli eventi che erano
      // stati marchiati con la descrizione di lezione
      _recommendedGoals!.add(KeepUpEvent(
          title: 'Studio - ${event.title}',
          startDate: event.startDate,
          endDate: event.endDate,
          color: event.color));
    }

    return _recommendedGoals!;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AppLayout(
      children: [
        SizedBox(height: 0.03 * size.height),
        Image.asset('assets/images/goal_design.png',
            height: 0.25 * size.height, width: 0.5 * size.width),
        SizedBox(height: 0.05 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('I tuoi obiettivi',
                style: Theme.of(context).textTheme.headline1)),
        SizedBox(height: 0.02 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Ho pensato ad alcuni obiettivi per te.',
                style: Theme.of(context).textTheme.subtitle1)),
        SizedBox(height: 0.03 * size.height),
        Expanded(
            child: SizedBox(
                height: 0,
                child: FutureBuilder<List<KeepUpEvent>>(
                    future: _getRecommendedGoals(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final events = snapshot.data!;
                        return Scrollbar(
                            child: ListView.builder(
                                padding: const EdgeInsets.all(5),
                                itemCount: events.length,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  bool isActive = _selectedGoals
                                      .contains(events[index].title);
                                  return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isActive) {
                                            _selectedGoals
                                                .remove(events[index].title);
                                          } else {
                                            _selectedGoals
                                                .add(events[index].title);
                                          }
                                        });
                                      },
                                      child: AppGoalCard(
                                        onChecked: (checked) {
                                          setState(() {
                                            if (checked!) {
                                              _selectedGoals
                                                  .add(events[index].title);
                                            } else {
                                              _selectedGoals
                                                  .remove(events[index].title);
                                            }
                                          });
                                        },
                                        color: events[index].color,
                                        active: isActive,
                                        title: events[index].title,
                                      ));
                                }));
                      } else {
                        return Scrollbar(
                            child: ListView.builder(
                                padding: const EdgeInsets.all(5),
                                itemCount: 3,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return SkeletonLoader(
                                      child: AppGoalCard(title: ''));
                                }));
                      }
                    }))),
        SizedBox(height: 0.03 * size.height),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              if (_recommendedGoals == null) return;
              await _saveSelectedGoals();
              Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(builder: (context) {
                return const GoalChoiceScreen();
              }));
            },
            child: const Text('Continua'),
            style: TextButton.styleFrom(primary: AppColors.primaryColor),
          ),
        ),
        SizedBox(height: 0.05 * size.height),
      ],
    );
  }

  Future<void> _saveSelectedGoals() async {
    for (final recommended in _recommendedGoals!) {
      if (_selectedGoals.contains(recommended.title)) {
        final response = await KeepUp.instance.createGoal(
            KeepUpGoal.fromEvent(recommended)
              ..category = KeepUpEventCategory.education);
        if (response.error) {
          ScaffoldMessenger.of(context).showSnackBar(_goalCreationSnackbar);
        }
      }
    }
  }
}

class GoalChoiceScreen extends StatefulWidget {
  const GoalChoiceScreen({Key? key}) : super(key: key);

  @override
  _GoalChoiceScreenState createState() => _GoalChoiceScreenState();
}

class _GoalChoiceScreenState extends State<GoalChoiceScreen> {
  static const _downloadSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Ci sono dei problemi nello scaricare i dati'));

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return AppLayout(
      children: [
        SizedBox(height: 0.05 * size.height),
        Row(children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Text('I tuoi obiettivi',
                  style: Theme.of(context).textTheme.headline1)),
          const Expanded(child: SizedBox()),
          IconButton(
              iconSize: 32.0,
              padding: EdgeInsets.zero,
              tooltip: 'Aggiungi',
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) {
                          return const DefineGoalScreen();
                        }))
                    .then((_) => setState(() {}));
              },
              icon: const Icon(Icons.add, color: AppColors.primaryColor))
        ]),
        SizedBox(height: 0.02 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Tocca a te. Definisci i tuoi obiettivi.',
                style: Theme.of(context).textTheme.subtitle1)),
        SizedBox(height: 0.03 * size.height),
        Expanded(
            child: SizedBox(
          height: 0,
          child: FutureBuilder<KeepUpResponse>(
              future: KeepUp.instance.getAllGoals(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final goals = snapshot.data!.result as List<KeepUpGoal>;

                  if (goals.isEmpty) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/no_goals.png',
                              height: 0.25 * size.height,
                              width: 0.7 * size.width),
                          SizedBox(height: 0.05 * size.height),
                          Text('Dipingi il tuo futuro!',
                              style: Theme.of(context).textTheme.headline3),
                          SizedBox(height: 0.02 * size.height),
                          Text('Aggiungi qualche obiettivo in alto.',
                              style: Theme.of(context).textTheme.subtitle2)
                        ]);
                  }

                  return Scrollbar(
                      child: ListView.builder(
                          padding: const EdgeInsets.all(5),
                          itemCount: goals.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return GestureDetector(
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(
                                          fullscreenDialog: true,
                                          builder: (context) {
                                            return DefineGoalScreen(
                                                fromGoal: goals[index]);
                                          }))
                                      .then((_) => setState(() {}));
                                },
                                child: AppGoalCard(
                                  color: goals[index].color,
                                  title: goals[index].title,
                                  finishDate: goals[index].endDate,
                                  onDeleteGoal: (context) {
                                    KeepUp.instance
                                        .deleteEvent(eventId: goals[index].id!)
                                        .then((_) => setState(() {}));
                                  },
                                ));
                          }));
                } else {
                  return Scrollbar(
                      child: ListView.builder(
                          padding: const EdgeInsets.all(5),
                          itemCount: 3,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return SkeletonLoader(
                                child: AppGoalCard(title: ''));
                          }));
                }
              }),
        )),
        SizedBox(height: 0.03 * size.height),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(builder: (context) {
                return const ScheduleLoadingScreen();
              }));
            },
            child: const Text('Continua'),
            style: TextButton.styleFrom(primary: AppColors.primaryColor),
          ),
        ),
        SizedBox(height: 0.05 * size.height),
      ],
    );
  }
}
