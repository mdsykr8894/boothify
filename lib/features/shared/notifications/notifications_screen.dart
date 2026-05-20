import 'package:flutter/material.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_page_header.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Notifications',
              showBackButton: true,
            ),
            Expanded(
              child: AppEmptyState(
                title: 'No Notifications',
                message: 'Important updates will appear here.',
                icon: Icons.notifications_none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
