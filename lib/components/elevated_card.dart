import 'package:flutter/material.dart';

class AppElevatedCard extends StatelessWidget {
  final List<Widget> children;
  final Function()? onTap;

  const AppElevatedCard({Key? key, required this.children, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: GestureDetector(
            onTap: onTap,
            child: Container(
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      blurStyle: BlurStyle.normal,
                      color: Colors.black12,
                      blurRadius: 20.0,
                      spreadRadius: 0.0,
                      offset: Offset(0.0, 0.75),
                    )
                  ],
                ),
                child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(children: children),
                    )))));
  }
}
