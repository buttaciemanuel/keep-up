import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_up/components/navigator.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/slider_input_field.dart';
import 'package:keep_up/components/step_progress_indicator.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/screens/home_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class DailySurveyScreen extends StatefulWidget {
  const DailySurveyScreen({Key? key}) : super(key: key);

  @override
  _DailySurveyScreenState createState() => _DailySurveyScreenState();
}

class _DailySurveyScreenState extends State<DailySurveyScreen> {
  static const _stepsCount = 4;
  static const _buttonTexts = ['Continua', 'Hai tempo?', 'Continua', 'Mostra'];
  var _currentStep = 0;
  var _previousStep = 0;
  final _currentDate = DateTime.now().getDateOnly();
  var _selectedMood = 2.0;
  List<KeepUpTask>? _todayTasks;
  KeepUpDailyTrace? _todayTrace;
  List<KeepUpGoal>? _ratedGoals;
  final _taskRatings = <String, double>{};
  final _personalReflectionController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<bool> _fetchTodayInfo() async {
    if (_todayTrace == null) {
      final tasksResponse =
          await KeepUp.instance.getTasks(inDate: _currentDate);
      final traceResponse =
          await KeepUp.instance.getDailyTrace(inDate: _currentDate);
      final goalResponse = await KeepUp.instance.getAllGoals();
      // legge la daily trace o ne crea una vuota
      _todayTasks = tasksResponse.result ?? [];
      _todayTrace = traceResponse.result ??
          KeepUpDailyTrace(date: _currentDate, completedTasks: []);
      // utilizza sono i task associati a dei goal programmati
      _todayTasks!.removeWhere((task) => task.totalWeeklyCount == null);
      // crea il set di goal
      final goalSet = _todayTasks!.map((t) => t.eventId).toSet();
      // preleva i goal di oggi
      _ratedGoals = goalResponse.result
          ?.where((goal) => goalSet.contains(goal.id))
          .toList();
      // scrive le informazioni
      setState(() {
        if (_todayTrace!.mood != null) {
          _selectedMood = _todayTrace!.mood!.toDouble();
        }
        if (_todayTrace!.notes != null) {
          _personalReflectionController.text = _todayTrace!.notes!;
        }
      });
    }

    return true;
  }

  Future _saveDataInBackground() async {
    // ritenta l'acquisizione del today trace se non ancora fatta
    await _fetchTodayInfo();
    _todayTrace!.mood = _selectedMood.round();
    _todayTrace!.notes = _personalReflectionController.text;
    // aggiorna
    await KeepUp.instance.updateDailyTrace(_todayTrace!);
    // aggiorna le valutazioni sugli obiettivi con media
    for (final goal in _ratedGoals!) {
      final newCount = goal.ratingsCount! + 1;
      goal.rating =
          (goal.rating! * goal.ratingsCount! + _taskRatings[goal.id!]!) /
              newCount;
      goal.ratingsCount = newCount;
      // aggiorna
      KeepUp.instance.updateGoal(goal);
    }
  }

  Widget _firstPage() {
    const imageSources = [
      'assets/images/very_sad_face.png',
      'assets/images/sad_face.png',
      'assets/images/okay_face.png',
      'assets/images/happy_face.png',
      'assets/images/very_happy_face.png'
    ];
    final size = MediaQuery.of(context).size;
    final moodValues = ['Molto male', 'Male', 'Okay', 'Bene', 'Alla grande'];
    return Column(key: const ValueKey(0), children: [
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Come è andata oggi?',
              style: Theme.of(context).textTheme.headline3)),
      SizedBox(height: 0.05 * size.height),
      AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Image.asset(imageSources[_selectedMood.round()],
              key: Key(imageSources[_selectedMood.round()]),
              height: 0.25 * size.height,
              width: 0.7 * size.width)),
      SizedBox(height: 0.05 * size.height),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Align(
            key: Key(imageSources[_selectedMood.round()]),
            alignment: Alignment.center,
            child: Text(moodValues[_selectedMood.round()],
                style: Theme.of(context).textTheme.subtitle1)),
      ),
      SizedBox(height: 0.02 * size.height),
      Slider(
        value: _selectedMood,
        min: 0,
        max: (moodValues.length - 1).toDouble(),
        divisions: moodValues.length - 1,
        onChanged: (value) {
          setState(() => _selectedMood = value);
        },
      )
    ]);
  }

  Widget _secondPage() {
    final size = MediaQuery.of(context).size;
    const double maxRating = 4;
    const double defaultRating = 2;
    final ratingValues = ['Pessimo', 'Male', 'Okay', 'Bene', 'Ottimo'];

    return FutureBuilder<bool>(
        key: const ValueKey(1),
        future: _fetchTodayInfo(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(children: [
              if (_todayTasks!.isEmpty) ...[
                SizedBox(height: 0.05 * size.height),
                Image.asset('assets/images/no_tasks.png',
                    height: 0.25 * size.height, width: 0.7 * size.width),
                SizedBox(height: 0.05 * size.height),
                Text('Giornata libera!',
                    style: Theme.of(context).textTheme.headline3),
                SizedBox(height: 0.02 * size.height),
                Text('Oggi nessun evento da valutare.',
                    style: Theme.of(context).textTheme.subtitle2)
              ] else ...[
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Come valuti queste attività, oggi?',
                        style: Theme.of(context).textTheme.headline3)),
                SizedBox(height: 0.03 * size.height),
                Column(
                    children: List.generate(_todayTasks!.length, (index) {
                  _taskRatings.putIfAbsent(
                      _todayTasks![index].eventId, () => defaultRating);
                  return Container(
                      margin:
                          EdgeInsets.symmetric(vertical: 0.01 * size.height),
                      child: SliderTheme(
                          data: SliderThemeData.fromPrimaryColors(
                              primaryColor: _todayTasks![index].color,
                              primaryColorDark: Colors.black,
                              primaryColorLight: Colors.white,
                              valueIndicatorTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 20)),
                          child: SliderInputField(
                              displayBuilder: (value) =>
                                  ratingValues[value.round()],
                              label: _todayTasks![index].title,
                              value: _taskRatings[_todayTasks![index].eventId]!,
                              min: 0,
                              max: maxRating,
                              onChanged: (newValue) => setState(() {
                                    _taskRatings.update(
                                        _todayTasks![index].eventId,
                                        (_) => newValue);
                                  }))));
                }))
              ]
            ]);
          } else {
            return Column(children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Come valuti queste attività, oggi?',
                      style: Theme.of(context).textTheme.headline3)),
              SizedBox(height: 0.03 * size.height),
              SkeletonLoader(
                child: SliderInputField(
                    label: '',
                    value: 0,
                    min: 0,
                    max: maxRating,
                    onChanged: (_) {}),
              ),
              SizedBox(height: 0.02 * size.height),
              SkeletonLoader(
                child: SliderInputField(
                    label: '',
                    value: 0,
                    min: 0,
                    max: maxRating,
                    onChanged: (_) {}),
              ),
              SizedBox(height: 0.02 * size.height)
            ]);
          }
        });
  }

  Widget _thirdPage() {
    final size = MediaQuery.of(context).size;
    return Column(key: const ValueKey(2), children: [
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Rifletti su di te',
              style: Theme.of(context).textTheme.headline3)),
      SizedBox(height: 0.03 * size.height),
      AppTextField(
          controller: _personalReflectionController,
          isTextArea: true,
          textAreaLines: 12,
          label: 'Riflessione personale',
          hint:
              'Prova a rispondere...\nCosa ho imparato oggi?\nQuali obiettivi ho raggiunto?\nSono soddisfatto del mio stile di vita?')
    ]);
  }

  Widget _fourthPage() {
    final size = MediaQuery.of(context).size;
    return Column(key: const ValueKey(3), children: [
      SizedBox(height: 0.03 * size.height),
      Image.asset('assets/images/survey.png',
          height: 0.3 * size.height, width: 0.7 * size.width),
      SizedBox(height: 0.05 * size.height),
      Text('Grazie per il tuo tempo!',
          style: Theme.of(context).textTheme.headline3),
      SizedBox(height: 0.02 * size.height),
      Text('Ho appena aggiornato i tuoi progressi.',
          style: Theme.of(context).textTheme.subtitle2),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final _dayFormatter =
        DateFormat.yMMMMEEEEd(Localizations.localeOf(context).toLanguageTag());
    final size = MediaQuery.of(context).size;
    late final _pages = [
      _firstPage(),
      _secondPage(),
      _thirdPage(),
      _fourthPage()
    ];
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Row(children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Raccontami...',
                style: Theme.of(context).textTheme.headline1)),
        const Expanded(child: SizedBox(width: 10)),
        IconButton(
            iconSize: 32.0,
            padding: EdgeInsets.zero,
            tooltip: 'Esci',
            constraints: const BoxConstraints(),
            onPressed: () async {
              await _saveDataInBackground();
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) => const AppNavigator()));
            },
            icon: const Icon(Icons.close, color: AppColors.grey))
      ]),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text(_dayFormatter.format(_currentDate).capitalize(),
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: AppColors.fieldTextColor,
                  fontWeight: FontWeight.bold))),
      SizedBox(height: 0.03 * size.height),
      StepProgressIndicator(
          stepsCount: _stepsCount - 1, selectedStepsCount: _currentStep),
      SizedBox(height: 0.03 * size.height),
      Expanded(
          child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _pages[_currentStep],
        transitionBuilder: (child, animation) {
          final inAnimation = Tween<Offset>(
                  begin: const Offset(1.0, 0.0), end: const Offset(0.0, 0.0))
              .animate(animation);
          final outAnimation = Tween<Offset>(
                  begin: const Offset(-1.0, 0.0), end: const Offset(0.0, 0.0))
              .animate(animation);

          if (child.key == ValueKey(_currentStep)) {
            return ClipRect(
              child: SlideTransition(
                position:
                    _currentStep > _previousStep ? inAnimation : outAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: child,
                ),
              ),
            );
          } else {
            return ClipRect(
              child: SlideTransition(
                position:
                    _currentStep > _previousStep ? outAnimation : inAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: child,
                ),
              ),
            );
          }
        },
      )),
      Row(children: [
        if (_currentStep > 0) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () async {
                setState(() {
                  _previousStep = _currentStep;
                  --_currentStep;
                });
              },
              child: const Text('Indietro'),
              style: TextButton.styleFrom(primary: AppColors.grey),
            ),
          )
        ],
        const Expanded(child: SizedBox(width: 10)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {
              if (_currentStep < _stepsCount - 1) {
                setState(() {
                  _previousStep = _currentStep;
                  ++_currentStep;
                });
              } else {
                await _saveDataInBackground();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => const AppNavigator(
                        initialPage: AppNavigator.personalGrowthPage)));
              }
            },
            child: Text(_buttonTexts[_currentStep]),
            style: TextButton.styleFrom(primary: AppColors.primaryColor),
          ),
        )
      ]),
      SizedBox(height: 0.05 * size.height)
    ]);
  }
}
