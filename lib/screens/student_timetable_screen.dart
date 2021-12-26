import 'package:flutter/material.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:keep_up/components/task_card.dart';
import 'package:keep_up/style.dart';

class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({Key? key}) : super(key: key);

  @override
  _StudentTimetableScreenState createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen> {
  static const _weekDays = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica'
  ];
  var _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return AppLayout(
      children: [
        SizedBox(height: 0.05 * size.height),
        Image.asset('assets/images/timetable.png'),
        SizedBox(height: 0.05 * size.height),
        Row(children: [
          Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(_weekDays[_currentPageIndex],
                      style: Theme.of(context).textTheme.headline2))),
          const IconButton(
              iconSize: 32.0,
              padding: EdgeInsets.zero,
              tooltip: 'Aggiungi',
              onPressed: null,
              icon: Icon(Icons.add, color: AppColors.primaryColor))
        ]),
        SizedBox(height: 0.03 * size.height),
        Expanded(
            child: Container(
          height: 0,
          child: ListView(children: const [
            AppTaskCard(
                title: 'Analisi Matematica I',
                time: TimeOfDay(hour: 10, minute: 1)),
            AppTaskCard(
                title: 'Analisi Matematica I',
                time: TimeOfDay(hour: 10, minute: 1)),
            AppTaskCard(
                title: 'Analisi Matematica I',
                time: TimeOfDay(hour: 10, minute: 1)),
            AppTaskCard(
                title: 'Analisi Matematica I',
                time: TimeOfDay(hour: 10, minute: 1)),
            AppTaskCard(
                title: 'Analisi Matematica I',
                time: TimeOfDay(hour: 10, minute: 1)),
            AppTaskCard(
                title: 'Analisi Matematica I',
                time: TimeOfDay(hour: 10, minute: 1)),
            AppTaskCard(
                title: 'Analisi Matematica I',
                time: TimeOfDay(hour: 10, minute: 1)),
            AppTaskCard(
                title: 'Analisi Matematica I',
                time: TimeOfDay(hour: 10, minute: 1))
          ]),
        )),
        SizedBox(height: 0.03 * size.height),
        DotsIndicator(
            dotsCount: _weekDays.length,
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
