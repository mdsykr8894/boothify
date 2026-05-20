import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_filter_chips.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../providers/application_provider.dart';
import '../../../providers/exhibition_provider.dart';
import '../../../providers/user_provider.dart';
import 'widgets/admin_application_card.dart';

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAllApplications();
    });
  }

  void _fetchAllApplications() {
    context.read<ApplicationProvider>().fetchAllApplications();
    context.read<ExhibitionProvider>().fetchAllExhibitions();
    context.read<UserProvider>().fetchAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<ApplicationProvider>();
    final isLoading = appProvider.isLoading;
    final allApps = appProvider.allApplications;

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
                          message: 'Applications will appear here when exhibitors submit bookings.',
                          icon: Icons.assignment_outlined,
                        )
                      : ScrollConfiguration(
                          behavior: const ScrollBehavior().copyWith(overscroll: false),
                          child: RefreshIndicator(
                            onRefresh: () async => _fetchAllApplications(),
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
                                return AdminApplicationCard(application: applications[index]);
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
