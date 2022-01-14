import 'package:flutter/material.dart';
import 'package:keep_up/screens/home_screen.dart';
import 'package:keep_up/screens/personal_growth_screen.dart';
import 'package:keep_up/style.dart';

class AppNavigator extends StatefulWidget {
  static const homePage = 0;
  static const personalGrowthPage = 1;
  final int? initialPage;
  const AppNavigator({Key? key, this.initialPage = homePage}) : super(key: key);

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  late int _selectedIndex = widget.initialPage!;
  final _pages = const [HomeScreen(), PersonalGrowthScreen()];

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
        bottomNavigationBar: BottomAppBar(
          elevation: 25,
          color: Colors.white,
          notchMargin: 16,
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Theme.of(context).primaryColor.withAlpha(0),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home, size: 30), label: 'Oggi'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person, size: 30), label: 'Io')
            ],
            currentIndex: _selectedIndex,
            onTap: (value) {
              setState(() => _selectedIndex = value);
            },
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Transform.scale(
            scale: 1.3,
            child: FloatingActionButton(
              backgroundColor: AppColors.primaryColor,
              child: const Icon(Icons.bar_chart, size: 35),
              onPressed: () {},
            )));
  }
}
