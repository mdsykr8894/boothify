import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/date_format_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/models/booth_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/booth_provider.dart';
import '../../../providers/booth_spot_provider.dart';
import '../../../core/utils/feedback_helper.dart';

class ExhibitionDetailsScreen extends StatefulWidget {
  final ExhibitionModel exhibition;

  const ExhibitionDetailsScreen({
    super.key,
    required this.exhibition,
  });

  @override
  State<ExhibitionDetailsScreen> createState() =>
      _ExhibitionDetailsScreenState();
}

class _ExhibitionDetailsScreenState extends State<ExhibitionDetailsScreen> {
  // Track scroll position for sticky app bar opacity.
  late final ScrollController _scrollController;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();

    // Create scroll controller for this page.
    _scrollController = ScrollController();

    // Update scroll offset when user scrolls.
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });

    // Fetch booth spots and packages after screen loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BoothSpotProvider>().fetchBoothSpots(widget.exhibition.id);
      context.read<BoothProvider>().fetchBoothPackages(widget.exhibition.id);
    });
  }

  @override
  void dispose() {
    // Dispose scroll controller to prevent memory leaks.
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildStatusBadge(String status) {
    // Build colored badge based on status value.
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (status.toLowerCase()) {
      case 'ongoing':
      case 'published':
      case 'available':
        textColor = const Color(0xFF0F9D58);
        bgColor = const Color(0xFFE6F7F5);
        borderColor = const Color(0xFFD4F2EE);
        break;
      case 'upcoming':
        textColor = const Color(0xFF1E88E5);
        bgColor = const Color(0xFFEEF6FF);
        borderColor = const Color(0xFFD2E8FF);
        break;
      case 'booking open':
        textColor = const Color(0xFF0F9D58);
        bgColor = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFFDCFCE7);
        break;
      case 'booking closed':
        textColor = AppColors.primaryAccent;
        bgColor = const Color(0xFFFFF0F2);
        borderColor = const Color(0xFFFCDDE2);
        break;
      case 'draft':
      case 'pending':
        textColor = const Color(0xFFE67E22);
        bgColor = const Color(0xFFFFF4EB);
        borderColor = const Color(0xFFFDE3CF);
        break;
      default:
        textColor = Colors.grey.shade600;
        bgColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade200;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String category) {
    // Build category badge for exhibition category.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Text(
        category.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primaryAccent,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPinkPlaceholderIcon() {
    // Show placeholder when exhibition image is missing.
    return Center(
      child: Icon(
        Icons.store_mall_directory_outlined,
        size: 68,
        color: AppColors.primaryAccent.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildQuickInfoRow(
    String label,
    String value, {
    bool isLast = false,
  }) {
    // Hide quick info row if value is empty.
    if (value.trim().isEmpty || value.toLowerCase() == 'null') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    // Build small information card for duration and location.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryAccent.withValues(alpha: 0.15),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryAccent),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value, {
    Color? highlightColor,
  }) {
    // Build one summary item for booth statistics.
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: highlightColor ?? AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    // Build divider between summary items.
    return Container(
      width: 1,
      height: 28,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildPublicPackageItem(
    BoothModel package,
    bool isLast, {
    bool isCheapest = false,
  }) {
    // Build booth package card for public view.
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCheapest
              ? AppColors.primaryAccent.withValues(alpha: 0.25)
              : AppColors.border,
          width: isCheapest ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCheapest
                ? AppColors.primaryAccent.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  package.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              if (isCheapest)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'BEST VALUE',
                    style: TextStyle(
                      color: AppColors.primaryAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'RM ${package.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14.5,
                  color: AppColors.primaryAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '  ·  ${package.size} booth space',
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Included amenities',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          if (package.amenities.isNotEmpty)
            Wrap(
              spacing: 24,
              runSpacing: 10,
              children: package.amenities.map((amenity) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check,
                      size: 14,
                      color: Color(0xFF0F9D58),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      amenity,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            )
          else
            Text(
              'No amenities listed',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current user and related providers.
    final authProvider = context.watch<AuthProvider>();
    final userProvider = context.watch<UserProvider>();
    final spotProvider = context.watch<BoothSpotProvider>();
    final boothProvider = context.watch<BoothProvider>();

    // Calculate sticky app bar opacity from scroll offset.
    final double appBarOpacity = (_scrollOffset / 150.0).clamp(0.0, 1.0);

    final user = authProvider.currentUser;

    // Check whether user already saved this exhibition.
    final bool isFavorited =
        user?.favoriteExhibitionIds.contains(widget.exhibition.id) ?? false;

    // Resolve organizer display name from user list.
    final creator =
        userProvider.users.any((u) => u.uid == widget.exhibition.organizerId)
            ? userProvider.users.firstWhere(
                (u) => u.uid == widget.exhibition.organizerId,
              )
            : null;

    String creatorDisplay = 'Organizer';

    if (creator != null) {
      if (creator.name.isNotEmpty) {
        creatorDisplay = creator.name;
      } else if (creator.email.isNotEmpty) {
        creatorDisplay = creator.email;
      } else if (creator.role == 'Admin') {
        creatorDisplay = 'Admin';
      }
    } else {
      // Fallback to current user if they created the exhibition.
      final currentUser = authProvider.currentUser;

      if (currentUser != null &&
          currentUser.uid == widget.exhibition.organizerId) {
        if (currentUser.name.isNotEmpty) {
          creatorDisplay = currentUser.name;
        } else if (currentUser.email.isNotEmpty) {
          creatorDisplay = currentUser.email;
        } else if (currentUser.role == 'Admin') {
          creatorDisplay = 'Admin';
        }
      }
    }

    // Calculate booth spot summary.
    final spots = spotProvider.boothSpots;
    final totalSpots = spots.length;
    final availableSpots = spotProvider.availableSpots.length;

    // Get booth packages for this exhibition.
    final packages = boothProvider.boothPackages;

    // Find minimum booth package price.
    double? minPrice;
    if (packages.isNotEmpty) {
      minPrice = packages.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    }

    // Find cheapest booth package.
    final cheapestPackage = packages.isNotEmpty
        ? packages.reduce((a, b) => a.price < b.price ? a : b)
        : null;

    // Show quick info only when at least one value exists.
    final hasQuickInfo = widget.exhibition.eventType.isNotEmpty ||
        widget.exhibition.category.isNotEmpty ||
        widget.exhibition.openingHours.isNotEmpty ||
        widget.exhibition.expectedVisitors.isNotEmpty ||
        widget.exhibition.contactEmail.isNotEmpty ||
        widget.exhibition.contactPhone.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Hero image or placeholder.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 380,
            child: widget.exhibition.imageUrls.isNotEmpty
                ? Image.network(
                    widget.exhibition.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFFFF0F2),
                      child: _buildPinkPlaceholderIcon(),
                    ),
                  )
                : Container(
                    color: const Color(0xFFFFF0F2),
                    child: _buildPinkPlaceholderIcon(),
                  ),
          ),

          // Scrollable details panel.
          Positioned.fill(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                overscroll: false,
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 350),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(38),
                        ),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 16,
                        bottom: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Exhibition title.
                          Center(
                            child: Text(
                              widget.exhibition.name,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.h1.copyWith(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.0,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Location and date range.
                          Center(
                            child: Text(
                              '${widget.exhibition.location}  ·  ${DateFormatHelper.formatDateRange(widget.exhibition.startDate, widget.exhibition.endDate)}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Category, event status, and booking status badges.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildCategoryBadge(widget.exhibition.category),
                              const SizedBox(width: 8),
                              _buildStatusBadge(
                                widget.exhibition.eventStatus,
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(
                                widget.exhibition.isBookingOpen
                                    ? 'Booking Open'
                                    : 'Booking Closed',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: AppSpacing.l),

                          // Booth summary row.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryItem(
                                'Total Booths',
                                totalSpots.toString(),
                              ),
                              _buildVerticalDivider(),
                              _buildSummaryItem(
                                'Available',
                                availableSpots.toString(),
                                highlightColor: AppColors.success,
                              ),
                              _buildVerticalDivider(),
                              _buildSummaryItem(
                                'Packages',
                                packages.length.toString(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 18),

                          // Organizer display row.
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 26,
                                  color: AppColors.secondaryText,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: 'Organized by ',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.secondaryText,
                                        fontWeight: FontWeight.w400,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: creatorDisplay,
                                          style: const TextStyle(
                                            color: AppColors.primaryText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: 20),

                          // Duration and location cards.
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Duration',
                                    value: DateFormatHelper.formatDateRange(
                                      widget.exhibition.startDate,
                                      widget.exhibition.endDate,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInfoCard(
                                    icon: Icons.location_on_outlined,
                                    label: 'Location',
                                    value: widget.exhibition.location,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: AppSpacing.xl),

                          // Booth package section.
                          const Text(
                            'Booth Package',
                            style: AppTextStyles.h2,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          boothProvider.isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : packages.isEmpty
                                  ? Text(
                                      'No booth packages available.',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 14,
                                      ),
                                    )
                                  : Column(
                                      children: List.generate(
                                        packages.length,
                                        (idx) {
                                          final pkg = packages[idx];
                                          final isCheapest =
                                              cheapestPackage != null &&
                                                  pkg.id == cheapestPackage.id;

                                          return _buildPublicPackageItem(
                                            pkg,
                                            idx == packages.length - 1,
                                            isCheapest: isCheapest,
                                          );
                                        },
                                      ),
                                    ),
                          const SizedBox(height: AppSpacing.xl),
                          const Divider(height: 1, color: AppColors.border),
                          const SizedBox(height: AppSpacing.xl),

                          // Exhibition description.
                          const Text(
                            'About this exhibition',
                            style: AppTextStyles.h2,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          Text(
                            widget.exhibition.description,
                            style: const TextStyle(
                              fontSize: 14.5,
                              color: AppColors.secondaryText,
                              height: 1.6,
                            ),
                          ),

                          // Quick info section.
                          if (hasQuickInfo) ...[
                            const SizedBox(height: AppSpacing.xl),
                            const Divider(
                              height: 1,
                              color: AppColors.border,
                            ),
                            const SizedBox(height: AppSpacing.l),
                            const Text(
                              'Quick Info',
                              style: AppTextStyles.h2,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            _buildQuickInfoRow(
                              'Event Type',
                              widget.exhibition.eventType,
                            ),
                            _buildQuickInfoRow(
                              'Category',
                              widget.exhibition.category,
                            ),
                            _buildQuickInfoRow(
                              'Opening Hours',
                              widget.exhibition.openingHours,
                            ),
                            _buildQuickInfoRow(
                              'Expected Visitors',
                              widget.exhibition.expectedVisitors,
                            ),
                            _buildQuickInfoRow(
                              'Contact Email',
                              widget.exhibition.contactEmail,
                            ),
                            _buildQuickInfoRow(
                              'Contact Phone',
                              widget.exhibition.contactPhone,
                              isLast: true,
                            ),
                          ],

                          // Admin-only technical context.
                          if (user?.role == 'Admin') ...[
                            _buildAdminContextSection(),
                          ],

                          const SizedBox(height: 150),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sticky top bar with navigation actions.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).padding.top + 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: appBarOpacity),
                border: Border(
                  bottom: BorderSide(
                    color:
                        Colors.grey.shade200.withValues(alpha: appBarOpacity),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: appBarOpacity * 0.03,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.s,
                  ),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Back button.
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: 0.08 * (1.0 - appBarOpacity),
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: AppColors.primaryText,
                              size: 20,
                            ),
                          ),
                        ),

                        // Share and favorite buttons.
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                FeedbackHelper.showInfo(
                                  context,
                                  'Sharing options coming soon!',
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08 * (1.0 - appBarOpacity),
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.share_outlined,
                                  color: AppColors.primaryText,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () async {
                                // Ask guest user to login before saving favorite.
                                if (user == null) {
                                  FeedbackHelper.showWarning(
                                    context,
                                    'Please log in to save favorites',
                                  );
                                  context.push(AppRoutes.login);
                                  return;
                                }

                                // Toggle favorite in Firestore through UserProvider.
                                final updatedFavorites =
                                    await userProvider.toggleFavorite(
                                  userId: user.uid,
                                  exhibitionId: widget.exhibition.id,
                                  currentFavorites:
                                      user.favoriteExhibitionIds,
                                );

                                // Update local auth user state after favorite change.
                                if (updatedFavorites != null) {
                                  authProvider.updateFavorites(
                                    updatedFavorites,
                                  );
                                }
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08 * (1.0 - appBarOpacity),
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isFavorited
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorited
                                      ? AppColors.primaryAccent
                                      : Colors.grey.shade600,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom booking bar.
      bottomSheet: Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (minPrice != null) ...[
                    Text.rich(
                      TextSpan(
                        text: 'From ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                        children: [
                          TextSpan(
                            text: 'RM ${minPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryAccent,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'per booth spot',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ] else ...[
                    Text(
                      '$availableSpots spots',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F9D58),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'available now',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            widget.exhibition.isBookingOpen
                ? AppButton(
                    text: 'View Plan',
                    color: const Color(0xFF1A1A1A),
                    width: 130,
                    borderRadius: 28,
                    onPressed: () {
                      context.push(
                        AppRoutes.boothApplicationFlow,
                        extra: widget.exhibition,
                      );
                    },
                  )
                : GestureDetector(
                    onTap: () {
                      FeedbackHelper.showWarning(
                        context,
                        'Booking is currently closed for this exhibition.',
                      );
                    },
                    child: Container(
                      width: 130,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Text(
                        'Booking Closed',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminContextSection() {
    // Build admin-only technical exhibition details.
    final String createdStr = widget.exhibition.createdAt != null
        ? DateFormatHelper.formatDateTime(widget.exhibition.createdAt!)
        : 'N/A';

    final String updatedStr = widget.exhibition.updatedAt != null
        ? DateFormatHelper.formatDateTime(widget.exhibition.updatedAt!)
        : 'N/A';

    final String publishStatus =
        widget.exhibition.isPublished ? 'Published' : 'Draft';

    final String bookingStatus =
        widget.exhibition.isBookingOpen ? 'Booking Open' : 'Booking Closed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xl),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: AppSpacing.l),

        // Admin context title.
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'ADMIN CONTEXT',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
              letterSpacing: 1.4,
            ),
          ),
        ),

        // Technical details card.
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey.shade100,
              width: 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TECHNICAL DETAILS',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAdminInfoRow(
                label: 'Exhibition ID',
                value: widget.exhibition.id,
                showDivider: true,
              ),
              _buildAdminInfoRow(
                label: 'Created By ID',
                value: widget.exhibition.organizerId,
                showDivider: true,
              ),
              _buildAdminInfoRow(
                label: 'Publish Status',
                value: publishStatus,
                showDivider: true,
              ),
              _buildAdminInfoRow(
                label: 'Booking Status',
                value: bookingStatus,
                showDivider: true,
              ),
              _buildAdminInfoRow(
                label: 'Created At',
                value: createdStr,
                showDivider: true,
              ),
              _buildAdminInfoRow(
                label: 'Updated At',
                value: updatedStr,
                showDivider: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminInfoRow({
    required String label,
    required String? value,
    bool showDivider = true,
  }) {
    // Build one admin technical information row.
    final bool hasValue = value != null && value.trim().isNotEmpty;
    final String displayValue = hasValue ? value.trim() : 'Not provided';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: hasValue
                            ? AppColors.primaryText
                            : Colors.grey.shade400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showDivider) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.shade100,
            ),
          ],
        ],
      ),
    );
  }
}