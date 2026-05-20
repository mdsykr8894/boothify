import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_bottom_sheet_scaffold.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/feedback_helper.dart';

class PersonalInformationScreen extends StatelessWidget {
  const PersonalInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppPageHeader(
              title: 'Personal Information',
              showBackButton: true,
            ),
            Expanded(
              child: user == null
                  ? const Center(child: CircularProgressIndicator())
                  : ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 24,
                          top: 12,
                          bottom: 40,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Row 1: Legal Name
                            _buildInfoRow(
                              context,
                              label: 'Legal name',
                              value: user.name,
                              onActionPressed: () => _showEditBottomSheet(
                                context,
                                fieldName: 'name',
                                label: 'Legal name',
                                currentValue: user.name,
                                isRequired: true,
                              ),
                            ),
                            _buildDivider(),

                            // Row 2: Preferred Name
                            _buildInfoRow(
                              context,
                              label: 'Preferred first name',
                              value: user.preferredName,
                              onActionPressed: () => _showEditBottomSheet(
                                context,
                                fieldName: 'preferredName',
                                label: 'Preferred first name',
                                currentValue: user.preferredName ?? '',
                              ),
                            ),
                            _buildDivider(),

                            // Row 3: Phone Number
                            _buildInfoRow(
                              context,
                              label: 'Phone number',
                              value: user.phoneNumber,
                              onActionPressed: () => _showEditBottomSheet(
                                context,
                                fieldName: 'phoneNumber',
                                label: 'Phone number',
                                currentValue: user.phoneNumber ?? '',
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                            _buildDivider(),

                            // Row 4: Email Address
                            _buildInfoRow(
                              context,
                              label: 'Email address',
                              value: user.email,
                              onActionPressed: () => _showEditBottomSheet(
                                context,
                                fieldName: 'email',
                                label: 'Email address',
                                currentValue: user.email,
                                isRequired: true,
                                keyboardType: TextInputType.emailAddress,
                              ),
                            ),
                            _buildDivider(),

                            // Row 5: Residential Address
                            _buildInfoRow(
                              context,
                              label: 'Residential address',
                              value: user.residentialAddress,
                              onActionPressed: () => _showEditBottomSheet(
                                context,
                                fieldName: 'residentialAddress',
                                label: 'Residential address',
                                currentValue: user.residentialAddress ?? '',
                                maxLines: 2,
                              ),
                            ),
                            _buildDivider(),

                            // Row 6: Postal Address
                            _buildInfoRow(
                              context,
                              label: 'Postal address',
                              value: user.postalAddress,
                              onActionPressed: () => _showEditBottomSheet(
                                context,
                                fieldName: 'postalAddress',
                                label: 'Postal address',
                                currentValue: user.postalAddress ?? '',
                                maxLines: 2,
                              ),
                            ),
                            _buildDivider(),

                            // Row 7: Emergency Contact
                            _buildInfoRow(
                              context,
                              label: 'Emergency contact',
                              value: user.emergencyContact,
                              onActionPressed: () => _showEditBottomSheet(
                                context,
                                fieldName: 'emergencyContact',
                                label: 'Emergency contact',
                                currentValue: user.emergencyContact ?? '',
                              ),
                            ),
                            _buildDivider(),

                            // Row 8: Identity Verification Status (DISPLAY ONLY)
                            _buildInfoRow(
                              context,
                              label: 'Identity verification',
                              value: user.isVerified ? 'Verified' : 'Not verified',
                              isReadOnly: true,
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String? value,
    VoidCallback? onActionPressed,
    bool isReadOnly = false,
  }) {
    final bool hasValue = value != null && value.trim().isNotEmpty;
    final String displayValue = (value != null && value.trim().isNotEmpty) ? value : 'Not provided';
    final String actionText = isReadOnly ? '' : (hasValue ? 'Edit' : '+ Add');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 15,
                    color: hasValue ? Colors.grey.shade600 : Colors.grey.shade400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Right Action Button
          if (!isReadOnly && onActionPressed != null) ...[
            const SizedBox(width: 16),
            InkWell(
              onTap: onActionPressed,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 2, right: 2, bottom: 2),
                child: Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryAccent,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showEditBottomSheet(
    BuildContext context, {
    required String fieldName,
    required String label,
    required String currentValue,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _EditFieldBottomSheet(
          fieldName: fieldName,
          label: label,
          currentValue: currentValue,
          isRequired: isRequired,
          keyboardType: keyboardType,
          maxLines: maxLines,
        );
      },
    );
  }
}

class _EditFieldBottomSheet extends StatefulWidget {
  final String fieldName;
  final String label;
  final String currentValue;
  final bool isRequired;
  final TextInputType keyboardType;
  final int maxLines;

  const _EditFieldBottomSheet({
    required this.fieldName,
    required this.label,
    required this.currentValue,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  State<_EditFieldBottomSheet> createState() => _EditFieldBottomSheetState();
}

class _EditFieldBottomSheetState extends State<_EditFieldBottomSheet> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _formError = null;
    });

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);
      
      final String finalVal = _controller.text.trim();
      final authProvider = context.read<AuthProvider>();

      final bool success = await authProvider.updatePersonalInformation({
        widget.fieldName: finalVal,
      });

      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          Navigator.pop(context);
          if (context.mounted) {
            FeedbackHelper.showSuccess(
              context,
              '${widget.label} updated successfully!',
            );
          }
        } else {
          setState(() {
            _formError = authProvider.errorMessage ?? 'Failed to save changes. Please try again.';
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      title: 'Edit ${widget.label}',
      primaryLabel: 'Save Changes',
      isLoading: _isSaving,
      onPrimaryPressed: _isSaving ? null : _handleSave,
      isScrollable: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_formError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.2),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.primaryAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formError!,
                        style: const TextStyle(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            AppTextField(
              controller: _controller,
              label: widget.label,
              hint: 'Enter your ${widget.label.toLowerCase()}',
              keyboardType: widget.keyboardType,
              maxLines: widget.maxLines,
              validator: (val) {
                if (widget.isRequired && (val == null || val.trim().isEmpty)) {
                  return 'This field is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
