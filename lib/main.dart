import 'package:flutter/material.dart';
import 'package:keep_up/screens/welcome.dart';
import 'package:keep_up/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'My first app',
        theme: ThemeData(
            primaryColor: kPrimaryColor, scaffoldBackgroundColor: Colors.white),
        home: AnimatedSplashScreen.withScreenFunction(
            duration: 1500,
            splashTransition: SplashTransition.fadeTransition,
            pageTransitionType: PageTransitionType.fade,
            splash: SvgPicture.asset('assets/icons/logo.svg'),
            backgroundColor: kPrimaryColor,
            screenFunction: () async {
              return const /*WelcomeScreen()*/ HelloScreen(userName: "Ema");
            }));
  }
}
