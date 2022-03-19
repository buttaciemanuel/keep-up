import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/task_card.dart';
import 'package:keep_up/screens/define_goal_screen.dart';
import 'package:keep_up/screens/goal_success_screen.dart';
import 'package:keep_up/screens/schedule_loading_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  _GoalsScreenState createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late final _rescheduleSnackbar = SnackBar(
      action: SnackBarAction(
          label: 'Si',
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) {
                  return const ScheduleLoadingScreen(popWhenCompleted: true);
                }));
          }),
      padding: const EdgeInsets.all(20),
      content: const Text('Vuoi pianificare qualche obiettivo?'));

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return AppNavigationPageLayout(
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
                    .then((_) => setState(() {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(_rescheduleSnackbar);
                        }));
              },
              icon: const Icon(Icons.add, color: AppColors.primaryColor))
        ]),
        SizedBox(height: 0.02 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Definisci i tuoi obiettivi.',
                style: Theme.of(context).textTheme.subtitle1)),
        SizedBox(height: 0.03 * size.height),
        FutureBuilder<KeepUpResponse>(
            future: KeepUp.instance.getAllGoals(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final goals = snapshot.data!.result as List<KeepUpGoal>;

                if (goals.isEmpty) {
                  return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 0.05 * size.height),
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

                return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    child: Column(
                        children: List.generate(goals.length, (index) {
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
                            completionDate: goals[index].completionDate,
                            onDeleteGoal: (context) {
                              KeepUp.instance
                                  .deleteEvent(eventId: goals[index].id!)
                                  .then((_) => setState(() {}));
                            },
                            onCompleteBadgeTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  fullscreenDialog: true,
                                  builder: (context) {
                                    return GoalSuccessScreen(
                                        goalMetadataId:
                                            goals[index].metadataId!);
                                  }));
                            },
                          ));
                    })));
              } else {
                return SizedBox(
                    height: 0,
                    child: Scrollbar(
                        child: ListView.builder(
                            padding: const EdgeInsets.all(5),
                            itemCount: 3,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              return const SkeletonLoader(
                                  child: AppGoalCard(title: ''));
                            })));
              }
            }),
        SizedBox(height: 0.03 * size.height),
      ],
    );
  }
}
