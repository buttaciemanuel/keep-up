import 'package:flutter/material.dart';

abstract class AppColors {
  static const primaryColor = Color(0xFFFF7F00);
  static const grey = Color.fromRGBO(0, 0, 0, 0.5);
  static const lightGrey = Color.fromRGBO(0, 0, 0, 0.3);
  static const fieldBackgroundColor = Color(0xFFF5F4F4);
  static const fieldTextColor = Color.fromRGBO(0, 0, 0, 0.5);
}

abstract class AppThemes {
  static ThemeData get lightTheme => ThemeData(
      primaryColor: AppColors.primaryColor,
      backgroundColor: Colors.white,
      scaffoldBackgroundColor: Colors.white,
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(primary: AppColors.primaryColor)),
      textTheme: const TextTheme(
          headline1: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w900, fontSize: 36),
          headline2: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w900, fontSize: 32),
          headline3: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24),
          subtitle1: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w300, fontSize: 20),
          bodyText1: TextStyle(color: Colors.black, fontSize: 16),
          button: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor)),
      cardTheme: const CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
          checkColor: MaterialStateProperty.all(Colors.white),
          fillColor: MaterialStateProperty.all(AppColors.lightGrey),
          shape: const CircleBorder(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      snackBarTheme: const SnackBarThemeData(
          contentTextStyle: TextStyle(color: Colors.white, fontSize: 16),
          behavior: SnackBarBehavior.floating,
          actionTextColor: AppColors.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          )),
      timePickerTheme: const TimePickerThemeData(
        hourMinuteTextColor: AppColors.fieldTextColor,
        dayPeriodTextStyle:
            TextStyle(fontWeight: FontWeight.w300, fontSize: 20),
        dialHandColor: AppColors.primaryColor,
        hourMinuteColor: AppColors.fieldBackgroundColor,
        hourMinuteTextStyle:
            TextStyle(fontWeight: FontWeight.w500, fontSize: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10.0)),
        ),
        /*helpTextStyle: TextStyle(
              color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24)*/
      ));
}

class AppLayout extends StatelessWidget {
  final List<Widget> children;
  const AppLayout({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(
      child: LayoutBuilder(builder: (context, constraint) {
        return SingleChildScrollView(
          child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraint.maxHeight),
              child: IntrinsicHeight(
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: children,
                      )))),
        );
      }),
    ));
  }
}
