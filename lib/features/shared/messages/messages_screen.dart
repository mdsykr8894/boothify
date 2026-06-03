import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_filter_chips.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/login_required_view.dart';
import '../../../providers/auth_provider.dart';

// Display user messages.
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // Track selected message filter.
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // Require login before viewing messages.
    if (user == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppPageHeader(title: 'Messages'),
              LoginRequiredView(
                title: 'Login to View Messages',
                message:
                    'Sign in to view your conversations and updates about your applications.',
                onLoginPressed: () => context.go(AppRoutes.login),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Messages'),
            const SizedBox(height: AppSpacing.s),

            // Filter messages by status.
            AppFilterChips(
              selectedValue: _selectedFilter,
              filters: const ['All', 'Read', 'Unread'],
              onChanged: (val) => setState(() => _selectedFilter = val),
            ),
            const SizedBox(height: AppSpacing.s),

            // Show empty messages state.
            const Expanded(
              child: AppEmptyState(
                title: 'No Messages',
                message:
                    'Your conversations will appear here when messages are available.',
                icon: Icons.chat_bubble_outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}