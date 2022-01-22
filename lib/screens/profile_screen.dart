import 'dart:collection';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:keep_up/components/navigator.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/task_card.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/screens/define_goal_screen.dart';
import 'package:keep_up/screens/edit_profile.dart';
import 'package:keep_up/screens/login_screen.dart';
import 'package:keep_up/screens/oops_screen.dart';
import 'package:keep_up/screens/schedule_loading_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _logoutErrorSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Si è verificato un errore nel logout'));

  KeepUpUser? _user;
  List<KeepUpGoal>? _goals;
  List<int>? _threads = [];

  Future<bool> _fetchData() async {
    final goalsResponse = await KeepUp.instance.getAllGoals();
    // FIXME: read user active threads

    if (goalsResponse.error) {
      return Future.error('');
    } else {
      _goals = goalsResponse.result;
    }

    _user = await KeepUp.instance.getUser();

    return true;
  }

  Widget _loading() {
    final size = MediaQuery.of(context).size;
    return AppNavigationPageLayout(
      children: [
        SizedBox(height: 0.05 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Il tuo profilo',
                style: Theme.of(context).textTheme.headline1)),
        SizedBox(height: 0.05 * size.height),
        Row(children: [
          SkeletonLoader(
              child: Image.asset('assets/images/avatar_man1.png',
                  width: size.width * 0.3)),
          Expanded(child: SizedBox(width: 10)),
          Column(children: [
            Align(
                alignment: Alignment.centerRight,
                child: SkeletonLoader(
                    child: Text('',
                        style: Theme.of(context).textTheme.headline3))),
            SizedBox(height: 5),
            SkeletonLoader(
                child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('',
                        style: Theme.of(context).textTheme.subtitle2))),
          ])
        ]),
        SizedBox(height: 0.05 * size.height),
        Row(children: [
          Expanded(
              child: Column(children: [
            SkeletonLoader(
                child: Text('', style: Theme.of(context).textTheme.headline2)),
            Text('traguardi', style: Theme.of(context).textTheme.subtitle2),
          ])),
          Expanded(
              child: Column(children: [
            SkeletonLoader(
                child: Text('', style: Theme.of(context).textTheme.headline2)),
            Text('obiettivi', style: Theme.of(context).textTheme.subtitle2),
          ])),
          Expanded(
              child: Column(children: [
            SkeletonLoader(
                child: Text('', style: Theme.of(context).textTheme.headline2)),
            Text('thread', style: Theme.of(context).textTheme.subtitle2),
          ]))
        ]),
        SizedBox(height: 0.05 * size.height),
        Row(children: [
          Icon(Icons.edit, color: Colors.black),
          SizedBox(width: 24),
          Text('Modifica profilo',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(color: Colors.black)),
          Expanded(child: SizedBox(width: 10)),
          Icon(Icons.keyboard_arrow_right, color: Colors.black),
        ]),
        //SizedBox(height: 0.02 * size.height),
        Divider(
            height: 0.03 * size.height,
            color: Colors.black,
            thickness: 0.1,
            indent: 48,
            endIndent: 48),
        Row(children: [
          Icon(Icons.notifications, color: Colors.black),
          SizedBox(width: 24),
          Text('Notifiche',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(color: Colors.black)),
          Expanded(child: SizedBox(width: 10)),
          Icon(Icons.keyboard_arrow_right, color: Colors.black),
        ]),
        //SizedBox(height: 0.02 * size.height),
        Divider(
            height: 0.03 * size.height,
            color: Colors.black,
            thickness: 0.1,
            indent: 48,
            endIndent: 48),
        Row(children: [
          Icon(Icons.flag, color: Colors.black),
          SizedBox(width: 24),
          Text('Pianifica obiettivi',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(color: Colors.black)),
          Expanded(child: SizedBox(width: 10)),
          Icon(Icons.keyboard_arrow_right, color: Colors.black)
        ]),
        //SizedBox(height: 0.02 * size.height),
        Divider(
            height: 0.03 * size.height,
            color: Colors.black,
            thickness: 0.1,
            indent: 48,
            endIndent: 48),
        Row(children: [
          Icon(Icons.logout, color: Colors.black),
          SizedBox(width: 24),
          Text('Esci',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(color: Colors.black)),
          Expanded(child: SizedBox(width: 10)),
          Icon(Icons.keyboard_arrow_right, color: Colors.black)
        ]),
        Divider(
            height: 0.03 * size.height,
            color: Colors.black,
            thickness: 0.1,
            indent: 48,
            endIndent: 48),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return FutureBuilder<dynamic>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loading();
          } else if (snapshot.hasError) {
            OopsScreen.show(context);
            return _loading();
          } else if (snapshot.hasData) {
            return AppNavigationPageLayout(
              children: [
                SizedBox(height: 0.05 * size.height),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Il tuo profilo',
                        style: Theme.of(context).textTheme.headline1)),
                SizedBox(height: 0.05 * size.height),
                Row(children: [
                  Image.asset('assets/images/avatar_man1.png',
                      width: size.width * 0.3),
                  Expanded(child: SizedBox(width: 10)),
                  Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                            alignment: Alignment.centerRight,
                            child: Text(_user!.fullname,
                                style: Theme.of(context).textTheme.headline3)),
                        SizedBox(height: 5),
                        Align(
                            alignment: Alignment.centerRight,
                            child: Text(_user!.email,
                                style: Theme.of(context).textTheme.subtitle2)),
                      ])
                ]),
                SizedBox(height: 0.05 * size.height),
                Row(children: [
                  Expanded(
                      child: Column(children: [
                    Text('0', style: Theme.of(context).textTheme.headline2),
                    Text('traguardi',
                        style: Theme.of(context).textTheme.subtitle2),
                  ])),
                  Expanded(
                      child: Column(children: [
                    Text(_goals!.length.toString(),
                        style: Theme.of(context).textTheme.headline2),
                    Text('obiettivi',
                        style: Theme.of(context).textTheme.subtitle2),
                  ])),
                  Expanded(
                      child: Column(children: [
                    Text(_threads!.length.toString(),
                        style: Theme.of(context).textTheme.headline2),
                    Text('thread',
                        style: Theme.of(context).textTheme.subtitle2),
                  ]))
                ]),
                SizedBox(height: 0.05 * size.height),
                GestureDetector(
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) {
                                return const EditProfileScreen();
                              }))
                          .then((_) => setState(() {}));
                    },
                    child: Row(children: [
                      Icon(Icons.edit, color: Colors.black),
                      SizedBox(width: 24),
                      Text('Modifica profilo',
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(color: Colors.black)),
                      Expanded(child: SizedBox(width: 10)),
                      Icon(Icons.keyboard_arrow_right, color: Colors.black),
                    ])),
                Divider(
                    height: 0.03 * size.height,
                    color: Colors.black,
                    thickness: 0.1,
                    indent: 48,
                    endIndent: 48),
                Row(children: [
                  Icon(Icons.notifications, color: Colors.black),
                  SizedBox(width: 24),
                  Text('Notifiche',
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          ?.copyWith(color: Colors.black)),
                  Expanded(child: SizedBox(width: 10)),
                  Icon(Icons.keyboard_arrow_right, color: Colors.black),
                ]),
                Divider(
                    height: 0.03 * size.height,
                    color: Colors.black,
                    thickness: 0.1,
                    indent: 48,
                    endIndent: 48),
                GestureDetector(
                    onTap: () {
                      AppBottomDialog.showBottomDialog(
                          context: context,
                          title: 'Pianifica obiettivi',
                          body:
                              'Vuoi pianificare qualche obiettivo nel futuro?',
                          confirmText: 'Si',
                          confirmPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) {
                                      return const ScheduleLoadingScreen(
                                          popWhenCompleted: true);
                                    }))
                                .then((_) => setState(() {}));
                          },
                          cancelText: 'Annulla');
                    },
                    child: Row(children: [
                      Icon(Icons.flag, color: Colors.black),
                      SizedBox(width: 24),
                      Text('Pianifica obiettivi',
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(color: Colors.black)),
                      Expanded(child: SizedBox(width: 10)),
                      Icon(Icons.keyboard_arrow_right, color: Colors.black)
                    ])),
                Divider(
                    height: 0.03 * size.height,
                    color: Colors.black,
                    thickness: 0.1,
                    indent: 48,
                    endIndent: 48),
                GestureDetector(
                    onTap: () {
                      AppBottomDialog.showBottomDialog(
                          context: context,
                          title: 'Esci',
                          body: 'Sei sicuro di voler effettuare il logout?',
                          confirmText: 'Si',
                          confirmPressed: () async {
                            final response = await KeepUp.instance.logout();
                            Navigator.of(context, rootNavigator: true).pop();
                            if (response.error) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(_logoutErrorSnackbar);
                            } else {
                              Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (c) => const LoginScreen()),
                                  (route) => false);
                            }
                          },
                          cancelText: 'Annulla');
                    },
                    child: Row(children: [
                      Icon(Icons.logout, color: Colors.black),
                      SizedBox(width: 24),
                      Text('Esci',
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(color: Colors.black)),
                      Expanded(child: SizedBox(width: 10)),
                      Icon(Icons.keyboard_arrow_right, color: Colors.black)
                    ])),
                Divider(
                    height: 0.03 * size.height,
                    color: Colors.black,
                    thickness: 0.1,
                    indent: 48,
                    endIndent: 48),
              ],
            );
          } else {
            return _loading();
          }
        });
  }
}

class AppBottomDialog {
  static void showBottomDialog(
      {required BuildContext context,
      required String title,
      required String body,
      List<Widget>? children,
      required String confirmText,
      required String cancelText,
      Function()? confirmPressed,
      Function()? cancelPressed}) {
    final size = MediaQuery.of(context).size;

    defaultAction() {
      Navigator.of(context, rootNavigator: true).pop();
    }

    showGeneralDialog(
      barrierLabel: "showGeneralDialog",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      context: context,
      pageBuilder: (context, _, __) {
        return Align(
            alignment: Alignment.bottomCenter,
            child: IntrinsicHeight(
              child: Container(
                width: double.maxFinite,
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(title,
                            style: Theme.of(context).textTheme.headline3)),
                    SizedBox(height: 0.02 * size.height),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(body,
                            style: Theme.of(context).textTheme.bodyText1)),
                    SizedBox(height: 0.03 * size.height),
                    if (children != null) ...[
                      Scaffold(body: Column(children: children)),
                      SizedBox(height: 0.03 * size.height),
                    ],
                    Row(children: [
                      Expanded(
                          child: Container(
                        width: double.maxFinite,
                        decoration: const BoxDecoration(
                          color: AppColors.fieldBackgroundColor,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: TextButton(
                          onPressed: cancelPressed ?? defaultAction,
                          child: Center(
                            child: Text(
                              cancelText,
                              style: Theme.of(context)
                                  .textTheme
                                  .button!
                                  .copyWith(
                                      color: AppColors.fieldTextColor,
                                      fontSize: Theme.of(context)
                                          .textTheme
                                          .bodyText1
                                          ?.fontSize),
                            ),
                          ),
                        ),
                      )),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Container(
                        width: double.maxFinite,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: TextButton(
                          onPressed: confirmPressed ?? defaultAction,
                          child: Center(
                            child: Text(
                              confirmText,
                              style: Theme.of(context)
                                  .textTheme
                                  .button!
                                  .copyWith(
                                      color: Colors.white,
                                      fontSize: Theme.of(context)
                                          .textTheme
                                          .bodyText1
                                          ?.fontSize),
                            ),
                          ),
                        ),
                      ))
                    ])
                  ],
                ),
              ),
            ));
      },
      transitionBuilder: (_, animation1, __, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
          ).animate(animation1),
          child: child,
        );
      },
    );
  }
}
