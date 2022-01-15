import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:keep_up/components/navigator.dart';
import 'package:keep_up/screens/daily_survey_screen.dart';
import 'package:keep_up/screens/personal_growth_screen.dart';
import 'package:keep_up/services/notification_service.dart';
import 'package:keep_up/screens/goal_choice_screen.dart';
import 'package:keep_up/screens/home_screen.dart';
import 'package:keep_up/screens/login_screen.dart';
import 'package:keep_up/screens/register_screen.dart';
import 'package:keep_up/screens/schedule_loading_screen.dart';
import 'package:keep_up/screens/timetable_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/services/polito_api.dart';
import 'package:keep_up/screens/student_sync_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  KeepUp.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    NotificationService().init(onNotificationSelected: (payload) {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DailySurveyScreen()));
    });
    NotificationService().scheduleNotification(
        id: NotificationServiceId.dailySurveyIds[5],
        hour: 23,
        minute: 58,
        title: 'Ehi, come va?',
        body: 'Raccontami come è andata la tua giornata!');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!),
        debugShowCheckedModeBanner: false,
        locale: const Locale('it', 'IT'),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('it', 'IT')],
        title: 'KeepUp',
        theme: AppThemes.lightTheme,
        home: AnimatedSplashScreen.withScreenFunction(
            duration: 1500,
            splashTransition: SplashTransition.fadeTransition,
            pageTransitionType: PageTransitionType.fade,
            splash: SvgPicture.asset('assets/icons/logo.svg'),
            backgroundColor: AppColors.primaryColor,
            screenFunction: () async {
              final currentUser = await KeepUp.instance.getUser();
              if (currentUser != null) {
                return const AppNavigator();
              } else {
                // home screen
                return const LoginScreen();
              }
            }));
  }
}
