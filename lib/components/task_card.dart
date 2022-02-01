import 'dart:developer';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:keep_up/components/progress_bar.dart';
import 'package:keep_up/constant.dart';
import 'package:keep_up/screens/define_goal_screen.dart';
import 'package:keep_up/screens/goal_success_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class AppTaskCard extends StatelessWidget {
  final String title;
  final TimeOfDay time;
  final TimeOfDay? endTime;
  final Color? color;
  final int? completedTasksCount;
  final int? totalTaskCount;
  final bool? active;
  final Function(BuildContext?)? onCancelTask;
  final Function(bool?)? onCheckTask;

  const AppTaskCard(
      {Key? key,
      required this.title,
      required this.time,
      this.endTime,
      this.color,
      this.completedTasksCount,
      this.totalTaskCount,
      this.active,
      this.onCancelTask,
      this.onCheckTask})
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
            child: Slidable(
                startActionPane: ActionPane(
                  motion: const BehindMotion(),
                  dragDismissible: false,
                  children: [
                    SlidableAction(
                      onPressed: onCancelTask,
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete_forever,
                      label: 'Cancella',
                    )
                  ],
                ),
                endActionPane: null,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(children: [
                        Expanded(
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: titleStyle))),
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
                                    value: active,
                                    onChanged: onCheckTask)),
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
                        AppProgressBar(
                            valueColor: Colors.white,
                            value: completedTasksCount!.toDouble() /
                                totalTaskCount!.toDouble()),
                        Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                                '$completedTasksCount/$totalTaskCount completati questa settimana',
                                style: progressStyle))
                      ]
                    ],
                  ),
                ))));
  }
}

class AppGoalCard extends StatelessWidget {
  final String title;
  final Color? color;
  final bool? active;
  final DateTime? finishDate;
  final DateTime? completionDate;
  final Function(BuildContext?)? onDeleteGoal;
  final Function(bool?)? onChecked;
  final Function()? onCompleteBadgeTap;

  const AppGoalCard(
      {Key? key,
      required this.title,
      this.color,
      this.active,
      this.onChecked,
      this.finishDate,
      this.completionDate,
      this.onDeleteGoal,
      this.onCompleteBadgeTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final textColor = completionDate == null
        ? Colors.black
        : AppColors.fieldTextColor.withOpacity(0.3);
    final titleStyle = TextStyle(
        fontSize: Theme.of(context).textTheme.subtitle1?.fontSize,
        fontWeight: FontWeight.bold,
        color: textColor,
        decoration: completionDate != null ? TextDecoration.lineThrough : null);
    final subtitleStyle = TextStyle(
        fontSize: Theme.of(context).textTheme.bodyText1?.fontSize,
        fontWeight: FontWeight.normal,
        color: textColor);
    var cardColor = color ?? AppEventColors.fromEvent(title);

    if (completionDate != null) cardColor = cardColor.withOpacity(0.3);

    if (active != null && !active!) cardColor = AppColors.notSelectedColor;

    return Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: const BoxDecoration(boxShadow: [
          BoxShadow(
            blurStyle: BlurStyle.normal,
            color: Colors.black12,
            blurRadius: 20.0,
            spreadRadius: 0.0,
            offset: Offset(0.0, 0.75),
          )
        ]),
        child: Badge(
            badgeColor: cardColor,
            showBadge: finishDate != null &&
                completionDate == null &&
                DateTime.now()
                        .getDateOnly()
                        .compareTo(finishDate!.getDateOnly()) >=
                    0,
            badgeContent: GestureDetector(
                child: const Icon(Icons.flag, color: Colors.white, size: 24),
                onTap: onCompleteBadgeTap),
            child: Card(
                child: ClipPath(
                    clipper: ShapeBorderClipper(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border(
                                left: BorderSide(color: cardColor, width: 15))),
                        child: Slidable(
                            enabled: active == null,
                            startActionPane: ActionPane(
                              motion: const BehindMotion(),
                              dragDismissible: false,
                              children: [
                                SlidableAction(
                                  onPressed: onDeleteGoal,
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete_forever,
                                  label: 'Cancella',
                                )
                              ],
                            ),
                            endActionPane: null,
                            child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    Row(children: [
                                      Expanded(
                                          child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: false,
                                                  style: titleStyle))),
                                      if (active != null) ...[
                                        const SizedBox(width: 10),
                                        SizedBox(
                                          height: 24.0,
                                          width: 24.0,
                                          child: Transform.scale(
                                              scale: 1.3,
                                              child: Checkbox(
                                                  fillColor: !active!
                                                      ? MaterialStateProperty
                                                          .all(Colors.white)
                                                      : null,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2),
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
                                        Icon(Icons.flag, color: textColor),
                                        const SizedBox(width: 10),
                                        Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                                AppDateTextField.formatter
                                                    .format(finishDate!),
                                                style: subtitleStyle))
                                      ])
                                    ]
                                  ],
                                ))))))));
  }
}
