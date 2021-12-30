import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/task_card.dart';
import 'package:keep_up/screens/define_event.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/constant.dart';

class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({Key? key}) : super(key: key);

  @override
  _StudentTimetableScreenState createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen> {
  var _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return AppLayout(
      children: [
        SizedBox(height: 0.05 * size.height),
        Image.asset('assets/images/timetable.png',
            height: 0.25 * size.height, width: 0.7 * size.width),
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
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) {
                      return DefineEventScreen();
                    }));
              },
              icon: const Icon(Icons.add, color: AppColors.primaryColor))
        ]),
        SizedBox(height: 0.03 * size.height),
        Expanded(
            child: SizedBox(
          height: 0,
          child: FutureBuilder<KeepUpResponse>(
              future: KeepUp.instance.getTasks(
                  inDate: DateTime(2021, 12, 6)
                      .add(Duration(days: _currentPageIndex))),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView(
                      children: (snapshot.data!.result as List<KeepUpTask>)
                          .map((task) => GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) {
                                      return DefineEventScreen(fromTask: task);
                                    }));
                              },
                              child: AppTaskCard(
                                  title: task.title,
                                  time: task.startTime.toTimeOfDay(),
                                  endTime: task.endTime.toTimeOfDay())))
                          .toList());
                } else {
                  return ListView(
                    children: [
                      SkeletonLoader(
                          child: AppTaskCard(
                              title: '',
                              time: const TimeOfDay(hour: 0, minute: 0)))
                    ],
                  );
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
        SizedBox(height: 0.05 * size.height),
      ],
    );
  }
}
