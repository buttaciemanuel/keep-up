import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter/material.dart';
import 'package:keep_up/constant.dart';
import 'package:keep_up/screens/register_screen.dart';
import 'package:keep_up/style.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardinScreen extends StatefulWidget {
  const OnBoardinScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardinScreen> createState() => _OnBoardinScreenState();
}

class _OnBoardinScreenState extends State<OnBoardinScreen> {
  static const _buttonTexts = [
    'Continua',
    'Continua',
    'Continua',
    'Continua',
    'Inizia'
  ];
  var _currentStep = 0;
  var _previousStep = 0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    late final _pages = [
      _buildPage(
          index: 0,
          imagePath: 'assets/images/on_boarding_intro.png',
          title: 'Benvenuto su KeepUp',
          text:
              'Ottieni il massimo dalla tua vita studentesca.\nInizia il tuo percorso di crescita personale.'),
      _buildPage(
          index: 1,
          imagePath: 'assets/images/on_boarding_plan.png',
          title: 'Pianifica le tue giornate',
          text:
              'Affidati totalmente alla pianificazione automatica delle tue attività.'),
      _buildPage(
          index: 2,
          imagePath: 'assets/images/on_boarding_goals.png',
          title: 'Realizza i tuoi obiettivi',
          text:
              'Definisci la roadmap dei tuoi obiettivi a breve e lungo termine.'),
      _buildPage(
          index: 3,
          imagePath: 'assets/images/on_boarding_growth.png',
          title: 'Traccia i tuoi progressi',
          text:
              'Segui il tuo percorso di crescita personale.\nConcretizza i tuoi progressi.'),
      _buildPage(
          index: 4,
          imagePath: 'assets/images/on_boarding_community.png',
          title: 'Interagisci con il mondo',
          text:
              'Partecipa alla community di studenti.\nCondividi idee o dubbi.')
    ];
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      AnimatedSwitcher(
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
      ),
      Expanded(child: SizedBox(height: 0.03 * size.height)),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        DotsIndicator(
            dotsCount: _pages.length,
            position: _currentStep.toDouble(),
            decorator: const DotsDecorator(
              size: Size.fromRadius(5),
              activeSize: Size.fromRadius(7),
              spacing: EdgeInsets.all(7),
              color: AppColors.lightGrey, // Inactive color
              activeColor: AppColors.primaryColor,
            ),
            onTap: (position) {
              setState(() {
                _previousStep = _currentStep;
                _currentStep = position.toInt();
              });
            }),
        TextButton(
          onPressed: () async {
            if (_currentStep < _pages.length - 1) {
              setState(() {
                _previousStep = _currentStep;
                ++_currentStep;
              });
            } else {
              final preferences = await SharedPreferences.getInstance();
              preferences.setBool(isFirstRunKey, false);
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) {
                    return const RegisterScreen();
                  }));
            }
          },
          child: Text(_buttonTexts[_currentStep]),
          style: TextButton.styleFrom(primary: AppColors.primaryColor),
        )
      ]),
      SizedBox(height: 0.05 * size.height)
    ]);
  }

  Widget _buildPage(
      {required int index,
      required String imagePath,
      required String title,
      required String text}) {
    final size = MediaQuery.of(context).size;
    return Column(key: ValueKey(index), children: [
      SizedBox(height: 0.1 * size.height),
      Image.asset(imagePath,
          height: 0.5 * size.height, width: 0.8 * size.width),
      Text(title,
          style: Theme.of(context).textTheme.headline3,
          textAlign: TextAlign.center),
      SizedBox(height: 0.02 * size.height),
      Text(text,
          style: Theme.of(context).textTheme.subtitle2,
          textAlign: TextAlign.center)
    ]);
  }
}
