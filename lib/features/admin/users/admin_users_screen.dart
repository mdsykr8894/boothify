import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_filter_chips.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import 'widgets/admin_user_card.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _selectedFilter = 'All';
  bool _hasFetched = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    if (!auth.isInitialized || auth.currentUser == null || auth.currentUser?.role != 'Admin') {
      _hasFetched = false;
    } else if (!_hasFetched) {
      _hasFetched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchUsers();
      });
    }
  }

  void _fetchUsers() {
    context.read<UserProvider>().fetchAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final isLoading = userProvider.isLoading;
    final allUsers = userProvider.users;

    // Filter users
    final users = allUsers.where((user) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Active') return user.isActive;
      if (_selectedFilter == 'Inactive') return !user.isActive;
      return true;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'User'),
            const SizedBox(height: AppSpacing.s),
            AppFilterChips(
              selectedValue: _selectedFilter,
              filters: const ['All', 'Active', 'Inactive'],
              onChanged: (val) => setState(() => _selectedFilter = val),
            ),
            const SizedBox(height: AppSpacing.s),
            Expanded(
              child: isLoading
                  ? const AppLoading()
                  : users.isEmpty
                      ? AppEmptyState(
                          title: _selectedFilter == 'All' ? 'No Users' : 'No $_selectedFilter Users',
                          message: 'Registered users will appear here.',
                          icon: Icons.group_outlined,
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _fetchUsers(),
                          child: ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.only(
                              left: AppSpacing.screenHorizontal,
                              right: AppSpacing.screenHorizontal,
                              top: AppSpacing.m,
                              bottom: AppSpacing.s,
                            ),
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              return AdminUserCard(
                                user: user,
                                onTap: () => context.push(AppRoutes.adminUserDetails, extra: user),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
