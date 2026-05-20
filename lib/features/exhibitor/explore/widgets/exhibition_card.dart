import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/date_format_helper.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/exhibition_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../../core/utils/feedback_helper.dart';

class ExhibitionCard extends StatelessWidget {
  final ExhibitionModel exhibition;
  final VoidCallback? onTap;
  final double? width;

  const ExhibitionCard({
    super.key,
    required this.exhibition,
    this.onTap,
    this.width,
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

  Widget _buildPinkPlaceholder() {
    return Container(
      color: const Color(0xFFFDF4F6),
      child: const Center(
        child: Icon(
          Icons.store_mall_directory_outlined,
          size: 48,
          color: Color(0xFFE8B2C1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userProvider = context.read<UserProvider>();
    final user = authProvider.currentUser;
    final bool isFavorited = user?.favoriteExhibitionIds.contains(exhibition.id) ?? false;
    final bool hasImage = exhibition.imageUrls.isNotEmpty;
    final double imageHeight = width != null ? 170.0 : 180.0;

    final VoidCallback navigateToDetails = onTap ?? () => context.push(AppRoutes.exhibitionDetails, extra: exhibition);

    return Container(
      width: width,
      margin: EdgeInsets.only(bottom: width != null ? 0 : 20),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: navigateToDetails,
            splashColor: Colors.black.withValues(alpha: 0.03),
            highlightColor: Colors.black.withValues(alpha: 0.01),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Image / Preview Area
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      child: SizedBox(
                        height: imageHeight,
                        width: double.infinity,
                        child: hasImage
                            ? Image.network(
                                exhibition.imageUrls.first,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => _buildPinkPlaceholder(),
                              )
                            : _buildPinkPlaceholder(),
                      ),
                    ),
                    // Floating Circular Favorite Button
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                        child: InkWell(
                          onTap: () async {
                            if (user == null) {
                              FeedbackHelper.showWarning(context, 'Please log in to save favorites');
                              context.push(AppRoutes.login);
                              return;
                            }

                            final updatedFavorites = await userProvider.toggleFavorite(
                              userId: user.uid,
                              exhibitionId: exhibition.id,
                              currentFavorites: user.favoriteExhibitionIds,
                            );

                            if (updatedFavorites != null) {
                              authProvider.updateFavorites(updatedFavorites);
                            }
                          },
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isFavorited ? Icons.favorite : Icons.favorite_border,
                              color: isFavorited ? Colors.red.shade600 : Colors.grey.shade400,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Content Below Image
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title + Category Badge Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exhibition.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.primaryText,
                                letterSpacing: -0.3,
                                height: 1.25,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildCategoryBadge(exhibition.category),
                        ],
                      ),
                      const SizedBox(height: 14),

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
                      const SizedBox(height: 8),

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

                // Footer action row: "View Details" style
                Container(
                  width: double.infinity,
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.center,
                  child: Row(
                    children: [
                      const Text(
                        'View Details',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
