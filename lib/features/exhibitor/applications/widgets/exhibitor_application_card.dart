import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/application_model.dart';
import '../../../../providers/application_provider.dart';
import '../../../../providers/exhibition_provider.dart';
import '../../../../providers/user_provider.dart';
import '../../../shared/applications/widgets/payment_dialog.dart';
import '../../../../core/widgets/base_dialog.dart';
import '../../../../core/utils/feedback_helper.dart';

class ApplicationCard extends StatelessWidget {
  final ApplicationModel application;

  const ApplicationCard({super.key, required this.application});

  void _handleCancel(BuildContext context) async {
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
      applicationId: application.id,
      boothSpotId: application.boothSpotId,
      status: 'Cancelled',
    );

    if (success) {
      await provider.fetchUserApplications(application.userId);
      if (context.mounted) {
        FeedbackHelper.showSuccess(context, 'Application cancelled successfully');
      }
    } else {
      if (context.mounted) {
        FeedbackHelper.showError(context, 'Failed to cancel application. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // In-memory lookup: exhibition name
    final exhibitionProvider = context.watch<ExhibitionProvider>();
    final exhibition = exhibitionProvider.publishedExhibitions.any((e) => e.id == application.exhibitionId)
        ? exhibitionProvider.publishedExhibitions.firstWhere((e) => e.id == application.exhibitionId)
        : null;
    final String exhibitionName = exhibition?.name ?? application.exhibitionId;

    // In-memory lookup: applicant's real name from UserProvider
    final userProvider = context.watch<UserProvider>();
    final applicantUser = userProvider.users.any((u) => u.uid == application.userId)
        ? userProvider.users.firstWhere((u) => u.uid == application.userId)
        : null;
    final String applicantName = applicantUser?.name.isNotEmpty == true
        ? applicantUser!.name
        : application.companyName;

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
            // ── Top content area ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Applicant Company Name + Status Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          application.companyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.primaryText,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      StatusBadge(label: application.status),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Row 2: Business Type
                  Text(
                    application.businessType,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // ── 2-column info section ───────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // LEFT: Decorative thumbnail box
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCEEF3),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.storefront_outlined,
                          size: 36,
                          color: Color(0xFFE8789A),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // RIGHT: 3 compact metadata rows
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMetaRow(
                              Icons.confirmation_number_outlined,
                              exhibitionName,
                            ),
                            const SizedBox(height: 8),
                            _buildMetaRow(
                              Icons.grid_view_outlined,
                              'Booth ${application.boothNumber}',
                            ),
                            const SizedBox(height: 8),
                            _buildMetaRow(
                              Icons.person_outline_rounded,
                              'Applied by $applicantName',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Rejection reason alert ─────────────────────────────────
            if (application.rejectReason != null && application.status == 'Rejected') ...[
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100, width: 0.8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 15, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reason: ${application.rejectReason}',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Divider ───────────────────────────────────────────────
            Divider(height: 1, color: Colors.grey.shade100),

            // ── Action buttons ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildActionButtons(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (application.status == 'Pending') {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Cancel',
              isSecondary: true,
              color: Colors.red.shade600,
              height: 50,
              borderRadius: 12,
              onPressed: () => _handleCancel(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              text: 'View Details',
              color: AppColors.primaryText,
              height: 50,
              borderRadius: 12,
              onPressed: () => context.push(
                AppRoutes.applicationDetails,
                extra: application,
              ),
            ),
          ),
        ],
      );
    } else if (application.status == 'Approved') {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'View Details',
              isSecondary: true,
              color: AppColors.primaryText,
              height: 50,
              borderRadius: 12,
              onPressed: () => context.push(
                AppRoutes.applicationDetails,
                extra: application,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              text: 'Pay Now',
              color: AppColors.primaryAccent,
              height: 50,
              borderRadius: 12,
              onPressed: () async {
                final paid = await showDialog<bool>(
                  context: context,
                  builder: (context) => PaymentDialog(application: application),
                );
                if (paid == true && context.mounted) {
                  FeedbackHelper.showSuccess(context, 'Payment completed successfully!');
                  context.read<ApplicationProvider>().fetchUserApplications(application.userId);
                }
              },
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: AppButton(
          text: 'View Details',
          color: AppColors.primaryText,
          height: 50,
          borderRadius: 12,
          onPressed: () => context.push(
            AppRoutes.applicationDetails,
            extra: application,
          ),
        ),
      );
    }
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
