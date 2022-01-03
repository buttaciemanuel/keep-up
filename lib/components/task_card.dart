import 'dart:math';

import 'package:flutter/material.dart';
import 'package:keep_up/constant.dart';
import 'package:keep_up/screens/define_goal.dart';
import 'package:keep_up/style.dart';

class AppTaskCard extends StatelessWidget {
  String title;
  TimeOfDay time;
  TimeOfDay? endTime;
  Color? color;
  int? completedTasksCount;
  int? totalTaskCount;
  bool? active;

  AppTaskCard(
      {Key? key,
      required this.title,
      required this.time,
      this.endTime,
      this.color,
      this.completedTasksCount,
      this.totalTaskCount,
      this.active})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final cardColor = color ?? AppEventColors.fromEvent(title);
    final titleStyle = TextStyle(
        fontSize: Theme.of(context).textTheme.subtitle1?.fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white);
    final timeStyle = TextStyle(
        fontSize: Theme.of(context).textTheme.bodyText1?.fontSize,
        fontWeight: FontWeight.normal,
        color: Colors.white);
    final progressStyle = TextStyle(
        fontSize: Theme.of(context).textTheme.bodyText2?.fontSize,
        fontWeight: FontWeight.normal,
        color: Colors.white);
    return Center(
        child: Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(title, style: titleStyle))),
                    if (active != null) ...[
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 24.0,
                        width: 24.0,
                        child: Transform.scale(
                            scale: 1.3,
                            child: Checkbox(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                value: true,
                                onChanged: null)),
                      )
                    ]
                  ]),
                  SizedBox(height: 0.005 * size.height),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          time.format(context) +
                              (endTime != null
                                  ? ' → ${endTime!.format(context)}'
                                  : ''),
                          style: timeStyle)),
                  if (completedTasksCount != null &&
                      totalTaskCount != null) ...[
                    SizedBox(height: 0.01 * size.height),
                    LinearProgressIndicator(
                        backgroundColor: AppColors.lightGrey,
                        color: Colors.white,
                        minHeight: 10,
                        value: completedTasksCount!.toDouble() /
                            totalTaskCount!.toDouble()),
                    SizedBox(height: 0.01 * size.height),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            '$completedTasksCount/$totalTaskCount completati questa settimana',
                            style: progressStyle))
                  ]
                ],
              ),
            )));
  }
}

class AppGoalCard extends StatelessWidget {
  String title;
  Color? color;
  bool? active;
  DateTime? finishDate;
  Function(bool?)? onChecked;

  AppGoalCard(
      {Key? key,
      required this.title,
      this.color,
      this.active,
      this.onChecked,
      this.finishDate})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final titleStyle = TextStyle(
        fontSize: Theme.of(context).textTheme.subtitle1?.fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white);
    final subtitleStyle = TextStyle(
        fontSize: Theme.of(context).textTheme.bodyText1?.fontSize,
        fontWeight: FontWeight.normal,
        color: Colors.white);
    var cardColor = color ?? AppEventColors.fromEvent(title);

    if (active != null && !active!) cardColor = AppColors.notSelectedColor;

    return Center(
        child: Card(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(title, style: titleStyle))),
                    if (active != null) ...[
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 24.0,
                        width: 24.0,
                        child: Transform.scale(
                            scale: 1.3,
                            child: Checkbox(
                                fillColor: !active!
                                    ? MaterialStateProperty.all(Colors.white)
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                value: active,
                                onChanged: onChecked)),
                      ),
                    ],
                  ]),
                  SizedBox(height: 0.005 * size.height),
                  if (finishDate != null) ...[
                    SizedBox(height: 0.005 * size.height),
                    Row(children: [
                      const Icon(Icons.flag, color: Colors.white),
                      const SizedBox(width: 10),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              AppDateTextField.formatter.format(finishDate!),
                              style: subtitleStyle))
                    ])
                  ]
                ],
              ),
            )));
  }
}
