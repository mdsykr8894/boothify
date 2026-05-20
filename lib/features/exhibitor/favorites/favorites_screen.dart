import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_filter_chips.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/login_required_view.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/exhibition_provider.dart';
import '../../../providers/user_provider.dart';
import 'widgets/favorite_exhibition_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  String _selectedFilter = 'All';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExhibitionProvider>().fetchPublishedExhibitions();
      context.read<UserProvider>().fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final exhibitionProvider = context.watch<ExhibitionProvider>();

    final user = authProvider.currentUser;
    final isLoading = exhibitionProvider.isLoading;

    if (user == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppPageHeader(title: 'Favorite'),
              LoginRequiredView(
                title: 'Login to Save Events',
                message: 'Join Boothify to save and manage your favorite exhibitions.',
                onLoginPressed: () => context.go(AppRoutes.login),
              ),
            ],
          ),
        ),
      );
    }

    final favoriteIds = user.favoriteExhibitionIds;
    final favoriteExhibitions = exhibitionProvider.publishedExhibitions
        .where((ex) => favoriteIds.contains(ex.id))
        .toList();

    // Filter favorites
    final filteredExhibitions = favoriteExhibitions.where((ex) {
      if (_selectedFilter == 'All') return true;
      if (_selectedFilter == 'Upcoming') return ex.isUpcoming;
      if (_selectedFilter == 'Ongoing') return ex.isOngoing;
      return true;
    }).toList();

    // Auto-reset edit mode if all favorites are gone
    if (filteredExhibitions.isEmpty && _isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isEditing = false);
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Favorite',
              actions: [
                if (filteredExhibitions.isNotEmpty || _isEditing)
                  HeaderActionButton(
                    onPressed: () => setState(() => _isEditing = !_isEditing),
                    icon: _isEditing ? Icons.done : Icons.edit,
                    iconColor: _isEditing ? Colors.green.shade600 : AppColors.primaryAccent,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            AppFilterChips(
              selectedValue: _selectedFilter,
              filters: const ['All', 'Upcoming', 'Ongoing'],
              moreFilters: const ['Nearby'],
              onChanged: (val) => setState(() => _selectedFilter = val),
            ),
            const SizedBox(height: AppSpacing.s),
            Expanded(
              child: isLoading
                  ? const AppLoading()
                  : filteredExhibitions.isEmpty
                  ? const AppEmptyState(
                      title: 'No Favorites',
                      message: 'Saved exhibitions will appear here when you add favorites.',
                      icon: Icons.favorite_border,
                    )
                  : RefreshIndicator(
                      onRefresh: () async => context
                          .read<ExhibitionProvider>()
                          .fetchPublishedExhibitions(),
                      child: ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: AppSpacing.screenHorizontal,
                          right: AppSpacing.screenHorizontal,
                          top: AppSpacing.m,
                          bottom: AppSpacing.s,
                        ),
                        itemCount: filteredExhibitions.length,
                        itemBuilder: (context, index) {
                          return FavoriteExhibitionCard(
                            exhibition: filteredExhibitions[index],
                            isEditing: _isEditing,
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
