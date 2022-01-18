import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/task_card.dart';
import 'package:keep_up/screens/define_goal_screen.dart';
import 'package:keep_up/screens/schedule_loading_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _downloadSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Ci sono dei problemi nello scaricare i dati'));

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return AppNavigationPageLayout(
      children: [
        SizedBox(height: 0.05 * size.height),
        Row(children: [
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Il tuo profilo',
                  style: Theme.of(context).textTheme.headline1)),
          const Expanded(child: SizedBox()),
          IconButton(
              iconSize: 32.0,
              padding: EdgeInsets.zero,
              tooltip: 'Impostazioni',
              constraints: const BoxConstraints(),
              onPressed: () {},
              icon: const Icon(Icons.settings, color: AppColors.primaryColor))
        ]),
        SizedBox(height: 0.05 * size.height),
        Row(children: [
          Image.asset('assets/images/avatar_man1.png', width: size.width * 0.3),
          Expanded(child: SizedBox(width: 10)),
          Column(children: [
            Align(
                alignment: Alignment.centerRight,
                child: Text('Emanuel Buttaci',
                    style: Theme.of(context).textTheme.headline3)),
            SizedBox(height: 5),
            Align(
                alignment: Alignment.centerRight,
                child: Text('buttaciemanuel@gmail.com',
                    style: Theme.of(context).textTheme.subtitle2)),
          ])
        ]),
        SizedBox(height: 0.05 * size.height),
        Row(children: [
          Expanded(
              child: Column(children: [
            Text('3', style: Theme.of(context).textTheme.headline2),
            Text('traguardi', style: Theme.of(context).textTheme.subtitle2),
          ])),
          Expanded(
              child: Column(children: [
            Text('6', style: Theme.of(context).textTheme.headline2),
            Text('obiettivi', style: Theme.of(context).textTheme.subtitle2),
          ])),
          Expanded(
              child: Column(children: [
            Text('4', style: Theme.of(context).textTheme.headline2),
            Text('thread', style: Theme.of(context).textTheme.subtitle2),
          ]))
        ]),
      ],
    );
  }
}
