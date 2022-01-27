import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/task_card.dart';
import 'package:keep_up/screens/define_event_screen.dart';
import 'package:keep_up/screens/goal_choice_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/constant.dart';

class TimetableScreen extends StatefulWidget {
  final bool skipStudent;
  const TimetableScreen({Key? key, required this.skipStudent})
      : super(key: key);

  @override
  _TimetableScreenState createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late DateTime _weekStartDate;
  var _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _weekStartDate = DateTime.now().getDateOnly();
    _weekStartDate =
        _weekStartDate.subtract(Duration(days: _weekStartDate.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return AppLayout(
      children: [
        SizedBox(height: 0.05 * size.height),
        Row(children: [
          Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(weekDays[_currentPageIndex],
                      style: Theme.of(context).textTheme.headline2))),
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
                          return DefineEventScreen(
                              fromDayIndex: _currentPageIndex);
                        }))
                    .then((_) => setState(() {}));
              },
              icon: const Icon(Icons.add, color: AppColors.primaryColor))
        ]),
        SizedBox(height: 0.03 * size.height),
        Expanded(
            child: SizedBox(
          height: 0,
          child: FutureBuilder<KeepUpResponse>(
              future: KeepUp.instance.getTasks(
                  inDate:
                      _weekStartDate.add(Duration(days: _currentPageIndex))),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final tasks = snapshot.data!.result as List<KeepUpTask>;

                  if (tasks.isEmpty) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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

                  return Scrollbar(
                      child: ListView.builder(
                          padding: const EdgeInsets.all(5),
                          itemCount: tasks.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return GestureDetector(
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(
                                          fullscreenDialog: true,
                                          builder: (context) {
                                            return DefineEventScreen(
                                                fromDayIndex: _currentPageIndex,
                                                fromTask: tasks[index]);
                                          }))
                                      .then((_) => setState(() {}));
                                },
                                child: AppTaskCard(
                                    color: tasks[index].color,
                                    title: tasks[index].title,
                                    time: tasks[index].startTime.toTimeOfDay(),
                                    endTime:
                                        tasks[index].endTime.toTimeOfDay()));
                          }));
                } else {
                  return Scrollbar(
                      child: ListView.builder(
                          padding: const EdgeInsets.all(5),
                          itemCount: 3,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return SkeletonLoader(
                                child: AppTaskCard(
                                    title: '',
                                    time: const TimeOfDay(hour: 0, minute: 0)));
                          }));
                }
              }),
        )),
        SizedBox(height: 0.03 * size.height),
        DotsIndicator(
            dotsCount: weekDays.length,
            position: _currentPageIndex.toDouble(),
            decorator: const DotsDecorator(
              size: Size.fromRadius(7),
              activeSize: Size.fromRadius(7),
              spacing: EdgeInsets.all(7),
              color: AppColors.lightGrey, // Inactive color
              activeColor: AppColors.primaryColor,
            ),
            onTap: (position) {
              setState(() => _currentPageIndex = position.toInt());
            }),
        SizedBox(height: 0.03 * size.height),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.of(context)
                  .pushReplacement(MaterialPageRoute(builder: (context) {
                if (widget.skipStudent) return const GoalChoiceScreen();
                return const StudentGoalChoiceScreen();
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
