import 'package:flutter/material.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/screens/change_password_screen.dart';
import 'package:keep_up/screens/edit_profile.dart';
import 'package:keep_up/screens/login_screen.dart';
import 'package:keep_up/screens/notification_settings.dart';
import 'package:keep_up/screens/oops_screen.dart';
import 'package:keep_up/screens/schedule_loading_screen.dart';
import 'package:keep_up/screens/user_threads_screen.dart';
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
  List<KeepUpThread>? _threads;

  Future<bool> _fetchData() async {
    final goalsResponse = await KeepUp.instance.getAllGoals();
    final threadsResponse =
        await KeepUp.instance.getUserThreads(asCreator: true);

    if (goalsResponse.error) {
      return Future.error('');
    } else {
      _goals = goalsResponse.result;
    }

    if (threadsResponse.error) {
      return Future.error('');
    } else {
      _threads = threadsResponse.result;
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
          const SizedBox(width: 32),
          Expanded(
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader(
                            child: Text('',
                                style: Theme.of(context).textTheme.headline3)),
                        const SizedBox(height: 5),
                        Text('', style: Theme.of(context).textTheme.subtitle2),
                      ])))
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
          const Icon(Icons.edit, color: Colors.black),
          const SizedBox(width: 24),
          Text('Modifica profilo',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(color: Colors.black)),
          const Expanded(child: SizedBox(width: 10)),
          const Icon(Icons.keyboard_arrow_right, color: Colors.black),
        ]),
        Divider(
            height: 0.03 * size.height,
            color: Colors.black,
            thickness: 0.1,
            indent: 48,
            endIndent: 48),
        Row(children: [
          const Icon(Icons.lock, color: Colors.black),
          const SizedBox(width: 24),
          Text('Cambia password',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(color: Colors.black)),
          const Expanded(child: SizedBox(width: 10)),
          const Icon(Icons.keyboard_arrow_right, color: Colors.black),
        ]),
        Divider(
            height: 0.03 * size.height,
            color: Colors.black,
            thickness: 0.1,
            indent: 48,
            endIndent: 48),
        Row(children: [
          const Icon(Icons.notifications, color: Colors.black),
          const SizedBox(width: 24),
          Text('Notifiche',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(color: Colors.black)),
          const Expanded(child: SizedBox(width: 10)),
          const Icon(Icons.keyboard_arrow_right, color: Colors.black),
        ]),
        Divider(
            height: 0.03 * size.height,
            color: Colors.black,
            thickness: 0.1,
            indent: 48,
            endIndent: 48),
        Row(children: [
          const Icon(Icons.flag, color: Colors.black),
          const SizedBox(width: 24),
          Text('Pianifica obiettivi',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(color: Colors.black)),
          const Expanded(child: SizedBox(width: 10)),
          const Icon(Icons.keyboard_arrow_right, color: Colors.black)
        ]),
        Divider(
            height: 0.03 * size.height,
            color: Colors.black,
            thickness: 0.1,
            indent: 48,
            endIndent: 48),
        Row(children: [
          const Icon(Icons.logout, color: Colors.black),
          const SizedBox(width: 24),
          Text('Esci',
              style: Theme.of(context)
                  .textTheme
                  .bodyText1
                  ?.copyWith(color: Colors.black)),
          const Expanded(child: SizedBox(width: 10)),
          const Icon(Icons.keyboard_arrow_right, color: Colors.black)
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
                  const SizedBox(width: 32),
                  Expanded(
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_user!.fullname,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style:
                                        Theme.of(context).textTheme.headline3),
                                const SizedBox(height: 5),
                                Text(_user!.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style:
                                        Theme.of(context).textTheme.subtitle2),
                              ])))
                ]),
                SizedBox(height: 0.05 * size.height),
                Row(children: [
                  Expanded(
                      child: Column(children: [
                    Text(
                        _goals!
                            .where((g) => g.completionDate != null)
                            .length
                            .toString(),
                        style: Theme.of(context).textTheme.headline2),
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
                      child: GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .push(MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) {
                                      return const UserThreadsScreen();
                                    }))
                                .then((_) => setState(() {}));
                          },
                          child: Column(children: [
                            Text(_threads!.length.toString(),
                                style: Theme.of(context).textTheme.headline2),
                            Text('thread',
                                style: Theme.of(context).textTheme.subtitle2),
                          ])))
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
                      const Icon(Icons.edit, color: Colors.black),
                      const SizedBox(width: 24),
                      Text('Modifica profilo',
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(color: Colors.black)),
                      const Expanded(child: SizedBox(width: 10)),
                      const Icon(Icons.keyboard_arrow_right,
                          color: Colors.black),
                    ])),
                Divider(
                    height: 0.03 * size.height,
                    color: Colors.black,
                    thickness: 0.1,
                    indent: 48,
                    endIndent: 48),
                GestureDetector(
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) {
                                return const ChangePasswordScreen();
                              }))
                          .then((_) => setState(() {}));
                    },
                    child: Row(children: [
                      const Icon(Icons.lock, color: Colors.black),
                      const SizedBox(width: 24),
                      Text('Cambia password',
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(color: Colors.black)),
                      const Expanded(child: SizedBox(width: 10)),
                      const Icon(Icons.keyboard_arrow_right,
                          color: Colors.black),
                    ])),
                Divider(
                    height: 0.03 * size.height,
                    color: Colors.black,
                    thickness: 0.1,
                    indent: 48,
                    endIndent: 48),
                GestureDetector(
                    onTap: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                              fullscreenDialog: true,
                              builder: (context) {
                                return const NotificationSettingsScreen();
                              }))
                          .then((_) => setState(() {}));
                    },
                    child: Row(children: [
                      const Icon(Icons.notifications, color: Colors.black),
                      const SizedBox(width: 24),
                      Text('Notifiche',
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(color: Colors.black)),
                      const Expanded(child: SizedBox(width: 10)),
                      const Icon(Icons.keyboard_arrow_right,
                          color: Colors.black),
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
                      const Icon(Icons.flag, color: Colors.black),
                      const SizedBox(width: 24),
                      Text('Pianifica obiettivi',
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(color: Colors.black)),
                      const Expanded(child: SizedBox(width: 10)),
                      const Icon(Icons.keyboard_arrow_right,
                          color: Colors.black)
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
                      const Icon(Icons.logout, color: Colors.black),
                      const SizedBox(width: 24),
                      Text('Esci',
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1
                              ?.copyWith(color: Colors.black)),
                      const Expanded(child: SizedBox(width: 10)),
                      const Icon(Icons.keyboard_arrow_right,
                          color: Colors.black)
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
      Function()? cancelPressed,
      Color? confirmColor}) {
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
                        decoration: BoxDecoration(
                          color: confirmColor ?? AppColors.primaryColor,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
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
