import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'reported_screen.dart';
import '../../../utils/app_themes.dart';

class MainScreenContainer extends StatefulWidget {
  const MainScreenContainer({super.key});

  @override
  State<MainScreenContainer> createState() => _MainScreenContainerState();
}

class _MainScreenContainerState extends State<MainScreenContainer> {
  int _pageIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const ReportedScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_pageIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _pageIndex,
        height: 60.0,
        items: const <Widget>[
          Icon(Icons.home, size: 30),
          Icon(Icons.report, size: 30),
          Icon(Icons.person, size: 30),
        ],
        color: isDarkMode ? AppThemes.darkTheme.cardColor : Colors.white,
        buttonBackgroundColor: isDarkMode ? AppThemes.darkTheme.primaryColor : AppThemes.lightTheme.primaryColor,
        backgroundColor: Colors.transparent, // Make it transparent to show scaffold bg
        animationCurve: Curves.easeInOut,
        animationDuration: const Duration(milliseconds: 400),
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
        letIndexChange: (index) => true,
      ),
    );
  }
}