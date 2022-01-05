import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:keep_up/components/progress_bar.dart';
import 'package:keep_up/screens/home_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/services/keep_up_scheduler.dart';
import 'package:keep_up/style.dart';

class ScheduleLoadingScreen extends StatefulWidget {
  final backgrounColor = AppColors.primaryColor;

  const ScheduleLoadingScreen({Key? key}) : super(key: key);

  @override
  _ScheduleLoadingScreenState createState() => _ScheduleLoadingScreenState();
}

class _ScheduleLoadingScreenState extends State<ScheduleLoadingScreen>
    with SingleTickerProviderStateMixin {
  late Animation<double> _animation;
  late AnimationController _controller;
  List<KeepUpEvent>? _events;
  List<KeepUpGoal>? _goals;
  static const _downloadSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Ci sono dei problemi nello scaricare i dati'));

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(seconds: 7), vsync: this);
    _animation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _loadData() async {
    if (_events == null || _goals == null) {
      // ottiene tutti gli eventi
      final allEvents = await KeepUp.instance.getAllEvents(getMetadata: true);
      // ottiene tutti i goal creati
      final allGoals = await KeepUp.instance.getAllGoals(getMetadata: false);
      // errore nello scaricare i dati
      if (allEvents.error || allGoals.error) {
        ScaffoldMessenger.of(context).showSnackBar(_downloadSnackbar);
      }
      // salva i dati
      else {
        _events = allEvents.result;
        _goals = allGoals.result;
        // avvia l'animazione
        _controller.animateTo(0.1);
        // avviene la schedulazione
        KeepUpScheduler.fromTimeTable(_events!).scheduleGoals(_goals!);
        // prosegue l'animazione
        _controller.forward().whenComplete(() {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) {
            return const HomeScreen();
          }));
        });
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return FutureBuilder<bool>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return AppLayout(
                backgroundColor: AppColors.primaryColor,
                children: [
                  const Expanded(child: SizedBox()),
                  Image.asset('assets/images/schedule_loading.png',
                      height: 0.5 * size.height, width: 0.8 * size.width),
                  SizedBox(height: 0.01 * size.height),
                  Text('Ad maiora semper',
                      style: Theme.of(context)
                          .textTheme
                          .headline3!
                          .copyWith(color: Colors.black)),
                  SizedBox(height: 0.02 * size.height),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('',
                          style: Theme.of(context)
                              .textTheme
                              .subtitle2!
                              .copyWith(color: Colors.black)),
                      DefaultTextStyle(
                        style: Theme.of(context)
                            .textTheme
                            .subtitle2!
                            .copyWith(color: Colors.black),
                        child: AnimatedTextKit(
                            totalRepeatCount: 1,
                            animatedTexts: [
                              FadeAnimatedText(
                                  'Lascia che ti aiuti a pianificare il tempo'),
                              FadeAnimatedText('Quasi fatto...'),
                              FadeAnimatedText('Finito!'),
                            ]),
                      ),
                    ],
                  ),
                  SizedBox(height: 0.05 * size.height),
                  AppProgressBar(
                      value: _animation.value, valueColor: Colors.black),
                  SizedBox(height: 0.05 * size.height),
                  const Expanded(child: SizedBox()),
                ]);
          } else {
            return AppLayout(
                backgroundColor: AppColors.primaryColor, children: const []);
          }
        });
  }
}
