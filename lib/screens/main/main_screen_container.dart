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

  final List<String> _titles = [
    'Blocked Numbers',
    'Reported Numbers',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: _screens[_pageIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: CurvedNavigationBar(
          index: _pageIndex,
          height: 65.0,
          items: [
            _buildNavItem(Icons.shield, 0),
            _buildNavItem(Icons.report, 1),
            _buildNavItem(Icons.person, 2),
          ],
          color: theme.colorScheme.surface,
          buttonBackgroundColor: theme.colorScheme.primary,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOutCubic,
          animationDuration: const Duration(milliseconds: 400),
          onTap: (index) {
            setState(() {
              _pageIndex = index;
            });
          },
          letIndexChange: (index) => true,
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final theme = Theme.of(context);
    final isSelected = _pageIndex == index;
    
    return Icon(
      icon,
      size: 28,
      color: isSelected 
          ? Colors.white 
          : theme.colorScheme.onSurface.withOpacity(0.6),
    );
  }
}