import 'package:flutter/material.dart';
import 'package:keep_up/screens/goals_screen.dart';
import 'package:keep_up/screens/home_screen.dart';
import 'package:keep_up/screens/personal_growth_screen.dart';
import 'package:keep_up/screens/profile_screen.dart';
import 'package:keep_up/style.dart';

class AppNavigator extends StatefulWidget {
  static const homePage = 0;
  static const goalsPage = 1;
  static const communityPage = 2;
  static const accountPage = 3;
  static const personalGrowthPage = 4;
  final int? initialPage;
  const AppNavigator({Key? key, this.initialPage = homePage}) : super(key: key);

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  late int _selectedIndex = widget.initialPage!;
  final _pages = const [
    HomeScreen(),
    GoalsScreen(),
    Text('Community'),
    ProfileScreen(),
    PersonalGrowthScreen()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBody: true,
        backgroundColor: Colors.white,
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        //_pages[_selectedIndex],
        floatingActionButton: SizedBox(
          height: 65,
          width: 65,
          child: FittedBox(
            child: FloatingActionButton(
              backgroundColor: _selectedIndex == AppNavigator.personalGrowthPage
                  ? AppColors.primaryColor
                  : Colors.black,
              splashColor: Colors.transparent,
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              onPressed: () {
                setState(
                    () => _selectedIndex = AppNavigator.personalGrowthPage);
              },
              child: const Icon(
                Icons.bar_chart,
                color: Colors.white,
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
            elevation: 25,
            shape: const CircularNotchedRectangle(),
            notchMargin: 6,
            child: SizedBox(
              height: 75,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    iconSize: 30,
                    padding: const EdgeInsets.only(left: 28),
                    icon: Icon(Icons.home,
                        color: _selectedIndex == AppNavigator.homePage
                            ? AppColors.primaryColor
                            : Colors.black),
                    onPressed: () =>
                        setState(() => _selectedIndex = AppNavigator.homePage),
                  ),
                  IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    iconSize: 30,
                    padding: const EdgeInsets.only(right: 28),
                    icon: Icon(Icons.flag,
                        color: _selectedIndex == AppNavigator.goalsPage
                            ? AppColors.primaryColor
                            : Colors.black),
                    onPressed: () =>
                        setState(() => _selectedIndex = AppNavigator.goalsPage),
                  ),
                  IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    iconSize: 30,
                    padding: const EdgeInsets.only(left: 28),
                    icon: Icon(Icons.people,
                        color: _selectedIndex == AppNavigator.communityPage
                            ? AppColors.primaryColor
                            : Colors.black),
                    onPressed: () => setState(
                        () => _selectedIndex = AppNavigator.communityPage),
                  ),
                  IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    iconSize: 30,
                    padding: const EdgeInsets.only(right: 28),
                    icon: Icon(Icons.person,
                        color: _selectedIndex == AppNavigator.accountPage
                            ? AppColors.primaryColor
                            : Colors.black),
                    onPressed: () => setState(
                        () => _selectedIndex = AppNavigator.accountPage),
                  )
                ],
              ),
            )));
  }
}
