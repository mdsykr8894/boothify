import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_filter_chips.dart';
import '../../../core/widgets/app_hero_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/exhibition_provider.dart';
import '../../../providers/user_provider.dart';
import 'widgets/exhibition_card.dart';
import 'widgets/explore_search_page.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _hasFetchedUsers = false;

  String _getOrganizerName(String organizerId, List<UserModel> users) {
    // Find organizer display name from user list.
    final user = users.firstWhere(
      (u) => u.uid == organizerId,
      orElse: () => UserModel(uid: '', name: '', email: '', role: 'Organizer'),
    );

    // Prefer organization name if available.
    return user.organizationName?.isNotEmpty == true
        ? user.organizationName!
        : user.name;
  }

  @override
  void initState() {
    super.initState();

    // Fetch published exhibitions after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExhibitionProvider>().fetchPublishedExhibitions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Watch auth state before fetching user data.
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      // Reset user fetch flag while auth is still loading.
      _hasFetchedUsers = false;
    } else if (!_hasFetchedUsers) {
      // Fetch users only once after auth is ready.
      _hasFetchedUsers = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<UserProvider>().fetchAllUsers();
      });
    }
  }

  void _fetchExhibitions() {
    // Refresh exhibitions and organizer data.
    context.read<ExhibitionProvider>().fetchPublishedExhibitions();
    context.read<UserProvider>().fetchAllUsers();
  }

  Widget _buildSearchHeader() {
    // Check whether search query exists.
    final bool hasQuery = _searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () async {
            // Open full search page and wait for result.
            final result = await Navigator.push<Map<String, String>>(
              context,
              PageRouteBuilder(
                opaque: true,
                barrierColor: Colors.white,
                transitionDuration: const Duration(milliseconds: 200),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: ExploreSearchPage(
                        initialQuery: _searchQuery,
                        initialFilter: _selectedFilter,
                      ),
                    ),
                  );
                },
              ),
            );

            // Update search query and filter from search page result.
            if (result != null) {
              setState(() {
                _searchQuery = result['query'] ?? '';
                _selectedFilter = result['filter'] ?? 'All';
              });
            }
          },
          borderRadius: BorderRadius.circular(100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                // Search icon.
                Icon(
                  Icons.search,
                  color: hasQuery
                      ? AppColors.primaryAccent
                      : Colors.grey.shade400,
                  size: 22,
                ),
                const SizedBox(width: 12),

                // Search text or placeholder.
                Expanded(
                  child: Text(
                    hasQuery ? _searchQuery : 'Search exhibitions...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasQuery
                          ? AppColors.primaryText
                          : Colors.grey.shade400,
                      fontSize: 14,
                      fontWeight:
                          hasQuery ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),

                // Clear search query button.
                if (hasQuery) ...[
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                    icon: const Icon(Icons.clear_rounded),
                    color: Colors.grey.shade400,
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 10),
                ],

                // Divider before filter icon.
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(width: 14),

                // Filter icon.
                Icon(
                  Icons.tune_outlined,
                  color: hasQuery
                      ? AppColors.primaryAccent
                      : Colors.grey.shade500,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get published exhibitions and loading state.
    final exhibitionProvider = context.watch<ExhibitionProvider>();
    final allPublished = exhibitionProvider.publishedExhibitions;
    final isLoading = exhibitionProvider.isLoading;

    // Get user list for organizer name lookup.
    final List<UserModel> users = context.watch<UserProvider>().users;

    // Prepare lowercase search query.
    final String query = _searchQuery.trim().toLowerCase();

    // Filter exhibitions by search keyword.
    final List<ExhibitionModel> searchFiltered = allPublished.where((e) {
      if (query.isEmpty) return true;

      final String orgName =
          _getOrganizerName(e.organizerId, users).toLowerCase();
      final String name = e.name.toLowerCase();
      final String cat = e.category.toLowerCase();
      final String loc = e.location.toLowerCase();
      final String type = e.eventType.toLowerCase();

      return name.contains(query) ||
          cat.contains(query) ||
          loc.contains(query) ||
          type.contains(query) ||
          orgName.contains(query);
    }).toList();

    // Split exhibitions by event status.
    final upcomingEvents = searchFiltered.where((e) => e.isUpcoming).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final ongoingEvents = searchFiltered.where((e) => e.isOngoing).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final completedEvents = searchFiltered.where((e) => e.isCompleted).toList()
      ..sort((a, b) => b.endDate.compareTo(a.endDate));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _fetchExhibitions(),
          child: isLoading
              ? const AppLoading()
              : ListView(
                  physics: const ClampingScrollPhysics(),
                  children: [
                    const SizedBox(height: 16),

                    // Search and filter header.
                    _buildSearchHeader(),
                    const SizedBox(height: 22),

                    // Summary hero card.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.screenHorizontal,
                      ),
                      child: AppHeroCard(
                        title: 'Live Now',
                        icon: Icons.auto_awesome,
                        mainValue: 'Discover Modern\nExhibitions',
                        subtitle:
                            '${ongoingEvents.length} ongoing • ${upcomingEvents.length} upcoming',
                        ctaText: 'Explore Now',
                        isPromotional: true,
                        isDark: true,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Event filter chips.
                    AppFilterChips(
                      selectedValue: _selectedFilter,
                      filters: const ['All', 'Upcoming', 'Ongoing'],
                      moreFilters: const ['Nearby', 'Completed'],
                      onChanged: (val) {
                        setState(() => _selectedFilter = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.s),

                    // Render event list based on selected filter.
                    _buildContent(
                      upcomingEvents,
                      ongoingEvents,
                      completedEvents,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildContent(
    List<ExhibitionModel> upcoming,
    List<ExhibitionModel> ongoing,
    List<ExhibitionModel> completed,
  ) {
    // Nearby feature placeholder.
    if (_selectedFilter == 'Nearby') {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: AppEmptyState(
          title: 'No Nearby Events',
          message: 'Nearby event discovery is not available yet.',
          icon: Icons.near_me_outlined,
        ),
      );
    }

    // Check if empty state is caused by search.
    final bool hasSearchQuery = _searchQuery.trim().isNotEmpty;

    // Show empty state when no exhibitions match.
    if (upcoming.isEmpty && ongoing.isEmpty && completed.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: AppEmptyState(
          title: hasSearchQuery ? 'No Results Found' : 'No Exhibitions Found',
          message: hasSearchQuery
              ? 'Try a different keyword or clear your search.'
              : 'Check back later for exhibitions.',
          icon: Icons.search,
        ),
      );
    }

    // Show only upcoming events.
    if (_selectedFilter == 'Upcoming') {
      return _buildVerticalList(upcoming, 'No Upcoming Exhibitions');
    }

    // Show only ongoing events.
    if (_selectedFilter == 'Ongoing') {
      return _buildVerticalList(ongoing, 'No Ongoing Exhibitions');
    }

    // Show only completed events.
    if (_selectedFilter == 'Completed') {
      return _buildVerticalList(completed, 'No Completed Exhibitions');
    }

    // Show all events grouped by status.
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.m,
        bottom: AppSpacing.s,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ongoing.isNotEmpty) ...[
            _buildSectionHeader('Ongoing Events'),
            const SizedBox(height: 12),
            _buildHorizontalScroll(ongoing),
            const SizedBox(height: 24),
          ],
          if (upcoming.isNotEmpty) ...[
            _buildSectionHeader('Upcoming Events'),
            const SizedBox(height: 12),
            _buildHorizontalScroll(upcoming),
            const SizedBox(height: 24),
          ],
          if (completed.isNotEmpty) ...[
            _buildSectionHeader('Completed Events'),
            const SizedBox(height: 12),
            _buildHorizontalScroll(completed),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    // Build section title for grouped event lists.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
          letterSpacing: -0.4,
        ),
      ),
    );
  }

  Widget _buildHorizontalScroll(List<ExhibitionModel> events) {
    // Build horizontal event card list.
    return SizedBox(
      height: 355,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ExhibitionCard(
              exhibition: events[index],
              width: 310,
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerticalList(List<ExhibitionModel> events, String emptyMsg) {
    // Show empty message if selected filter has no events.
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: AppEmptyState(
          title: 'Empty List',
          message: emptyMsg,
          icon: Icons.calendar_today_outlined,
        ),
      );
    }

    // Build vertical event card list.
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.m,
        bottom: AppSpacing.s,
      ),
      child: Column(
        children: events.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ExhibitionCard(exhibition: e),
          );
        }).toList(),
      ),
    );
  }
}