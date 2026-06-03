import 'package:flutter/material.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../exhibitor/applications/exhibitor_applications_screen.dart';
import '../../exhibitor/explore/explore_screen.dart';
import '../../exhibitor/favorites/favorites_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';

class ExhibitorWrapper extends StatefulWidget {
  const ExhibitorWrapper({super.key});

  @override
  State<ExhibitorWrapper> createState() => _ExhibitorWrapperState();
}

class _ExhibitorWrapperState extends State<ExhibitorWrapper> {
  // Track selected bottom navigation tab.
  int _currentIndex = 0;

  // Screens available for exhibitor role.
  final List<Widget> _screens = [
    const ExploreScreen(),
    const FavoritesScreen(),
    const MyApplicationsScreen(),
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
            icon: Icon(Icons.search),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Favorite',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Applications',
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