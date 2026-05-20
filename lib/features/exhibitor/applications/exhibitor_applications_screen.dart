import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_filter_chips.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/login_required_view.dart';
import '../../../providers/application_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/exhibition_provider.dart';
import '../../../providers/user_provider.dart';
import 'widgets/exhibitor_application_card.dart';

class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchApplications();
    });
  }

  void _fetchApplications() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      context.read<ApplicationProvider>().fetchUserApplications(user.uid);
      context.read<ExhibitionProvider>().fetchPublishedExhibitions();
      context.read<UserProvider>().fetchAllUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appProvider = context.watch<ApplicationProvider>();

    final user = authProvider.currentUser;
    final isLoading = appProvider.isLoading;
    final allApps = appProvider.userApplications;

    if (user == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppPageHeader(title: 'Applications'),
              LoginRequiredView(
                title: 'Login to View Applications',
                message: 'Sign in to track your booth applications and booking status.',
                onLoginPressed: () => context.go(AppRoutes.login),
              ),
            ],
          ),
        ),
      );
    }

    // Filter applications
    final applications = allApps.where((app) {
      if (_selectedFilter == 'All') return true;
      return app.status == _selectedFilter;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(title: 'Applications'),
            const SizedBox(height: AppSpacing.s),
            AppFilterChips(
              selectedValue: _selectedFilter,
              filters: const ['All', 'Pending', 'Approved'],
              moreFilters: const ['Paid', 'Rejected', 'Cancelled'],
              onChanged: (val) => setState(() => _selectedFilter = val),
            ),
            const SizedBox(height: AppSpacing.s),
            Expanded(
              child: isLoading
                  ? const AppLoading()
                  : applications.isEmpty
                      ? AppEmptyState(
                          title: _selectedFilter == 'All'
                              ? 'No Applications'
                              : 'No $_selectedFilter Applications',
                          message: 'Your booth applications will appear here after you submit a booking.',
                          icon: Icons.description_outlined,
                        )
                      : ScrollConfiguration(
                          behavior: const ScrollBehavior().copyWith(overscroll: false),
                          child: RefreshIndicator(
                            onRefresh: () async => _fetchApplications(),
                            child: ListView.builder(
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.only(
                                left: AppSpacing.screenHorizontal,
                                right: AppSpacing.screenHorizontal,
                                top: AppSpacing.m,
                                bottom: 100,
                              ),
                              itemCount: applications.length,
                              itemBuilder: (context, index) {
                                return ApplicationCard(
                                  application: applications[index],
                                );
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
