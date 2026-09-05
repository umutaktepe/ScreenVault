import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../common/floating_frosted_nav_bar.dart';
import 'watchlist/watchlist_screen.dart';
import 'calendar/calendar_screen.dart';
import 'discover/discover_screen.dart';
import 'community/community_screen.dart';
import 'profile/profile_screen.dart';

/// Main Navigation Shell hosting the 5 tabs and the FloatingFrostedNavBar dock
class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      WatchlistScreen(onProfileTap: () => _onTabSelected(4)),
      const CalendarScreen(),
      const DiscoverScreen(),
      const CommunityScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvasBase,
      body: Stack(
        children: [
          // Screen contents
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          // 5-Tab Floating Frosted Glass Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FloatingFrostedNavBar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}
