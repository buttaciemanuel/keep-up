import 'dart:math';

import 'package:flutter/material.dart';
import 'package:keep_up/style.dart';

class AppTaskCard extends StatelessWidget {
  final String title;
  final TimeOfDay time;
  final Color? color;
  final int? completedTasksCount;
  final int? totalTaskCount;
  final bool? active;
  static final _defaultColors = [
    AppColors.primaryColor,
    Colors.green,
    Colors.blue,
    Colors.amber,
    Colors.cyan,
    Colors.indigo,
    Colors.purple
  ];

  const AppTaskCard(
      {Key? key,
      required this.title,
      required this.time,
      this.color,
      this.completedTasksCount,
      this.totalTaskCount,
      this.active})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final cardColor =
        color ?? _defaultColors[title.hashCode % _defaultColors.length];
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
                      child: Text(time.format(context), style: timeStyle)),
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
