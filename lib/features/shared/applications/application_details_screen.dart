import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/date_format_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/booth_model.dart';
import '../../../data/models/booth_spot_model.dart';
import '../../../providers/application_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booth_provider.dart';
import '../../../providers/booth_spot_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../core/widgets/base_dialog.dart';
import '../../../providers/exhibition_provider.dart';
import 'widgets/edit_application_bottom_sheet.dart';
import 'widgets/reject_application_dialog.dart';
import 'widgets/payment_dialog.dart';
import '../../../core/utils/feedback_helper.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final ApplicationModel application;

  const ApplicationDetailsScreen({super.key, required this.application});

  @override
  State<ApplicationDetailsScreen> createState() => _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState extends State<ApplicationDetailsScreen> {
  bool _hasEditedRejectedApplication = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BoothProvider>().fetchBoothPackages(widget.application.exhibitionId);
      context.read<UserProvider>().fetchAllUsers();
      context.read<BoothSpotProvider>().fetchBoothSpots(widget.application.exhibitionId);
      context.read<ExhibitionProvider>().fetchAllExhibitions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final applicationProvider = context.watch<ApplicationProvider>();
    final user = authProvider.currentUser;
    
    // Find latest application data from provider to stay reactive
    final latestApp = applicationProvider.allApplications.firstWhere(
      (a) => a.id == widget.application.id,
      orElse: () => applicationProvider.userApplications.firstWhere(
        (a) => a.id == widget.application.id,
        orElse: () => applicationProvider.organizerApplications.firstWhere(
          (a) => a.id == widget.application.id,
          orElse: () => widget.application,
        ),
      ),
    );

    final boothProvider = context.watch<BoothProvider>();
    final spotProvider = context.watch<BoothSpotProvider>();
    final userProvider = context.watch<UserProvider>();

    // Resolve booth spot model
    final spot = spotProvider.boothSpots.firstWhere(
      (s) => s.id == latestApp.boothSpotId,
      orElse: () => BoothSpotModel(
        id: latestApp.boothSpotId,
        exhibitionId: latestApp.exhibitionId,
        spotNumber: latestApp.boothNumber,
        boothPackageId: '',
        status: 'Booked',
      ),
    );

    // Resolve package model using boothSpot's boothPackageId
    final BoothModel? package = spot.boothPackageId.isNotEmpty
        ? boothProvider.boothPackages.where((p) => p.id == spot.boothPackageId).firstOrNull
        : null;

    // Resolve applicant user
    final applicantUser = userProvider.users.where((u) => u.uid == latestApp.userId).firstOrNull;
    final exhibitionProvider = context.watch<ExhibitionProvider>();
    final exhibition = exhibitionProvider.allExhibitions
        .where((e) => e.id == latestApp.exhibitionId)
        .firstOrNull;
    final exhibitionName = exhibition?.name ?? 'Exhibition';
    final applicantName = applicantUser?.name ?? latestApp.companyName;

    final bool canEdit = user != null && (
      user.role == 'Admin' || 
      (user.role == 'Exhibitor' && user.uid == latestApp.userId && latestApp.status == 'Pending')
    );

    final bool isOrganizer = user?.role == 'Organizer';
    final bool isAdmin = user?.role == 'Admin';
    final bool isPending = latestApp.status == 'Pending';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'Application Details',
              showBackButton: true,
              actions: [
                if (canEdit)
                  IconButton(
                    onPressed: () async {
                      final edited = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => EditApplicationBottomSheet(
                          application: latestApp,
                        ),
                      );
                      if (edited == true && mounted) {
                        setState(() {
                          _hasEditedRejectedApplication = true;
                        });
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                  ),
              ],
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: _NoOverscrollBehavior(),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: 120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Top Summary Card
                    _buildTopSummaryCard(latestApp, exhibitionName, applicantName),

                    // B. Conditional Alert Banners
                    _buildAlertBanner(latestApp),

                    // C. Applicant Information Section
                    _buildDetailsSectionHeader('APPLICANT INFORMATION'),
                    _buildDataCard([
                      _buildInfoRow(
                        label: 'Company Name',
                        value: latestApp.companyName,
                        showDivider: true,
                      ),
                      _buildInfoRow(
                        label: 'Business Type',
                        value: latestApp.businessType,
                        showDivider: true,
                      ),
                      _buildInfoRow(
                        label: 'Applied By',
                        value: applicantName,
                        showDivider: false,
                      ),
                    ]),

                    // D. Contact Information Section
                    if (applicantUser != null) ...[
                      _buildDetailsSectionHeader('CONTACT INFORMATION'),
                      _buildDataCard([
                        _buildInfoRow(
                          label: 'Contact Person',
                          value: applicantUser.name,
                          showDivider: true,
                        ),
                        _buildInfoRow(
                          label: 'Email Address',
                          value: applicantUser.email,
                          showDivider: false,
                        ),
                      ]),
                    ],

                    // E. Exhibit Information Section
                    _buildDetailsSectionHeader('EXHIBIT DETAILS'),
                    _buildDataCard([
                      _buildInfoRow(
                        label: 'Product / Service Name',
                        value: latestApp.productName,
                        showDivider: true,
                      ),
                      _buildInfoRow(
                        label: 'Description',
                        value: latestApp.description,
                        showDivider: true,
                      ),
                      _buildInfoRow(
                        label: 'Exhibition',
                        value: exhibitionName,
                        showDivider: false,
                      ),
                    ]),

                    // F. Booth Details Section
                    _buildDetailsSectionHeader('BOOTH DETAILS'),
                    _buildDataCard([
                      _buildInfoRow(
                        label: 'Booth Spot',
                        value: 'Booth ${latestApp.boothNumber}',
                        showDivider: true,
                      ),
                      if (package != null) ...[
                        _buildInfoRow(
                          label: 'Package Name',
                          value: package.name,
                          showDivider: true,
                        ),
                        _buildInfoRow(
                          label: 'Size',
                          value: package.size,
                          showDivider: true,
                        ),
                        _buildInfoRow(
                          label: 'Price',
                          value: 'RM ${package.price.toStringAsFixed(0)}',
                          showDivider: true,
                        ),
                      ],
                      _buildInfoRow(
                        label: 'Participation Period',
                        value: (latestApp.participationStartDate != null && latestApp.participationEndDate != null)
                            ? '${DateFormatHelper.formatDate(latestApp.participationStartDate!)} - ${DateFormatHelper.formatDate(latestApp.participationEndDate!)}'
                            : 'Full Event Duration',
                        showDivider: false,
                      ),
                    ]),

                    // G. Included Amenities Section
                    _buildDetailsSectionHeader('INCLUDED AMENITIES'),
                    _buildDataCard([
                      if (package == null || package.amenities.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'No included amenities listed',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: package.amenities.map((a) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200, width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 14, color: Colors.green.shade600),
                                  const SizedBox(width: 6),
                                  Text(
                                    a,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ]),

                    // H. Additional Requirements Section
                    _buildDetailsSectionHeader('ADDITIONAL REQUIREMENTS'),
                    _buildDataCard([
                      if (latestApp.requirements.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'No additional requirements',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: latestApp.requirements.map((r) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.15), width: 0.8),
                              ),
                              child: Text(
                                r,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ]),

                    // H.2 Payment Information Section (Only if status is Paid)
                    if (latestApp.status == 'Paid') ...[
                      _buildDetailsSectionHeader('PAYMENT INFORMATION'),
                      _buildPaymentInfoCard(latestApp),
                    ],

                    // I. Technical Debug Info Section (Admin Only)
                    if (isAdmin) ...[
                      _buildDetailsSectionHeader('ADMIN CONTEXT'),
                      _buildAdminDebugCard(latestApp),
                    ],
                  ],
                ),
              ),
            ),
          ),
            if (isPending && (isOrganizer || isAdmin))
              _buildBottomActionContainer(context, user, latestApp),
            if (!isOrganizer && !isAdmin && user != null && latestApp.userId == user.uid) ...[
              if (latestApp.status == 'Pending')
                _buildExhibitorCancelContainer(context, user, latestApp),
              if (latestApp.status == 'Approved')
                _buildExhibitorPaymentContainer(context, user, latestApp),
              if (latestApp.status == 'Rejected')
                _buildExhibitorResubmitContainer(context, user, latestApp),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 12),
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

  Widget _buildTopSummaryCard(ApplicationModel app, String exhibitionName, String applicantName) {
    final String appliedDate = app.createdAt != null ? DateFormatHelper.formatDate(app.createdAt!) : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Company Name & Status Badge aligned beautifully
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  app.companyName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    color: AppColors.primaryText,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(label: app.status),
            ],
          ),
          
          // Second line: Business Type
          const SizedBox(height: 4),
          Text(
            app.businessType,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Gap before the metadata block
          const SizedBox(height: 16),
          
          // Metadata block: Exhibition Name & Compact Applied By / Date Info
          Text(
            exhibitionName,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Applied by $applicantName • $appliedDate',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(ApplicationModel app) {
    if (app.status == 'Rejected' && app.rejectReason != null && app.rejectReason!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 20, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rejection Note',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app.rejectReason!,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    if (app.status == 'Pending') {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade100, width: 0.8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 20, color: Colors.amber.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Under Review',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your application is pending review by the exhibition organizer.',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildDataCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow({
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

  Widget _buildAdminDebugCard(ApplicationModel app) {
    return Container(
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
          _buildInfoRow(label: 'Exhibition ID', value: app.exhibitionId, showDivider: true),
          _buildInfoRow(label: 'User ID', value: app.userId, showDivider: true),
          _buildInfoRow(label: 'Booth Spot ID', value: app.boothSpotId, showDivider: false),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard(ApplicationModel app) {
    final paidDateStr = app.paidAt != null ? DateFormatHelper.formatDateTime(app.paidAt!) : 'N/A';

    return _buildDataCard([
      _buildInfoRow(
        label: 'Payment Method',
        value: app.paymentMethod ?? 'N/A',
        showDivider: true,
      ),
      _buildInfoRow(
        label: 'Transaction ID',
        value: app.transactionId ?? 'N/A',
        showDivider: true,
      ),
      _buildInfoRow(
        label: 'Payment Date',
        value: paidDateStr,
        showDivider: false,
      ),
    ]);
  }

  Widget _buildExhibitorCancelContainer(BuildContext context, dynamic user, ApplicationModel app) {
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Cancel Application',
            isSecondary: true,
            color: AppColors.primaryAccent,
            height: 56,
            borderRadius: 16,
            onPressed: () => _handleCancel(context, app),
          ),
        ),
      ),
    );
  }

  Widget _buildExhibitorPaymentContainer(BuildContext context, dynamic user, ApplicationModel app) {
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Pay Now',
            color: AppColors.primaryAccent,
            height: 56,
            borderRadius: 16,
            onPressed: () async {
              final paid = await showDialog<bool>(
                context: context,
                builder: (context) => PaymentDialog(application: app),
              );
              if (paid == true && context.mounted) {
                FeedbackHelper.showSuccess(
                  context,
                  'Payment completed successfully!',
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExhibitorResubmitContainer(BuildContext context, dynamic user, ApplicationModel app) {
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Resubmit',
            color: AppColors.primaryAccent,
            height: 56,
            borderRadius: 16,
            onPressed: () {
              if (!_hasEditedRejectedApplication) {
                FeedbackHelper.showWarning(
                  context,
                  'Please edit your application before resubmitting.',
                );
                return;
              }
              _handleResubmit(context, app);
            },
          ),
        ),
      ),
    );
  }

  void _handleCancel(BuildContext context, ApplicationModel app) async {
    final provider = context.read<ApplicationProvider>();

    final confirm = await BaseDialog.show<bool>(
      context: context,
      title: 'Cancel Application?',
      message: 'Are you sure you want to cancel this application? This action cannot be undone.',
      variant: DialogVariant.warning,
      primaryLabel: 'Cancel Application',
      secondaryLabel: 'Keep Application',
      onPrimaryPressed: () => Navigator.pop(context, true),
      onSecondaryPressed: () => Navigator.pop(context, false),
    );

    if (confirm != true) return;

    final success = await provider.updateApplicationStatus(
      applicationId: app.id,
      boothSpotId: app.boothSpotId,
      status: 'Cancelled',
    );

    if (success) {
      await provider.fetchUserApplications(app.userId);
      if (context.mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Application cancelled successfully',
        );
      }
    } else {
      if (context.mounted) {
        FeedbackHelper.showError(
          context,
          'Failed to cancel application. Please try again.',
        );
      }
    }
  }

  void _handleResubmit(BuildContext context, ApplicationModel app) async {
    final provider = context.read<ApplicationProvider>();
    final spotProvider = context.read<BoothSpotProvider>();

    // Safety check first
    await spotProvider.fetchBoothSpots(app.exhibitionId);
    final latestSpot = spotProvider.boothSpots
        .where((s) => s.id == app.boothSpotId)
        .firstOrNull;

    if (latestSpot == null || latestSpot.status != 'Available') {
      if (context.mounted) {
        FeedbackHelper.showError(
          context,
          'This booth is no longer available. Please select another booth.',
        );
      }
      return;
    }

    // Prepare resubmitted application details
    final resubmittedApp = app.copyWith(
      status: 'Pending',
      rejectReason: '',
      createdAt: DateTime.now(),
    );

    // Call updateApplication to update Firestore
    final success = await provider.updateApplication(resubmittedApp);

    if (success) {
      // Update booth spot status to Pending
      await spotProvider.updateBoothSpotStatus(
        app.boothSpotId,
        'Pending',
        app.exhibitionId,
      );

      setState(() {
        _hasEditedRejectedApplication = false; // Reset local state tracking
      });

      if (context.mounted) {
        FeedbackHelper.showSuccess(
          context,
          'Application resubmitted successfully!',
        );
      }
    } else {
      if (context.mounted) {
        FeedbackHelper.showError(
          context,
          'Resubmission failed. Please try again.',
        );
      }
    }
  }

  Widget _buildBottomActionContainer(BuildContext context, dynamic user, ApplicationModel app) {
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Reject',
                isSecondary: true,
                color: AppColors.primaryAccent,
                height: 56,
                borderRadius: 16,
                onPressed: () => _handleReject(context, user, app),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AppButton(
                text: 'Approve',
                color: AppColors.primaryText,
                height: 56,
                borderRadius: 16,
                onPressed: () => _handleApprove(context, user, app),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleApprove(BuildContext context, dynamic user, ApplicationModel app) {
    BaseDialog.show(
      context: context,
      title: 'Approve Application?',
      message: 'This will approve the application and reserve the selected booth for the applicant.',
      variant: DialogVariant.info,
      primaryLabel: 'Approve',
      secondaryLabel: 'Cancel',
      onPrimaryPressed: () async {
        Navigator.pop(context); // Close confirmation dialog
        final provider = context.read<ApplicationProvider>();
        final success = await provider.updateApplicationStatus(
          applicationId: app.id,
          boothSpotId: app.boothSpotId,
          status: 'Approved',
          organizerId: user.role == 'Organizer' ? user.uid : null,
        );

        if (context.mounted) {
          if (success) {
            FeedbackHelper.showSuccess(
              context,
              'Application approved',
            );
          } else {
            FeedbackHelper.showError(
              context,
              'Approval failed',
            );
          }
        }
      },
    );
  }

  void _handleReject(BuildContext context, dynamic user, ApplicationModel app) {
    showDialog(
      context: context,
      builder: (context) => RejectApplicationDialog(
        title: 'Reject Application',
        subtitle: 'Please provide a reason for rejecting this application.',
        onConfirm: (reason) async {
          final provider = Provider.of<ApplicationProvider>(context, listen: false);
          final success = await provider.updateApplicationStatus(
            applicationId: app.id,
            boothSpotId: app.boothSpotId,
            status: 'Rejected',
            rejectReason: reason,
            organizerId: user.role == 'Organizer' ? user.uid : null,
          );

          if (context.mounted) {
            if (success) {
              FeedbackHelper.showSuccess(
                context,
                'Application rejected',
              );
            } else {
              FeedbackHelper.showError(
                context,
                'Rejection failed',
              );
            }
          }
        },
      ),
    );
  }
}

class _NoOverscrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
