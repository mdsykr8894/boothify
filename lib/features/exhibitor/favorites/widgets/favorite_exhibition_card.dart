import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_format_helper.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/exhibition_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/user_provider.dart';

class FavoriteExhibitionCard extends StatelessWidget {
  final ExhibitionModel exhibition;
  final bool isEditing;

  const FavoriteExhibitionCard({
    super.key,
    required this.exhibition,
    this.isEditing = false,
  });

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primaryAccent,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final user = authProvider.currentUser;
    final hasImage = exhibition.imageUrls.isNotEmpty;

    // Try to get creator name using exact priority rules:
    // 1. User document full name / name / displayName / username
    // 2. User email
    // 3. Role label only
    // 4. 'Unknown organizer'
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
        child: InkWell(
          onTap: () => context.push(AppRoutes.exhibitionDetails, extra: exhibition),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Content Area: Clean Padding with no floating Stack, keeping normal/edit mode layouts 100% consistent with Exhibition Card
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Image/Icon Tile (104x104) with exact rounded corners and borders matching Exhibition Card
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
                        child: hasImage
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
                    // Right Content Column: Perfectly aligned with Exhibition card typography and spacings
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Title + Category Badge Row (Clean normal mode alignment matching Exhibition card)
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
                              _buildCategoryBadge(exhibition.category),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Dynamic Creator/Organizer Row with mixed emphasis
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
                              Icon(Icons.location_on_outlined,
                                  size: 15, color: Colors.grey.shade400),
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
                          
                          // Date Row
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 15, color: Colors.grey.shade400),
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

              // Standard Divider matching Exhibition Card
              Divider(height: 1, color: Colors.grey.shade100),

              // Bottom Action Row (64px View Details Footer)
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    const Text(
                      'View Details',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (isEditing)
                      // Comfortably tappable Remove text action with soft red tone
                      GestureDetector(
                        onTap: () async {
                          if (user == null) return;

                          final updatedFavorites = await userProvider.toggleFavorite(
                            userId: user.uid,
                            exhibitionId: exhibition.id,
                            currentFavorites: user.favoriteExhibitionIds,
                          );

                          if (updatedFavorites != null) {
                            authProvider.updateFavorites(updatedFavorites);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F3), // very soft light pink/red background
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
