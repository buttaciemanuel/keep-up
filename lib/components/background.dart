import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SizedBox(
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
    );
  }
}
