import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/opportunity/discover_screen.dart';
import '../features/application/my_applications_screen.dart';
import '../features/application/founder_apps_overview.dart';
import '../features/bookmark/saved_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/auth/auth_bloc.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isFounder =
            authState is AuthAuthenticated && authState.role == 'founder';

        // DYNAMIC SCREENS: Hides Saved for Founders
        final List<Widget> _screens = [
          const DiscoverScreen(),
          isFounder
              ? const FounderAppsOverview()
              : const MyApplicationsScreen(),
          if (!isFounder) const SavedScreen(), // <-- Added condition here
          const ProfileScreen(),
        ];

        // DYNAMIC NAV ITEMS: Hides Saved tab for Founders
        final List<BottomNavigationBarItem> _navItems = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(isFounder ? Icons.inbox_outlined : Icons.work_outline),
            activeIcon: Icon(isFounder ? Icons.inbox : Icons.work),
            label: isFounder ? 'Applicants' : 'My Apps',
          ),
          if (!isFounder) // <-- Added condition here
            const BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border),
              activeIcon: Icon(Icons.bookmark),
              label: 'Saved',
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: const Color(0xFF1B5E20),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: _navItems,
          ),
        );
      },
    );
  }
}
