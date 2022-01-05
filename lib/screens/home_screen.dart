import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/task_card.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dateTime = DateTime.now();
    final dateFormatter =
        DateFormat.MMMMEEEEd(Localizations.localeOf(context).toLanguageTag());
    return AppLayout(
      children: [
        SizedBox(height: 0.05 * size.height),
        Row(children: [
          Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Today',
                      style: Theme.of(context).textTheme.headline1))),
          IconButton(
              iconSize: 32.0,
              padding: EdgeInsets.zero,
              tooltip: 'Aggiungi',
              onPressed: () {},
              icon: const Icon(Icons.add, color: AppColors.primaryColor))
        ]),
        SizedBox(height: 0.02 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text(dateFormatter.format(dateTime),
                style: Theme.of(context).textTheme.subtitle1!.copyWith(
                    color: AppColors.fieldTextColor,
                    fontWeight: FontWeight.bold))),
        SizedBox(height: 0.03 * size.height),
        Expanded(
            child: SizedBox(
          height: 0,
          child: FutureBuilder<KeepUpResponse>(
              future: KeepUp.instance.getTasks(inDate: dateTime),
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
                                onTap: () {},
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
        SizedBox(height: 0.05 * size.height),
      ],
    );
  }
}
