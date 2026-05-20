import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/user_model.dart';
import '../../../../providers/user_provider.dart';
import '../../../../core/utils/feedback_helper.dart';

class EditPersonalInfoBottomSheet extends StatefulWidget {
  final UserModel user;

  const EditPersonalInfoBottomSheet({super.key, required this.user});

  @override
  State<EditPersonalInfoBottomSheet> createState() => _EditPersonalInfoBottomSheetState();
}

class _EditPersonalInfoBottomSheetState extends State<EditPersonalInfoBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _preferredNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _contactEmailController;
  late TextEditingController _residentialAddressController;
  late TextEditingController _postalAddressController;
  late TextEditingController _emergencyContactController;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _preferredNameController = TextEditingController(text: widget.user.preferredName);
    _phoneNumberController = TextEditingController(text: widget.user.phoneNumber);
    _contactEmailController = TextEditingController(text: widget.user.contactEmail ?? widget.user.email);
    _residentialAddressController = TextEditingController(text: widget.user.residentialAddress);
    _postalAddressController = TextEditingController(text: widget.user.postalAddress);
    _emergencyContactController = TextEditingController(text: widget.user.emergencyContact);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _preferredNameController.dispose();
    _phoneNumberController.dispose();
    _contactEmailController.dispose();
    _residentialAddressController.dispose();
    _postalAddressController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    setState(() {
      _formError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final fields = {
      'name': _nameController.text.trim(),
      'preferredName': _preferredNameController.text.trim(),
      'phoneNumber': _phoneNumberController.text.trim(),
      'contactEmail': _contactEmailController.text.trim(),
      'residentialAddress': _residentialAddressController.text.trim(),
      'postalAddress': _postalAddressController.text.trim(),
      'emergencyContact': _emergencyContactController.text.trim(),
    };

    final provider = context.read<UserProvider>();
    final success = await provider.updateUserFields(widget.user.uid, fields);

    if (mounted) {
      if (success) {
        final updatedUser = widget.user.copyWith(
          name: fields['name'],
          preferredName: fields['preferredName'],
          phoneNumber: fields['phoneNumber'],
          contactEmail: fields['contactEmail'],
          residentialAddress: fields['residentialAddress'],
          postalAddress: fields['postalAddress'],
          emergencyContact: fields['emergencyContact'],
        );
        Navigator.pop(context, updatedUser);
        FeedbackHelper.showSuccess(context, 'Personal information updated successfully');
      } else {
        setState(() {
          _formError = 'Update failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetScaffold(
      title: 'Edit Personal Info',
      isScrollable: true,
      maxHeightFactor: 0.80,
      primaryLabel: 'Save Changes',
      isLoading: context.watch<UserProvider>().isLoading,
      onPrimaryPressed: _handleSave,
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
              const SizedBox(height: AppSpacing.m),
            ],
            AppTextField(
              controller: _nameController,
              label: 'Legal Name',
              hint: 'Enter legal/full name',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: _preferredNameController,
              label: 'Preferred First Name',
              hint: 'Enter preferred first name',
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: _phoneNumberController,
              label: 'Phone Number',
              hint: 'Enter phone number',
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: _contactEmailController,
              label: 'Contact Email',
              hint: 'Enter contact email address',
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: _residentialAddressController,
              label: 'Residential Address',
              hint: 'Enter residential address',
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: _postalAddressController,
              label: 'Postal Address',
              hint: 'Enter postal address',
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: _emergencyContactController,
              label: 'Emergency Contact',
              hint: 'Enter emergency contact details',
            ),
          ],
        ),
      ),
    );
  }
}
