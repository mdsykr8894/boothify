import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/base_dialog.dart';
import '../../../core/utils/feedback_helper.dart';
import '../../../core/utils/date_format_helper.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../data/models/application_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/exhibition_provider.dart';
import '../../../providers/booth_spot_provider.dart';
import '../../../providers/application_provider.dart';

import 'widgets/edit_exhibition_bottom_sheet.dart';
import 'widgets/edit_event_information_bottom_sheet.dart';
import 'widgets/manage_exhibition_images_bottom_sheet.dart';

class OrganizerExhibitionDetailsScreen extends StatefulWidget {
  final ExhibitionModel exhibition;

  const OrganizerExhibitionDetailsScreen({super.key, required this.exhibition});

  @override
  State<OrganizerExhibitionDetailsScreen> createState() => _OrganizerExhibitionDetailsScreenState();
}

class _OrganizerExhibitionDetailsScreenState extends State<OrganizerExhibitionDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BoothSpotProvider>().fetchBoothSpots(widget.exhibition.id);
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        if (auth.currentUser!.role == 'Admin') {
          context.read<ApplicationProvider>().fetchAllApplications();
        } else {
          context.read<ApplicationProvider>().fetchOrganizerApplications(auth.currentUser!.uid);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final exhibitionProvider = context.watch<ExhibitionProvider>();
    final user = authProvider.currentUser;

    // Watch provider to get latest data
    final latestExhibition = exhibitionProvider.allExhibitions.firstWhere(
      (e) => e.id == widget.exhibition.id,
      orElse: () => exhibitionProvider.organizerExhibitions.firstWhere(
        (e) => e.id == widget.exhibition.id,
        orElse: () => widget.exhibition,
      ),
    );
    
    final bool canEdit = user != null && (
      user.role == 'Admin' || 
      (user.role == 'Organizer' && user.uid == latestExhibition.organizerId)
    );

    final bool showEditButtons = canEdit && !latestExhibition.isPublished;

    final bool isAdmin = user != null && user.role == 'Admin';
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Exhibition Details',
              showBackButton: true,
              actions: [
                if (showEditButtons)
                  IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => EditExhibitionBottomSheet(
                          exhibition: latestExhibition,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(overscroll: false), // Disable overscroll stretch/bounce behavior
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    30, // After header before EVENT INFO: 30
                    24,
                    isAdmin ? 96.0 : 32.0, // Optimized bottom padding
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. EVENT INFO
                      _buildSectionHeader('EVENT INFO'),
                      const SizedBox(height: 12), // Section label to card: 12
                      _buildEventInfoCard(context, latestExhibition),
                      const SizedBox(height: 34), // After each card before next section label: 34

                      // 2. SUMMARY
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionHeader('SUMMARY'),
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: _buildMiniBookingStatusBadge(latestExhibition.isBookingOpen),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryCard(context, latestExhibition),
                      const SizedBox(height: 34),

                      // 3. BOOKING AVAILABILITY
                      _buildSectionHeader('BOOKING AVAILABILITY'),
                      const SizedBox(height: 12),
                      _buildBookingAvailabilitySection(context, latestExhibition),
                      const SizedBox(height: 34),

                      // 4. MANAGEMENT ACTIONS
                      _buildSectionHeader('MANAGEMENT ACTIONS'),
                      const SizedBox(height: 12),
                      _buildManagementActionsCard(context, latestExhibition, isAdmin),
                      const SizedBox(height: 34),

                      // 5. EXHIBITION DETAILS
                      _buildExhibitionDetailsSection(context, latestExhibition),
                      const SizedBox(height: 34),

                      // 6. ADDITIONAL DETAILS
                      _buildAdditionalDetailsSection(context, showEditButtons, latestExhibition),

                      // 6. ADMIN CONTEXT (Admin Only)
                      if (isAdmin) ...[
                        _buildAdminContextSection(latestExhibition),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: canEdit ? _buildBottomActionBar(context, latestExhibition, isAdmin) : null,
    );
  }

  Widget _buildMiniBookingStatusBadge(bool isOpen) {
    final Color bgColor = isOpen 
        ? const Color(0xFFF0FDF4) 
        : const Color(0xFFFFF0F2);
    final Color borderColor = isOpen 
        ? const Color(0xFFDCFCE7) 
        : const Color(0xFFFCDDE2);
    final Color textColor = isOpen 
        ? const Color(0xFF0F9D58) 
        : AppColors.primaryAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        isOpen ? 'BOOKING OPEN' : 'BOOKING CLOSED',
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildStandardBadge({
    required String label,
    required Color color,
    bool hasBackground = true,
  }) {
    return Container(
      height: 26, // Fixed layout value: height around 26
      padding: const EdgeInsets.symmetric(horizontal: 11), // Fixed layout value: horizontal padding 11
      decoration: BoxDecoration(
        color: hasBackground ? color.withValues(alpha: 0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10), // Fixed layout value: radius 10
        border: Border.all(
          color: hasBackground ? color.withValues(alpha: 0.4) : Colors.grey.shade200,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: hasBackground ? color : Colors.grey.shade600,
              fontSize: 11, // Fixed layout value: fontSize 11
              fontWeight: FontWeight.w700, // Fixed layout value: fontWeight w700
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfoCard(BuildContext context, ExhibitionModel ex) {
    final hasImage = ex.imageUrls.isNotEmpty && ex.imageUrls.first.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18.0), // Fixed layout value: padding EdgeInsets.all(18)
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Fixed layout value: borderRadius 24
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left thumbnail (92x92) - Visibly larger thumbnail container
          Container(
            width: 92, // Increased from 84 to exactly 92
            height: 92,
            decoration: BoxDecoration(
              color: const Color(0xFFFDF4F6), // soft pink tint background
              borderRadius: BorderRadius.circular(20), // Standardized 20px radius
              border: Border.all(color: Colors.grey.shade100, width: 0.8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: hasImage
                  ? Image.network(
                      ex.imageUrls.first,
                      width: 92, // Explicitly specify width and height on the Image.network
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.store_mall_directory_outlined,
                        size: 34, // Increased size to 34
                        color: Color(0xFFE8B2C1),
                      ),
                    )
                  : const Icon(
                      Icons.store_mall_directory_outlined,
                      size: 34, // Increased size to 34
                      color: Color(0xFFE8B2C1),
                    ),
            ),
          ),
          const SizedBox(width: 18), // Fixed layout value: gap between thumbnail and text 18
          // Right content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.name,
                  style: const TextStyle(
                    fontSize: 18, // Fixed layout value: event title size 18
                    fontWeight: FontWeight.w700, // Fixed layout value: event title weight w700
                    color: AppColors.primaryText,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6), // title to location gap 6
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade400), // metadata icon size 16
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ex.location,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14, // Fixed layout value: metadata fontSize 14
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6), // location/date row gap 6
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 15, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormatHelper.formatDateRange(ex.startDate, ex.endDate),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14, // Fixed layout value: metadata fontSize 14
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10), // Fixed layout value: date to badge row gap 10
                Wrap(
                  spacing: 8, // Fixed layout value: gap between badges 8
                  runSpacing: 8,
                  children: [
                    // Removed category badge from Event Info card
                    _buildStandardBadge(
                      label: ex.eventStatus,
                      color: StatusBadge.getStatusColor(ex.eventStatus),
                    ),
                    _buildStandardBadge(
                      label: ex.isPublished ? 'Published' : 'Draft',
                      color: StatusBadge.getStatusColor(ex.isPublished ? 'published' : 'draft'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ExhibitionModel ex) {
    final boothSpotProvider = context.watch<BoothSpotProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // Filter spots
    final spots = boothSpotProvider.boothSpots.where((s) => s.exhibitionId == ex.id).toList();
    final totalBoothsCount = spots.length;

    // Filter applications based on role
    final List<ApplicationModel> apps;
    if (user != null && user.role == 'Admin') {
      apps = applicationProvider.allApplications.where((a) => a.exhibitionId == ex.id).toList();
    } else {
      apps = applicationProvider.organizerApplications.where((a) => a.exhibitionId == ex.id).toList();
    }

    final totalAppsCount = apps.length;
    final pendingAppsCount = apps.where((a) => a.status == 'Pending').toList().length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Fixed layout value: borderRadius 24
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            icon: Icons.grid_view_outlined,
            iconColor: Colors.grey.shade600,
            label: 'Total Booths',
            value: '$totalBoothsCount',
          ),
          Divider(height: 1, color: Colors.grey.shade100, indent: 82), // Fixed layout value: divider starts after icon area (24 + 40 + 18 = 82)
          _buildSummaryRow(
            icon: Icons.assignment_outlined,
            iconColor: Colors.grey.shade600,
            label: 'Total Applications',
            value: '$totalAppsCount',
          ),
          Divider(height: 1, color: Colors.grey.shade100, indent: 82),
          _buildSummaryRow(
            icon: Icons.pending_actions_outlined,
            iconColor: const Color(0xFFE8B2C1), // Pink important accent icon
            label: 'Pending Applications',
            value: '$pendingAppsCount',
            isHighlight: pendingAppsCount > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      height: 70, // Fixed layout value: row height 70
      padding: const EdgeInsets.symmetric(horizontal: 24), // Fixed layout value: padding Edgeinsets.horizontal(24)
      alignment: Alignment.center,
      child: Row(
        children: [
          SizedBox(
            width: 40, // Fixed layout value: icon column width 40
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                icon,
                color: iconColor,
                size: 22, // Fixed layout value: icon size 22
              ),
            ),
          ),
          const SizedBox(width: 18), // Fixed layout value: gap icon to text 18
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w400, // Reduced from w500 to w400 for sleek elegance
                fontSize: 16, // Fixed layout value: fontSize 16 strictly
                color: AppColors.primaryText,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500, // Reduced from w600 to w500 for crisp elegance
              fontSize: 16,
              color: isHighlight ? const Color(0xFFE8B2C1) : AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementActionsCard(BuildContext context, ExhibitionModel ex, bool isAdmin) {
    final isFromAdmin = GoRouterState.of(context).matchedLocation.startsWith('/admin');
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Fixed layout value: borderRadius 24
        border: Border.all(color: Colors.grey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isAdmin) ...[
            _buildManagementRowItem(
              context,
              icon: Icons.map_outlined,
              title: 'Manage Floor Plan',
              onTap: () {
                context.push(
                  isFromAdmin ? AppRoutes.adminBoothSpots : AppRoutes.organizerBoothSpots,
                  extra: ex,
                );
              },
            ),
            Divider(height: 1, color: Colors.grey.shade100, indent: 82), // Fixed layout value: divider indent 82
          ],
          _buildManagementRowItem(
            context,
            icon: Icons.inventory_2_outlined,
            title: 'Booth Packages',
            onTap: () {
              context.push(
                isFromAdmin ? AppRoutes.adminBoothPackages : AppRoutes.organizerBoothPackages,
                extra: ex,
              );
            },
          ),
          Divider(height: 1, color: Colors.grey.shade100, indent: 82),
          _buildManagementRowItem(
            context,
            icon: Icons.photo_library_outlined, // Image gallery icon
            title: 'Event Images', // Restored Event Images Row - last item now
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => ManageExhibitionImagesBottomSheet(
                  exhibition: ex,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildManagementRowItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 70, // Fixed layout value: row height 70
        padding: const EdgeInsets.symmetric(horizontal: 24), // Fixed layout value: padding EdgeInsets.horizontal(24)
        alignment: Alignment.center,
        child: Row(
          children: [
            SizedBox(
              width: 40, // Fixed layout value: icon column width 40
              child: Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  icon,
                  color: Colors.grey.shade600,
                  size: 22, // Fixed layout value: icon size 22
                ),
              ),
            ),
            const SizedBox(width: 18), // Fixed layout value: gap icon to text 18
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w400, // Reduced from w500 to w400 for sleek elegance
                  fontSize: 16, // Fixed layout value: fontSize 16 strictly
                  color: AppColors.primaryText,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 22, // Fixed layout value: chevron size 22
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExhibitionDetailsSection(BuildContext context, ExhibitionModel ex) {
    final List<Widget> items = [];

    // 1. Category (always show, fallback to General)
    items.add(_buildInfoRowItem(
      Icons.category_outlined, 
      'Category', 
      ex.category.isNotEmpty ? ex.category : 'General',
    ));

    // 2. Event Type (always show, fallback to Not specified)
    items.add(const SizedBox(height: 20)); // Spacing between rows: 20
    items.add(_buildInfoRowItem(
      Icons.layers_outlined, 
      'Event Type', 
      ex.eventType.isNotEmpty ? ex.eventType : 'Not specified',
    ));

    // 3. Location (always show)
    items.add(const SizedBox(height: 20));
    items.add(_buildInfoRowItem(
      Icons.location_on_outlined, 
      'Location', 
      ex.location,
    ));

    // 4. Start Date (always show)
    items.add(const SizedBox(height: 20));
    items.add(_buildInfoRowItem(
      Icons.calendar_today_outlined, 
      'Start Date', 
      DateFormatHelper.formatDate(ex.startDate),
    ));

    // 5. End Date (always show)
    items.add(const SizedBox(height: 20));
    items.add(_buildInfoRowItem(
      Icons.calendar_month_outlined, 
      'End Date', 
      DateFormatHelper.formatDate(ex.endDate),
    ));

    // 6. Description (always show, fallback to No description)
    items.add(const SizedBox(height: 20));
    items.add(_buildInfoRowItem(
      Icons.description_outlined, 
      'Description', 
      ex.description.isNotEmpty ? ex.description : 'No description provided.',
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('EXHIBITION DETAILS'),
        const SizedBox(height: 12), // Section header to card gap 12
        Container(
          padding: const EdgeInsets.all(22.0), // Card padding: 22
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // borderRadius 24
            border: Border.all(color: Colors.grey.shade100, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalDetailsSection(BuildContext context, bool canEdit, ExhibitionModel ex) {
    final List<Widget> items = [];

    // 1. Contact Email
    items.add(_buildInfoRowItem(
      Icons.mail_outline, 
      'Contact Email', 
      ex.contactEmail.isNotEmpty ? ex.contactEmail : 'Not provided',
    ));

    // 2. Contact Phone
    items.add(const SizedBox(height: 20));
    items.add(_buildInfoRowItem(
      Icons.phone_outlined, 
      'Contact Phone', 
      ex.contactPhone.isNotEmpty ? ex.contactPhone : 'Not provided',
    ));

    // 3. Opening Hours
    items.add(const SizedBox(height: 20));
    items.add(_buildInfoRowItem(
      Icons.access_time, 
      'Opening Hours', 
      ex.openingHours.isNotEmpty ? ex.openingHours : 'Not provided',
    ));

    // 4. Expected Visitors
    items.add(const SizedBox(height: 20));
    items.add(_buildInfoRowItem(
      Icons.people_outline, 
      'Expected Visitors', 
      ex.expectedVisitors.isNotEmpty ? ex.expectedVisitors : 'Not provided',
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSectionHeader('ADDITIONAL DETAILS'),
            if (canEdit)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => EditEventInformationBottomSheet(
                        exhibition: ex,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_outlined, size: 16, color: AppColors.primaryAccent), // Plus icon: 16
                  label: const Row(
                    children: [
                      SizedBox(width: 6), // Gap: 6
                      Text(
                        'Add Info',
                        style: TextStyle(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12), // Section header to card gap 12
        Container(
          padding: const EdgeInsets.all(22.0), // Card padding: 22
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // borderRadius 24
            border: Border.all(color: Colors.grey.shade100, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRowItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36, // Icon column width: 36
          child: Align(
            alignment: Alignment.centerLeft,
            child: Icon(
              icon,
              size: 22, // Icon size: 22, plain grey
              color: Colors.grey.shade400,
            ),
          ),
        ),
        const SizedBox(width: 18), // Gap icon to text: 18
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13, // Label size: 13
                  fontWeight: FontWeight.w400, // Lighter label: w400
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500, // Softer value: w500
                  fontSize: 15.5, // Value size: 15.5
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingAvailabilitySection(BuildContext context, ExhibitionModel ex) {
    final bool isOpen = ex.isBookingOpen;

    final Color bgColor = isOpen 
        ? const Color(0xFFF0FDF4) // Soft active green background
        : const Color(0xFFFFF0F2); // Soft warning red/pink background

    final Color borderColor = isOpen 
        ? const Color(0xFFDCFCE7) // Soft active green border
        : const Color(0xFFFCDDE2); // Soft warning red/pink border

    final Color iconTextColor = isOpen 
        ? const Color(0xFF0F9D58) // Active green
        : AppColors.primaryAccent; // Warning red/pink

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconTextColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOpen ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
              color: iconTextColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOpen ? 'Booking is OPEN' : 'Booking is CLOSED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                    color: iconTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  isOpen 
                      ? 'Exhibitors can view and apply.' 
                      : 'Exhibitors cannot apply right now.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          isOpen
              ? OutlinedButton(
                  onPressed: () => _handleToggleBooking(context, ex),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 40),
                    backgroundColor: const Color(0xFF0F9D58).withValues(alpha: 0.05),
                    side: const BorderSide(
                      color: Color(0xFF0F9D58),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Color(0xFF0F9D58),
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                )
              : ElevatedButton(
                  onPressed: () => _handleToggleBooking(context, ex),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 40),
                    backgroundColor: AppColors.primaryText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text(
                    'Open',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _handleToggleBooking(BuildContext context, ExhibitionModel ex) async {
    final provider = context.read<ExhibitionProvider>();
    final bool nextStatus = !ex.isBookingOpen;

    if (!nextStatus) {
      // User is attempting to CLOSE booking -> Show confirmation dialog
      final confirm = await BaseDialog.show<bool>(
        context: context,
        title: 'Close Booking?',
        message: 'Exhibitors will no longer be able to apply for this exhibition.',
        variant: DialogVariant.warning,
        primaryLabel: 'Close Booking',
        secondaryLabel: 'Cancel',
        onPrimaryPressed: () => Navigator.pop(context, true),
        onSecondaryPressed: () => Navigator.pop(context, false),
      );

      if (confirm != true) return;
    }

    final success = await provider.toggleBookingOpen(
      ex.id, 
      nextStatus,
      ex.organizerId,
    );
    if (context.mounted) {
      if (success) {
        FeedbackHelper.showSuccess(
          context,
          'Booking status updated',
        );
      } else {
        FeedbackHelper.showError(
          context,
          'Update failed',
        );
      }
    }
  }

  void _handleDelete(BuildContext context, ExhibitionModel ex) async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    // 1. Role verification check (Owner Organizer or Admin)
    if (user.role == 'Organizer' && user.uid != ex.organizerId) {
      FeedbackHelper.showError(
        context,
        'You are not authorized to delete this exhibition.',
      );
      return;
    }

    // 2. Fetch applications count
    final applicationProvider = context.read<ApplicationProvider>();
    final List<ApplicationModel> apps;
    if (user.role == 'Admin') {
      apps = applicationProvider.allApplications.where((a) => a.exhibitionId == ex.id).toList();
    } else {
      apps = applicationProvider.organizerApplications.where((a) => a.exhibitionId == ex.id).toList();
    }

    // 3. Block deletion if applications exist
    if (apps.isNotEmpty) {
      FeedbackHelper.showWarning(
        context,
        'This exhibition cannot be deleted because it already has applications. Please manage or close the applications instead.',
      );
      return;
    }

    // 4. Show confirmation dialog
    final confirm = await BaseDialog.show<bool>(
      context: context,
      title: 'Delete Exhibition',
      message: 'Are you sure you want to delete this exhibition? This action cannot be undone. This will also delete its booth packages and booth spots.',
      variant: DialogVariant.destructive,
      primaryLabel: 'Delete',
      secondaryLabel: 'Cancel',
      onPrimaryPressed: () => Navigator.pop(context, true),
      onSecondaryPressed: () => Navigator.pop(context, false),
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<ExhibitionProvider>();
      final success = await provider.deleteExhibition(ex.id, ex.organizerId);

      if (context.mounted) {
        if (success) {
          FeedbackHelper.showSuccess(
            context,
            'Exhibition deleted successfully!',
          );
          context.pop(); // Navigate back to exhibition list
        } else {
          FeedbackHelper.showError(
            context,
            provider.errorMessage ?? 'Deletion failed.',
          );
        }
      }
    }
  }

  Widget _buildBottomActionBar(BuildContext context, ExhibitionModel ex, bool isAdmin) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: isAdmin
              ? Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Delete',
                        isSecondary: true,
                        color: AppColors.primaryAccent,
                        height: 56,
                        borderRadius: 16,
                        onPressed: () => _handleDelete(context, ex),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ex.isPublished
                          ? AppButton(
                              text: 'Unpublish Event',
                              isSecondary: true,
                              color: AppColors.primaryText,
                              height: 56,
                              borderRadius: 16,
                              onPressed: () => _showPublishConfirmation(context, ex),
                            )
                          : AppButton(
                              text: 'Publish Event',
                              color: AppColors.primaryAccent,
                              height: 56,
                              borderRadius: 16,
                              onPressed: () => _showPublishConfirmation(context, ex),
                            ),
                    ),
                  ],
                )
              : AppButton(
                  text: 'Delete',
                  isSecondary: true,
                  color: AppColors.primaryAccent,
                  height: 56,
                  borderRadius: 16,
                  onPressed: () => _handleDelete(context, ex),
                ),
        ),
      ),
    );
  }

  Future<void> _showPublishConfirmation(BuildContext context, ExhibitionModel ex) async {
    final willPublish = !ex.isPublished;
    
    if (ex.eventStatus == 'Completed' && willPublish) {
      FeedbackHelper.showWarning(
        context,
        'Completed exhibitions cannot be published.',
      );
      return;
    }

    final confirm = await BaseDialog.show<bool>(
      context: context,
      title: willPublish ? 'Publish Event?' : 'Unpublish Event?',
      message: willPublish
          ? 'This event will become visible to exhibitors in Explore.'
          : 'This event will be hidden from Explore until published again.',
      variant: willPublish ? DialogVariant.info : DialogVariant.warning,
      primaryLabel: willPublish ? 'Publish' : 'Unpublish',
      secondaryLabel: 'Cancel',
      onPrimaryPressed: () => Navigator.pop(context, true),
      onSecondaryPressed: () => Navigator.pop(context, false),
    );

    if (confirm == true && context.mounted) {
      final provider = context.read<ExhibitionProvider>();
      final success = await provider.togglePublish(
        ex.id,
        willPublish,
        ex.organizerId,
      );

      if (context.mounted) {
        if (success) {
          FeedbackHelper.showSuccess(
            context,
            willPublish
                ? 'Exhibition published successfully!'
                : 'Exhibition unpublished successfully!',
          );
        } else {
          FeedbackHelper.showError(
            context,
            provider.errorMessage ?? 'Operation failed',
          );
        }
      }
    }
  }

  Widget _buildAdminContextSection(ExhibitionModel ex) {
    final String createdStr = ex.createdAt != null
        ? DateFormatHelper.formatDateTime(ex.createdAt!)
        : 'N/A';
    final String updatedStr = ex.updatedAt != null
        ? DateFormatHelper.formatDateTime(ex.updatedAt!)
        : 'N/A';
    final String publishStatus = ex.isPublished ? 'Published' : 'Draft';
    final String bookingStatus = ex.isBookingOpen ? 'Booking Open' : 'Booking Closed';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 34),
        _buildSectionHeader('ADMIN CONTEXT'),
        const SizedBox(height: 12),
        // Technical Details Card
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.admin_panel_settings_outlined, size: 16, color: Colors.grey.shade600),
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
              _buildAdminInfoRow(label: 'Exhibition ID', value: ex.id, showDivider: true),
              _buildAdminInfoRow(label: 'Created By ID', value: ex.organizerId, showDivider: true),
              _buildAdminInfoRow(label: 'Publish Status', value: publishStatus, showDivider: true),
              _buildAdminInfoRow(label: 'Booking Status', value: bookingStatus, showDivider: true),
              _buildAdminInfoRow(label: 'Created At', value: createdStr, showDivider: true),
              _buildAdminInfoRow(label: 'Updated At', value: updatedStr, showDivider: false),
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
                        color: hasValue ? AppColors.primaryText : Colors.grey.shade400,
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
