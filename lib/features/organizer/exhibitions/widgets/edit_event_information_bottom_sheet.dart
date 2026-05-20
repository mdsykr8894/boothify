import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/exhibition_model.dart';
import '../../../../providers/exhibition_provider.dart';
import '../../../../core/utils/feedback_helper.dart';

class EditEventInformationBottomSheet extends StatefulWidget {
  final ExhibitionModel exhibition;

  const EditEventInformationBottomSheet({super.key, required this.exhibition});

  @override
  State<EditEventInformationBottomSheet> createState() =>
      _EditEventInformationBottomSheetState();
}

class _EditEventInformationBottomSheetState
    extends State<EditEventInformationBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _openingHoursController;
  late TextEditingController _expectedVisitorsController;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _contactEmailController =
        TextEditingController(text: widget.exhibition.contactEmail);
    _contactPhoneController =
        TextEditingController(text: widget.exhibition.contactPhone);
    _openingHoursController =
        TextEditingController(text: widget.exhibition.openingHours);
    _expectedVisitorsController =
        TextEditingController(text: widget.exhibition.expectedVisitors);
  }

  @override
  void dispose() {
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _openingHoursController.dispose();
    _expectedVisitorsController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    setState(() {
      _formError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final email = _contactEmailController.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _formError = 'Please enter a valid email address';
      });
      return;
    }

    final updatedExhibition = widget.exhibition.copyWith(
      contactEmail: email,
      contactPhone: _contactPhoneController.text.trim(),
      openingHours: _openingHoursController.text.trim(),
      expectedVisitors: _expectedVisitorsController.text.trim(),
    );

    final provider = context.read<ExhibitionProvider>();
    final success = await provider.updateExhibition(updatedExhibition);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        if (context.mounted) {
          FeedbackHelper.showSuccess(
            context,
            'Event information updated successfully',
          );
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
      title: 'Edit Event Info',
      primaryLabel: 'Save Changes',
      isLoading: context.watch<ExhibitionProvider>().isLoading,
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
              controller: _contactEmailController,
              label: 'Contact Email (Optional)',
              hint: 'e.g. contact@expo.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: _contactPhoneController,
              label: 'Contact Phone (Optional)',
              hint: 'e.g. +60123456789',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: _openingHoursController,
              label: 'Opening Hours (Optional)',
              hint: 'e.g. 9:00 AM - 6:00 PM',
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: _expectedVisitorsController,
              label: 'Expected Visitors (Optional)',
              hint: 'e.g. 5,000+',
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }
}
