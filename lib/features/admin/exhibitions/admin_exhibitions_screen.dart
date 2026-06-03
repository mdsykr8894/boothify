import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_format_helper.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_filter_chips.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/exhibition_provider.dart';
import '../../../providers/user_provider.dart';

class AdminExhibitionsScreen extends StatefulWidget {
  const AdminExhibitionsScreen({super.key});

  @override
  State<AdminExhibitionsScreen> createState() => _AdminExhibitionsScreenState();
}

class _AdminExhibitionsScreenState extends State<AdminExhibitionsScreen> {
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
        context.read<ExhibitionProvider>().fetchAllExhibitions();
        context.read<UserProvider>().fetchAllUsers();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exhibitionProvider = context.watch<ExhibitionProvider>();
    final allExhibitions = exhibitionProvider.allExhibitions;
    final isLoading = exhibitionProvider.isLoading;

    // Filter exhibitions based on selection
    final exhibitions = allExhibitions.where((e) {
      if (_selectedFilter == 'Published') return e.isPublished;
      if (_selectedFilter == 'Draft') return !e.isPublished;
      return true;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Exhibition',
              actions: [
                HeaderActionButton(
                  onPressed: () => context.push(AppRoutes.adminCreateExhibition),
                  icon: Icons.add,
                  iconColor: AppColors.primaryAccent,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            AppFilterChips(
              selectedValue: _selectedFilter,
              filters: const ['All', 'Published', 'Draft'],
              onChanged: (val) => setState(() => _selectedFilter = val),
            ),
            const SizedBox(height: AppSpacing.s),
            Expanded(
              child: isLoading
                  ? const AppLoading()
                  : exhibitions.isEmpty
                      ? AppEmptyState(
                          title: _selectedFilter == 'All' ? 'No Exhibitions' : 'No $_selectedFilter Exhibitions',
                          message: 'Exhibitions will appear here when organizers create them.',
                          icon: Icons.event_note,
                        )
                      : RefreshIndicator(
                          onRefresh: () async => exhibitionProvider.fetchAllExhibitions(),
                          child: ListView.builder(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.only(
                              left: AppSpacing.screenHorizontal,
                              right: AppSpacing.screenHorizontal,
                              top: AppSpacing.m,
                              bottom: AppSpacing.s,
                            ),
                            itemCount: exhibitions.length,
                            itemBuilder: (context, index) {
                              final ex = exhibitions[index];
                              return _AdminExhibitionCard(exhibition: ex);
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

class _AdminExhibitionCard extends StatelessWidget {
  final ExhibitionModel exhibition;

  const _AdminExhibitionCard({required this.exhibition});

  @override
  Widget build(BuildContext context) {

    // Try to get creator name using exact priority rules:
    // 1. User document full name / name / displayName / username
    // 2. User email
    // 3. Role label only
    // 4. 'Unknown organizer'
    final userProvider = context.watch<UserProvider>();
    final creator = userProvider.users.any((u) => u.uid == exhibition.organizerId)
        ? userProvider.users.firstWhere((u) => u.uid == exhibition.organizerId)
        : null;

    String creatorName = '';
    if (creator != null) {
      if (creator.name.isNotEmpty) {
        creatorName = creator.name;
      } else if (creator.preferredName != null && creator.preferredName!.isNotEmpty) {
        creatorName = creator.preferredName!;
      } else if (creator.email.isNotEmpty) {
        creatorName = creator.email;
      } else if (creator.role.isNotEmpty) {
        creatorName = creator.role;
      } else {
        creatorName = 'Unknown organizer';
      }
    } else {
      creatorName = 'Unknown organizer';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => context.push(AppRoutes.adminExhibitionDetails, extra: exhibition),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left thumbnail box (104x104) with rounded corners (20)
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF4F6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100, width: 0.8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: exhibition.imageUrls.isNotEmpty
                            ? Image.network(
                                exhibition.imageUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.store_mall_directory_outlined,
                                  size: 36,
                                  color: Color(0xFFE8B2C1),
                                ),
                              )
                            : const Icon(
                                Icons.store_mall_directory_outlined,
                                size: 36,
                                color: Color(0xFFE8B2C1),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right info details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title + Status Row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  exhibition.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: AppColors.primaryText,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                label: exhibition.isPublished ? 'Published' : 'Draft',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Creator Row with mixed emphasis
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 15, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(text: 'Organized by '),
                                      TextSpan(
                                        text: creatorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Location Row
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  exhibition.location,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          
                          // Calendar Row
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey.shade400),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  DateFormatHelper.formatDateRange(exhibition.startDate, exhibition.endDate),
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            
            // Left-aligned dark bottom action row with comfortable left padding matching reference "View Details" style
            InkWell(
              onTap: () => context.push(AppRoutes.adminExhibitionDetails, extra: exhibition),
              child: Container(
                width: double.infinity,
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    const Text(
                      'Manage Exhibition',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
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
