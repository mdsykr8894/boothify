import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/bottom_sheet_dropdown_field.dart';
import '../../../../data/models/user_model.dart';
import '../../../../providers/user_provider.dart';
import '../../../../core/utils/feedback_helper.dart';

// Bottom sheet for editing basic user account details.
class EditUserBottomSheet extends StatefulWidget {
  final UserModel user;

  const EditUserBottomSheet({super.key, required this.user});

  @override
  State<EditUserBottomSheet> createState() => _EditUserBottomSheetState();
}

class _EditUserBottomSheetState extends State<EditUserBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedRole;
  final List<String> _roles = ['Exhibitor', 'Organizer', 'Admin'];
  String? _formError;

  @override
  void initState() {
    super.initState();

    // Fill form with current user data.
    _nameController = TextEditingController(text: widget.user.name);
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    setState(() {
      _formError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    // Prepare updated user account data.
    final updatedUser = widget.user.copyWith(
      name: _nameController.text.trim(),
      role: _selectedRole,
    );

    final provider = context.read<UserProvider>();

    // Save updated user through provider.
    final success = await provider.updateUser(updatedUser);

    if (mounted) {
      if (success) {
        Navigator.pop(context, updatedUser);

        if (context.mounted) {
          FeedbackHelper.showSuccess(context, 'User updated successfully');
        }
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
      title: 'Edit User',
      primaryLabel: 'Save Changes',
      isLoading: context.watch<UserProvider>().isLoading,
      onPrimaryPressed: _handleSave,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show form error message.
            if (_formError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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

            // Edit user full name.
            AppTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter user full name',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.m),

            // Select user role.
            BottomSheetDropdownField<String>(
              label: 'Role',
              hint: 'Select user role',
              value: _selectedRole,
              items: _roles.map((role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
