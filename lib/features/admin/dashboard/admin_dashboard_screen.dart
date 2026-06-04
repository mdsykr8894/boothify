import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_hero_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/dashboard_summary_card.dart';
import '../../../providers/application_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/exhibition_provider.dart';
import '../../../providers/user_provider.dart';
import '../../shared/wrappers/admin_wrapper.dart';
import '../../../providers/notification_provider.dart';
import '../../shared/notifications/widgets/notification_bell_button.dart';

// Display admin dashboard overview.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Track whether dashboard data has been fetched.
  bool _hasFetched = false;
  NotificationProvider? _notificationProvider;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    _notificationProvider ??= context.read<NotificationProvider>();

    if (user != null) {
      _notificationProvider?.subscribeToNotifications(user.uid);
    } else {
      _notificationProvider?.unsubscribe();
    }

    // Reset fetch state when admin session is unavailable.
    if (!auth.isInitialized ||
        user == null ||
        user.role != 'Admin') {
      _hasFetched = false;
    } else if (!_hasFetched) {
      _hasFetched = true;

      // Fetch dashboard data after first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fetchData();
      });
    }
  }

  @override
  void dispose() {
    _notificationProvider?.unsubscribe();
    super.dispose();
  }

  void _fetchData() {
    // Load exhibitions, applications, and users.
    context.read<ExhibitionProvider>().fetchAllExhibitions();
    context.read<ApplicationProvider>().fetchAllApplications();
    context.read<UserProvider>().fetchAllUsers();
  }

  Widget _buildPendingAlert(int pendingCount) {
    if (pendingCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.l),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          // Navigate to applications tab.
          onTap: () {
            context.findAncestorStateOfType<AdminWrapperState>()?.setIndex(2);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on_rounded,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$pendingCount Pending Review${pendingCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'New applications require approval',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Review Now',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActionRow(
                icon: Icons.calendar_today_outlined,
                label: 'Manage Exhibitions',
                onTap: () {
                  // Navigate to exhibitions tab.
                  context
                      .findAncestorStateOfType<AdminWrapperState>()
                      ?.setIndex(1);
                },
                isLast: false,
              ),
              _buildActionRow(
                icon: Icons.fact_check_outlined,
                label: 'Review Applications',
                onTap: () {
                  // Navigate to applications tab.
                  context
                      .findAncestorStateOfType<AdminWrapperState>()
                      ?.setIndex(2);
                },
                isLast: false,
              ),
              _buildActionRow(
                icon: Icons.people_outline,
                label: 'Manage Users',
                onTap: () {
                  // Navigate to users tab.
                  context
                      .findAncestorStateOfType<AdminWrapperState>()
                      ?.setIndex(3);
                },
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isLast,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : null,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.primaryAccent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade100,
                indent: 58,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exhibitionProvider = context.watch<ExhibitionProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final userProvider = context.watch<UserProvider>();

    // Check dashboard loading state.
    final isLoading =
        exhibitionProvider.isLoading ||
        applicationProvider.isLoading ||
        userProvider.isLoading;

    final exhibitions = exhibitionProvider.allExhibitions;
    final applications = applicationProvider.allApplications;
    final users = userProvider.users;

    // Count published exhibitions.
    final publishedCount = exhibitions.where((e) => e.isPublished).length;

    // Count draft exhibitions.
    final draftCount = exhibitions.length - publishedCount;

    // Count inactive users.
    final inactiveUsers = users.where((u) => !u.isActive).length;

    // Count active users.
    final activeUsers = users.length - inactiveUsers;

    // Count applications waiting for review.
    final pendingReviewsCount = applications
        .where((a) => a.status == 'Pending')
        .length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(
              title: 'Dashboard',
              actions: [
                NotificationBellButton(),
              ],
            ),
            Expanded(
              child: isLoading
                  ? const AppLoading()
                  : RefreshIndicator(
                      // Refresh dashboard data.
                      onRefresh: () async => _fetchData(),
                      child: ListView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                          vertical: AppSpacing.m,
                        ),
                        children: [
                          // Show platform summary card.
                          AppHeroCard(
                            title: 'Platform',
                            icon: Icons.shield_outlined,
                            mainValue:
                                '${exhibitions.length} ${exhibitions.length == 1 ? 'Total Event' : 'Total Events'}',
                            subtitle:
                                'Monitor events, applications, and users.',
                            isDark: true,
                            stats: [
                              // Show active users stat.
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$activeUsers ${activeUsers == 1 ? 'Active User' : 'Active Users'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),

                              // Show total applications stat.
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.description_outlined,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${applications.length} ${applications.length == 1 ? 'Application' : 'Applications'}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.l),

                          // Show pending review shortcut.
                          _buildPendingAlert(pendingReviewsCount),

                          // Show dashboard overview title.
                          const Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryText,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // Show overview metric cards.
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: AppSpacing.m,
                            crossAxisSpacing: AppSpacing.m,
                            childAspectRatio: 1.25,
                            children: [
                              // Show published exhibitions count.
                              DashboardSummaryCard(
                                title: 'Published',
                                value: publishedCount.toString(),
                                icon: Icons.public,
                                subtitle: 'Live in explore',
                              ),

                              // Show draft exhibitions count.
                              DashboardSummaryCard(
                                title: 'Drafts',
                                value: draftCount.toString(),
                                icon: Icons.edit_note,
                                subtitle: 'Unpublished events',
                              ),

                              // Show pending applications count.
                              DashboardSummaryCard(
                                title: 'Pending',
                                value: pendingReviewsCount.toString(),
                                icon: Icons.pending_actions,
                                subtitle: 'Requires review',
                              ),

                              // Show active users count.
                              DashboardSummaryCard(
                                title: 'Active Users',
                                value: activeUsers.toString(),
                                icon: Icons.people,
                                subtitle: 'Registered accounts',
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.l),

                          // Show admin quick actions.
                          _buildQuickActions(context),
                          const SizedBox(height: AppSpacing.l),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
