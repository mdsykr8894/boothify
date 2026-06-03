import 'package:flutter/material.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../organizer/applications/organizer_applications_screen.dart';
import '../../organizer/dashboard/organizer_dashboard_screen.dart';
import '../../organizer/exhibitions/organizer_exhibitions_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';

class OrganizerWrapper extends StatefulWidget {
  const OrganizerWrapper({super.key});

  @override
  State<OrganizerWrapper> createState() => OrganizerWrapperState();
}

class OrganizerWrapperState extends State<OrganizerWrapper> {
  // Track selected bottom navigation tab.
  int _currentIndex = 0;

  void setIndex(int index) {
    // Allow other widgets to change selected tab.
    setState(() {
      _currentIndex = index;
    });
  }

  // Screens available for organizer role.
  final List<Widget> _screens = [
    const OrganizerDashboardScreen(),
    const OrganizerExhibitionsScreen(),
    const OrganizerApplicationsScreen(),
    const MessagesScreen(),
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
            icon: Icon(Icons.fact_check_outlined),
            label: 'Application',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Messages',
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