import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keep_up/components/navigator.dart';
import 'package:keep_up/constant.dart';
import 'package:keep_up/screens/daily_survey_screen.dart';
import 'package:keep_up/screens/goal_success_screen.dart';
import 'package:keep_up/screens/on_boarding_screen.dart';
import 'package:keep_up/screens/timetable_screen.dart';
import 'package:keep_up/services/notification_service.dart';
import 'package:keep_up/screens/login_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/services/keep_up_api.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);

  await KeepUp.instance.init();

  await NotificationService()
      .init(onNotificationSelected: onNotificationTapped);

  final launchDetails = await NotificationService()
      .notificationsPlugin
      .getNotificationAppLaunchDetails();

  final preferences = await SharedPreferences.getInstance();

  runApp(MyApp(
      payload: launchDetails?.payload,
      firstRun: preferences.getBool(isFirstRunKey)));
}

void onNotificationTapped(String? payload) {
  if (payload == NotificationServiceConstant.surveyPayload) {
    navigatorKey.currentState!
        .pushReplacement(MaterialPageRoute(builder: (context) {
      return const DailySurveyScreen();
    }));
  } else if (payload!
      .startsWith(NotificationServiceConstant.goalCompletionPayload)) {
    navigatorKey.currentState!
        .pushReplacement(MaterialPageRoute(builder: (context) {
      return GoalSuccessScreen(
          goalMetadataId:
              NotificationServiceConstant.extractGoalFromPayload(payload));
    }));
  }
}

class MyApp extends StatefulWidget {
  final String? payload;
  final bool? firstRun;
  const MyApp({Key? key, this.payload, this.firstRun}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
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
                if (widget.payload == null) {
                  return const AppNavigator();
                } else if (widget.payload ==
                    NotificationServiceConstant.surveyPayload) {
                  return const DailySurveyScreen();
                } else if (widget.payload!.startsWith(
                    NotificationServiceConstant.goalCompletionPayload)) {
                  return GoalSuccessScreen(
                      goalMetadataId: NotificationServiceConstant
                          .extractGoalMetadataIdFromPayload(widget.payload!));
                } else {
                  return const AppNavigator();
                }
              } else if (widget.firstRun ?? true) {
                return const OnBoardinScreen();
              } else {
                // home screen
                return const LoginScreen();
              }
            }));
  }
}
