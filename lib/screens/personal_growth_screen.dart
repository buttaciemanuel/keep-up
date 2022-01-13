import 'package:flutter/material.dart';
import 'package:keep_up/components/chart.dart';
import 'package:keep_up/constant.dart';
import 'package:keep_up/style.dart';

class PersonalGrowthScreen extends StatelessWidget {
  const PersonalGrowthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AppNavigationPageLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('La tua crescita',
              style: Theme.of(context).textTheme.headline1)),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Dai uno sguardo ai tuoi progressi.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.05 * size.height),
      AppChart(
          title: 'Performance',
          description: 'Osserva la tua produttività.',
          backgroundColor: AppEventColors.lightBlue),
      SizedBox(height: 0.03 * size.height),
      AppChart(
          title: 'Umore',
          description: 'Osserva il tuo stato d\'animo.',
          backgroundColor: AppEventColors.purple),
      SizedBox(height: 0.05 * size.height),
    ]);
  }
}
