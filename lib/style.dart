import 'package:flutter/material.dart';

abstract class AppColors {
  static Color get primaryColor => const Color(0xFFFF7F00);
  static Color get grey => const Color.fromRGBO(0, 0, 0, 0.5);
  static Color get fieldBackgroundColor => const Color(0xFFF5F4F4);
  static Color get fieldTextColor => const Color.fromRGBO(0, 0, 0, 0.5);
}

abstract class AppThemes {
  static ThemeData get lightTheme => ThemeData(
        primaryColor: AppColors.primaryColor,
        backgroundColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(primary: AppColors.primaryColor)),
        textTheme: TextTheme(
            headline1: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w900, fontSize: 36),
            subtitle1: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w300, fontSize: 20),
            bodyText1: const TextStyle(color: Colors.black, fontSize: 16),
            button: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor)),
      );
}

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: SafeArea(
            child: SizedBox(
      height: size.height,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          /*Positioned(
              top: 0,
              left: 0,
              child: Image.asset('assets/images/blob_top.png',
                  width: size.width * 0.25)),
          Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset('assets/images/blob_bottom.png',
                  width: size.width * 0.25)),*/
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: child)
        ],
      ),
    )));
  }
}
