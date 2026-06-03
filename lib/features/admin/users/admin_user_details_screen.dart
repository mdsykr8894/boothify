import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/date_format_helper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/base_dialog.dart';
import '../../../../data/models/user_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/user_provider.dart';
import 'widgets/edit_user_bottom_sheet.dart';
import 'widgets/edit_personal_info_bottom_sheet.dart';
import '../../../../core/utils/feedback_helper.dart';

// Display selected user details for admin.
class AdminUserDetailsScreen extends StatefulWidget {
  final UserModel user;

  const AdminUserDetailsScreen({super.key, required this.user});

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  // Store editable local user state.
  late UserModel _currentUser;

  @override
  void initState() {
    super.initState();

    // Initialize selected user data.
    _currentUser = widget.user;
  }

  void _handleStatusToggle(BuildContext context) {
    final admin = context.read<AuthProvider>().currentUser;

    // Prevent admin from deactivating own account.
    if (admin?.uid == _currentUser.uid) {
      FeedbackHelper.showWarning(
        context,
        'You cannot deactivate your own account.',
      );
      return;
    }

    final newStatus = !_currentUser.isActive;

    BaseDialog.show(
      context: context,
      title: newStatus ? 'Activate Account?' : 'Deactivate Account?',
      message: newStatus
          ? 'This user will regain access to their account.'
          : 'This user will no longer be able to access their account.',
      variant: newStatus ? DialogVariant.info : DialogVariant.destructive,
      primaryLabel: newStatus ? 'Activate' : 'Deactivate',
      secondaryLabel: 'Cancel',
      onPrimaryPressed: () async {
        Navigator.pop(context);

        final provider = context.read<UserProvider>();

        // Update user active status.
        final success = await provider.updateUserActiveStatus(
          _currentUser.uid,
          newStatus,
        );

        if (mounted && success) {
          setState(() {
            _currentUser = _currentUser.copyWith(isActive: newStatus);
          });

          if (context.mounted) {
            FeedbackHelper.showSuccess(
              context,
              'Account ${newStatus ? 'activated' : 'deactivated'}',
            );
          }
        }
      },
    );
  }

  void _showEditSheet() async {
    // Open account edit bottom sheet.
    final updatedUser = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditUserBottomSheet(user: _currentUser),
    );

    if (updatedUser != null) {
      setState(() {
        _currentUser = updatedUser;
      });
    }
  }

  void _showEditPersonalInfoSheet() async {
    // Open personal info edit bottom sheet.
    final updatedUser = await showModalBottomSheet<UserModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPersonalInfoBottomSheet(user: _currentUser),
    );

    if (updatedUser != null) {
      setState(() {
        _currentUser = updatedUser;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            AppPageHeader(
              title: 'User Details',
              showBackButton: true,
              actions: [
                IconButton(
                  onPressed: _showEditSheet,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.m,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show user profile summary.
                    _buildProfileSummaryCard(),
                    const SizedBox(height: 24),

                    // Show account information header.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ACCOUNT INFORMATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.0,
                          ),
                        ),

                        // Show account status badge.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (_currentUser.isActive
                                        ? Colors.green
                                        : Colors.red)
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _currentUser.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _currentUser.isActive
                                  ? Colors.green
                                  : Colors.red,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Show account information card.
                    _buildPremiumCard(
                      children: [
                        _buildInfoRow(
                          label: 'User ID',
                          value: _currentUser.uid,
                        ),
                        _buildInfoRow(
                          label: 'Email Address',
                          value: _currentUser.email,
                        ),
                        _buildInfoRow(label: 'Role', value: _currentUser.role),
                        _buildInfoRow(
                          label: 'Created At',
                          value: _currentUser.createdAt != null
                              ? DateFormatHelper.formatDateTime(
                                  _currentUser.createdAt!,
                                )
                              : 'Not provided',
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Show personal information header.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PERSONAL INFORMATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                            letterSpacing: 1.0,
                          ),
                        ),
                        TextButton(
                          onPressed: _showEditPersonalInfoSheet,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            '+ Edit Info',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Show personal information card.
                    _buildPremiumCard(
                      children: [
                        _buildInfoRow(
                          label: 'Legal Name',
                          value: _currentUser.name,
                        ),
                        _buildInfoRow(
                          label: 'Preferred First Name',
                          value: _currentUser.preferredName?.isNotEmpty == true
                              ? _currentUser.preferredName!
                              : 'Not provided',
                        ),
                        _buildInfoRow(
                          label: 'Phone Number',
                          value: _currentUser.phoneNumber?.isNotEmpty == true
                              ? _currentUser.phoneNumber!
                              : 'Not provided',
                        ),
                        _buildInfoRow(
                          label: 'Contact Email',
                          value: _currentUser.contactEmail?.isNotEmpty == true
                              ? _currentUser.contactEmail!
                              : _currentUser.email,
                        ),
                        _buildInfoRow(
                          label: 'Residential Address',
                          value:
                              _currentUser.residentialAddress?.isNotEmpty ==
                                  true
                              ? _currentUser.residentialAddress!
                              : 'Not provided',
                        ),
                        _buildInfoRow(
                          label: 'Postal Address',
                          value: _currentUser.postalAddress?.isNotEmpty == true
                              ? _currentUser.postalAddress!
                              : 'Not provided',
                        ),
                        _buildInfoRow(
                          label: 'Emergency Contact',
                          value:
                              _currentUser.emergencyContact?.isNotEmpty == true
                              ? _currentUser.emergencyContact!
                              : 'Not provided',
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Show exhibitor company information.
                    if (_currentUser.role.toLowerCase() == 'exhibitor') ...[
                      Text(
                        'COMPANY INFORMATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPremiumCard(
                        children: [
                          _buildInfoRow(
                            label: 'Company Name',
                            value: _currentUser.companyName?.isNotEmpty == true
                                ? _currentUser.companyName!
                                : 'Not provided',
                          ),
                          _buildInfoRow(
                            label: 'Business Type',
                            value: _currentUser.businessType?.isNotEmpty == true
                                ? _currentUser.businessType!
                                : 'Not provided',
                          ),
                          _buildInfoRow(
                            label: 'Registration Number',
                            value:
                                _currentUser.companyRegistration?.isNotEmpty ==
                                    true
                                ? _currentUser.companyRegistration!
                                : 'Not provided',
                          ),
                          _buildInfoRow(
                            label: 'Product Category',
                            value:
                                _currentUser.productCategory?.isNotEmpty == true
                                ? _currentUser.productCategory!
                                : 'Not provided',
                          ),
                          _buildInfoRow(
                            label: 'Contact Person',
                            value:
                                _currentUser.contactPerson?.isNotEmpty == true
                                ? _currentUser.contactPerson!
                                : 'Not provided',
                          ),
                          _buildInfoRow(
                            label: 'Company Phone',
                            value: _currentUser.companyPhone?.isNotEmpty == true
                                ? _currentUser.companyPhone!
                                : 'Not provided',
                          ),
                          _buildInfoRow(
                            label: 'Company Email',
                            value: _currentUser.companyEmail?.isNotEmpty == true
                                ? _currentUser.companyEmail!
                                : 'Not provided',
                            showDivider: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ] else if (_currentUser.role.toLowerCase() ==
                        'organizer') ...[
                      // Show organizer information.
                      Text(
                        'ORGANIZATION INFORMATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildPremiumCard(
                        children: [
                          _buildInfoRow(
                            label: 'Organization Name',
                            value:
                                _currentUser.organizationName?.isNotEmpty ==
                                    true
                                ? _currentUser.organizationName!
                                : 'Not provided',
                          ),
                          _buildInfoRow(
                            label: 'Organizer Phone',
                            value:
                                _currentUser.organizerPhone?.isNotEmpty == true
                                ? _currentUser.organizerPhone!
                                : 'Not provided',
                          ),
                          _buildInfoRow(
                            label: 'Organizer Email',
                            value:
                                _currentUser.organizerEmail?.isNotEmpty == true
                                ? _currentUser.organizerEmail!
                                : 'Not provided',
                          ),
                          _buildInfoRow(
                            label: 'Verification Status',
                            value:
                                _currentUser
                                        .organizerVerificationStatus
                                        ?.isNotEmpty ==
                                    true
                                ? _currentUser.organizerVerificationStatus!
                                : 'Not provided',
                            showDivider: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                    ],
                  ],
                ),
              ),
            ),

            // Show account activation action.
            _buildBottomStickyBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Show user initials avatar.
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.15),
                width: 3,
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFDF4F6),
              ),
              alignment: Alignment.center,
              child: Text(
                _currentUser.name.isNotEmpty
                    ? _currentUser.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Show user name and role.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _currentUser.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _currentUser.role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Show user email.
          Text(
            _currentUser.email,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
    required String value,
    bool showDivider = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildBottomStickyBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.screenHorizontal,
        right: AppSpacing.screenHorizontal,
        top: AppSpacing.m,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.m,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AppButton(
        text: _currentUser.isActive ? 'Deactivate Account' : 'Activate Account',
        color: _currentUser.isActive
            ? AppColors.primaryAccent
            : AppColors.success,
        isSecondary: true,
        onPressed: () => _handleStatusToggle(context),
      ),
    );
  }
}
