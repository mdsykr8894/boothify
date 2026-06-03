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

  String _getOrganizerName(String organizerId, List<UserModel> users) {
    final user = users.firstWhere(
      (u) => u.uid == organizerId,
      orElse: () => UserModel(uid: '', name: '', email: '', role: 'Organizer'),
    );
    return user.organizationName?.isNotEmpty == true
        ? user.organizationName!
        : user.name;
  }

  bool _hasFetchedUsers = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExhibitionProvider>().fetchPublishedExhibitions();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    if (!auth.isInitialized) {
      _hasFetchedUsers = false;
    } else if (!_hasFetchedUsers) {
      _hasFetchedUsers = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<UserProvider>().fetchAllUsers();
      });
    }
  }

  void _fetchExhibitions() {
    context.read<ExhibitionProvider>().fetchPublishedExhibitions();
    context.read<UserProvider>().fetchAllUsers();
  }

  Widget _buildSearchHeader() {
    final bool hasQuery = _searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Container(
        height: 56, // Premium 56px height
        decoration: BoxDecoration(
          color: Colors.white, // Pure white background
          borderRadius: BorderRadius.circular(100), // Rounded pill shape
          border: Border.all(color: Colors.grey.shade100, width: 1.5), // Subtle border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), // Soft shadow
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push<Map<String, String>>(
              context,
              PageRouteBuilder(
                opaque: true,
                barrierColor: Colors.white,
                transitionDuration: const Duration(milliseconds: 200),
                pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                      CurvedAnimation(parent: animation, curve: Curves.easeOut),
                    ),
                    child: ExploreSearchPage(
                      initialQuery: _searchQuery,
                      initialFilter: _selectedFilter,
                    ),
                  ),
                ),
              ),
            );

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
                // Left Search Icon
                Icon(
                  Icons.search,
                  color: hasQuery ? AppColors.primaryAccent : Colors.grey.shade400,
                  size: 22,
                ),
                const SizedBox(width: 12),
                
                // Middle Placeholder or Query text
                Expanded(
                  child: Text(
                    hasQuery ? _searchQuery : 'Search exhibitions...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasQuery ? AppColors.primaryText : Colors.grey.shade400,
                      fontSize: 14,
                      fontWeight: hasQuery ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                
                // Quick clear action icon inside the search bar header if not empty
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

                // Vertical Divider near the right
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(width: 14),
                
                // Far Right Filter Icon (Boothify pink accent)
                Icon(
                  Icons.tune_outlined,
                  color: hasQuery ? AppColors.primaryAccent : Colors.grey.shade500,
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
    final exhibitionProvider = context.watch<ExhibitionProvider>();
    final allPublished = exhibitionProvider.publishedExhibitions;
    final isLoading = exhibitionProvider.isLoading;
    final List<UserModel> users = context.watch<UserProvider>().users;

    final String query = _searchQuery.trim().toLowerCase();

    // 1. Filter all published exhibitions by search keyword
    final List<ExhibitionModel> searchFiltered = allPublished.where((e) {
      if (query.isEmpty) return true;
      
      final String orgName = _getOrganizerName(e.organizerId, users).toLowerCase();
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

    // 2. Partition into status-specific sublists for content rendering
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
                  physics: const ClampingScrollPhysics(), // Consistent scroll behaviors
                  children: [
                    // Top safe area spacing below status bar
                    const SizedBox(height: 16),
                    
                    // 1. Redesigned Search Bar Header
                    _buildSearchHeader(),
                    const SizedBox(height: 22), // Search bar to hero card gap

                    // 2. Hero Card (Visually persistent across ALL filters, premium dark promotional style)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
                      child: AppHeroCard(
                        title: 'Live Now',
                        icon: Icons.auto_awesome, // Sparkle icon
                        mainValue: 'Discover Modern\nExhibitions',
                        subtitle: '${ongoingEvents.length} ongoing • ${upcomingEvents.length} upcoming',
                        ctaText: 'Explore Now',
                        isPromotional: true,
                        isDark: true, // Force premium dark layout
                      ),
                    ),
                    const SizedBox(height: 24), // Hero to filters gap

                    // 3. Filter Chips
                    AppFilterChips(
                      selectedValue: _selectedFilter,
                      filters: const ['All', 'Upcoming', 'Ongoing'],
                      moreFilters: const ['Nearby', 'Completed'],
                      onChanged: (val) => setState(() => _selectedFilter = val),
                    ),
                    const SizedBox(height: AppSpacing.s),

                    // 4. Event Content/Cards dynamically bound by filter selection
                    _buildContent(upcomingEvents, ongoingEvents, completedEvents),
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

    final bool hasSearchQuery = _searchQuery.trim().isNotEmpty;

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

    if (_selectedFilter == 'Upcoming') {
      return _buildVerticalList(upcoming, 'No Upcoming Exhibitions');
    }
    if (_selectedFilter == 'Ongoing') {
      return _buildVerticalList(ongoing, 'No Ongoing Exhibitions');
    }
    if (_selectedFilter == 'Completed') {
      return _buildVerticalList(completed, 'No Completed Exhibitions');
    }

    // "All" view with grouped horizontal sections of large discovery cards
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
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
    return SizedBox(
      height: 355,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
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

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.m,
        bottom: AppSpacing.s,
      ),
      child: Column(
        children: events.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ExhibitionCard(exhibition: e),
        )).toList(),
      ),
    );
  }
}
