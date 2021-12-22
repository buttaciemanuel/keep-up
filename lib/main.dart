import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:keep_up/utils/polito_api.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:page_transition/page_transition.dart';
import 'package:keep_up/screens/welcome.dart';
import 'package:keep_up/constants.dart';

void main() async {
  const keyApplicationId = '7lriFNc0muHJqnpBYmDJjkCdBP4ptEXEYaSiIZKR';
  const keyClientKey = 'Hboaa5QGH79mvRQQfEXCUcjXnZlrXSlZk0axzQri';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  WidgetsFlutterBinding.ensureInitialized();

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, autoSendSessionId: true, debug: true);

  var polito = PolitoClient.instance;
  await polito.init();

  if (polito.user != null) {
    log('user already in ${polito.user!.id}');
  } else {
    log('user is not logged');
    await polito.loginUser('s268620', 'luc22ele04');
    await polito.getSchedule();
  }

  await polito.logoutUser();

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
