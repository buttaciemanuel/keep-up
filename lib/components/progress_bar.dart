import 'package:flutter/material.dart';
import 'package:keep_up/style.dart';

class AppProgressBar extends StatelessWidget {
  double value;
  Color valueColor;
  Color backgroundColor;

  AppProgressBar(
      {Key? key,
      required this.value,
      this.valueColor = AppColors.primaryColor,
      this.backgroundColor = AppColors.lightGrey})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      width: size.width,
      height: 10,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: LinearProgressIndicator(
          value: value,
          valueColor: AlwaysStoppedAnimation<Color>(valueColor),
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}
