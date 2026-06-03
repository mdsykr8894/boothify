import 'package:flutter/material.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../admin/applications/admin_applications_screen.dart';
import '../../admin/dashboard/admin_dashboard_screen.dart';
import '../../admin/exhibitions/admin_exhibitions_screen.dart';
import '../../admin/users/admin_users_screen.dart';
import '../profile/profile_screen.dart';

class AdminWrapper extends StatefulWidget {
  const AdminWrapper({super.key});

  @override
  State<AdminWrapper> createState() => AdminWrapperState();
}

class AdminWrapperState extends State<AdminWrapper> {
  // Track selected bottom navigation tab.
  int _currentIndex = 0;

  void setIndex(int index) {
    // Allow other widgets to change selected tab.
    setState(() {
      _currentIndex = index;
    });
  }

  // Screens available for admin role.
  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const AdminExhibitionsScreen(),
    const AdminApplicationsScreen(),
    const AdminUsersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Keep tab screen states alive while switching tabs.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Exhibition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            label: 'Application',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'User',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}