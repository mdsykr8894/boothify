import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_filter_chips.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../providers/application_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/exhibition_provider.dart';
import '../../../providers/user_provider.dart';
import 'widgets/organizer_application_card.dart';

class OrganizerApplicationsScreen extends StatefulWidget {
  const OrganizerApplicationsScreen({super.key});

  @override
  State<OrganizerApplicationsScreen> createState() => _OrganizerApplicationsScreenState();
}

class _OrganizerApplicationsScreenState extends State<OrganizerApplicationsScreen> {
  String _selectedFilter = 'All';
  String? _lastFetchedUserId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) {
      _lastFetchedUserId = null;
    } else if (user.uid != _lastFetchedUserId) {
      _lastFetchedUserId = user.uid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchApplications();
      });
    }
  }

  void _fetchApplications() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      context.read<ApplicationProvider>().fetchOrganizerApplications(user.uid);
      context.read<ExhibitionProvider>().fetchAllExhibitions();
      context.read<UserProvider>().fetchAllUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appProvider = context.watch<ApplicationProvider>();
    
    final user = authProvider.currentUser;
    final isLoading = appProvider.isLoading;
    final allApps = appProvider.organizerApplications;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Login Required')));
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
                          message: 'Applications will appear here when exhibitors submit bookings.',
                          icon: Icons.assignment_outlined,
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
                                return OrganizerApplicationCard(
                                  application: applications[index],
                                  organizerId: user.uid,
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
