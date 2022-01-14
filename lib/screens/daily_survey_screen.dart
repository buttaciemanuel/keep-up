import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_up/components/navigator.dart';
import 'package:keep_up/components/step_progress_indicator.dart';
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
  static const _buttonTexts = ['Avanti', 'Hai tempo?', 'Avanti', 'Mostra'];
  var _currentStep = 0;
  final _currentDate = DateTime.now().getDateOnly();
  var _selectedMood = 0.0;

  Widget _firstPage() {
    final size = MediaQuery.of(context).size;
    final moodValues = ['Molto male', 'Male', 'Okay', 'Bene', 'Alla grande'];
    return Column(key: const ValueKey(0), children: [
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Come è andata oggi?',
              style: Theme.of(context).textTheme.headline3)),
      SizedBox(height: 0.05 * size.height),
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.center,
          child: Text(moodValues[_selectedMood.round()],
              style: Theme.of(context).textTheme.subtitle1)),
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

  Widget _fourthPage() {
    final size = MediaQuery.of(context).size;
    return Column(key: const ValueKey(3), children: [
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
      Text('1', key: ValueKey(1)),
      Text('2', key: ValueKey(2)),
      _fourthPage()
    ];
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Raccontami...',
              style: Theme.of(context).textTheme.headline1)),
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
      SizedBox(height: 0.05 * size.height),
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
                position: inAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: child,
                ),
              ),
            );
          } else {
            return ClipRect(
              child: SlideTransition(
                position: outAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: child,
                ),
              ),
            );
          }
        },
      )),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () async {
            if (_currentStep < _stepsCount - 1) {
              setState(() {
                ++_currentStep;
              });
            } else {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => const AppNavigator(
                      initialPage: AppNavigator.personalGrowthPage)));
            }
          },
          child: Text(_buttonTexts[_currentStep]),
          style: TextButton.styleFrom(primary: AppColors.primaryColor),
        ),
      ),
      SizedBox(height: 0.05 * size.height)
    ]);
  }
}
