import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/bottom_sheet_date_field.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/booth_model.dart';
import '../../../data/models/booth_spot_model.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../providers/application_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/feedback_helper.dart';

class ApplicationFormScreen extends StatefulWidget {
  final ExhibitionModel exhibition;
  final BoothSpotModel boothSpot;
  final BoothModel boothPackage;

  const ApplicationFormScreen({
    super.key,
    required this.exhibition,
    required this.boothSpot,
    required this.boothPackage,
  });

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  // Form key for validating application input.
  final _formKey = GlobalKey<FormState>();

  // Controllers store user input from form fields.
  final _companyController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Store selected additional requirements.
  final List<String> _selectedRequirements = [];

  // Default requirement options.
  final List<String> _availableRequirements = [
    'Electricity',
    'WiFi',
    'Extra Table & Chair',
  ];

  // Store selected participation period.
  DateTime? _participationStartDate;
  DateTime? _participationEndDate;

  @override
  void initState() {
    super.initState();

    // Use full exhibition duration as default participation period.
    _participationStartDate = widget.exhibition.startDate;
    _participationEndDate = widget.exhibition.endDate;
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks.
    _companyController.dispose();
    _businessTypeController.dispose();
    _productNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleRequirement(String req) {
    // Add or remove selected requirement.
    setState(() {
      if (_selectedRequirements.contains(req)) {
        _selectedRequirements.remove(req);
      } else {
        _selectedRequirements.add(req);
      }
    });
  }

  Future<void> _selectParticipationDate(
    BuildContext context,
    bool isStart,
  ) async {
    // Open date picker within exhibition date range.
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_participationStartDate ?? widget.exhibition.startDate)
          : (_participationEndDate ?? widget.exhibition.endDate),
      firstDate: widget.exhibition.startDate,
      lastDate: widget.exhibition.endDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.primaryText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryText,
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Colors.white,
              headerForegroundColor: AppColors.primaryText,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              dayStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          // Update participation start date.
          _participationStartDate = picked;

          // Keep end date after start date.
          if (_participationEndDate != null &&
              _participationStartDate!.isAfter(_participationEndDate!)) {
            _participationEndDate = _participationStartDate;
          }
        } else {
          // Update participation end date.
          _participationEndDate = picked;

          // Keep start date before end date.
          if (_participationStartDate != null &&
              _participationEndDate!.isBefore(_participationStartDate!)) {
            _participationStartDate = _participationEndDate;
          }
        }
      });
    }
  }

  void _handleSubmit() async {
    // Fast local check before Firestore verification.
    if (!widget.exhibition.isBookingOpen) {
      FeedbackHelper.showError(
        context,
        'Booking is closed. You cannot submit an application for this exhibition.',
      );
      return;
    }

    // Validate required form fields.
    if (!_formKey.currentState!.validate()) return;

    // Require participation dates.
    if (_participationStartDate == null || _participationEndDate == null) {
      FeedbackHelper.showError(context, 'Please select participation dates.');
      return;
    }

    // Prevent invalid date range.
    if (_participationStartDate!.isAfter(_participationEndDate!)) {
      FeedbackHelper.showError(context, 'Start date cannot be after end date.');
      return;
    }

    // Ensure selected dates are within exhibition duration.
    if (_participationStartDate!.isBefore(widget.exhibition.startDate) ||
        _participationEndDate!.isAfter(widget.exhibition.endDate)) {
      FeedbackHelper.showError(
        context,
        'Participation dates must be within the exhibition duration.',
      );
      return;
    }

    // Get current logged-in user.
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    // Require login before submission.
    if (user == null) {
      FeedbackHelper.showWarning(context, 'Please login to submit application.');
      context.go(AppRoutes.login);
      return;
    }

    try {
      // Re-check booking status directly from Firestore.
      final doc = await FirebaseFirestore.instance
          .collection('exhibitions')
          .doc(widget.exhibition.id)
          .get();

      if (doc.exists) {
        final data = doc.data();

        if (data != null) {
          final isBookingOpen = data['isBookingOpen'] as bool? ?? true;

          if (!isBookingOpen) {
            if (!mounted) return;

            FeedbackHelper.showError(
              context,
              'Booking is closed. You cannot submit an application for this exhibition.',
            );
            return;
          }
        }
      }
    } catch (e) {
      // Do not block submission if verification check fails.
      debugPrint('Error verifying booking status: $e');
    }

    // Build application data before submitting.
    final application = ApplicationModel(
      id: '',
      userId: user.uid,
      exhibitionId: widget.exhibition.id,
      boothSpotId: widget.boothSpot.id,
      boothNumber: widget.boothSpot.spotNumber,
      companyName: _companyController.text.trim(),
      businessType: _businessTypeController.text.trim(),
      productName: _productNameController.text.trim(),
      description: _descriptionController.text.trim(),
      requirements: _selectedRequirements,
      status: 'Pending',
      createdAt: DateTime.now(),
      participationStartDate: _participationStartDate,
      participationEndDate: _participationEndDate,
    );

    if (!mounted) return;

    // Submit application through provider.
    final appProvider = context.read<ApplicationProvider>();
    final success = await appProvider.submitApplication(application);

    if (mounted) {
      if (success) {
        // Show success message and return to home.
        FeedbackHelper.showSuccess(
          context,
          'Application submitted successfully!',
        );
        context.go(AppRoutes.root);
      } else {
        // Show provider error if submission fails.
        FeedbackHelper.showError(
          context,
          appProvider.errorMessage ?? 'Submission failed.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch loading state for submit button.
    final isLoading = context.watch<ApplicationProvider>().isLoading;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(
              title: 'Application Form',
              showBackButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenHorizontal,
                  vertical: AppSpacing.m,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selected booth and package summary.
                      _buildSummaryCard(),
                      const SizedBox(height: AppSpacing.xl),

                      // Participation period section.
                      const Text(
                        'Participation Period',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'Select your intended stay duration. The booth package price remains fixed.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      Row(
                        children: [
                          BottomSheetDateField(
                            innerLabel: 'Start Date',
                            date: _participationStartDate ??
                                widget.exhibition.startDate,
                            onTap: () =>
                                _selectParticipationDate(context, true),
                            dateFormat: DateFormat('d MMM yyyy'),
                          ),
                          const SizedBox(width: 16),
                          BottomSheetDateField(
                            innerLabel: 'End Date',
                            date: _participationEndDate ??
                                widget.exhibition.endDate,
                            onTap: () =>
                                _selectParticipationDate(context, false),
                            dateFormat: DateFormat('d MMM yyyy'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Company information section.
                      const Text(
                        'Company Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      AppTextField(
                        controller: _companyController,
                        label: 'Company Name',
                        hint: 'Enter registered company name',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      AppTextField(
                        controller: _businessTypeController,
                        label: 'Business Type',
                        hint: 'e.g. Technology, Retail, Food',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      AppTextField(
                        controller: _productNameController,
                        label: 'Product / Service Name',
                        hint: 'What are you showcasing?',
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      AppTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Briefly describe your participation',
                        maxLines: 3,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Additional requirements section.
                      const Text(
                        'Additional Requirements',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Wrap(
                        spacing: 8,
                        children: _availableRequirements.map((req) {
                          final isSelected =
                              _selectedRequirements.contains(req);

                          return FilterChip(
                            label: Text(req),
                            selected: isSelected,
                            onSelected: (_) => _toggleRequirement(req),
                            selectedColor: AppColors.primaryAccent.withValues(
                              alpha: 0.2,
                            ),
                            checkmarkColor: AppColors.primaryAccent,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.m,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: SafeArea(
          child: widget.exhibition.isBookingOpen
              ? AppButton(
                  text: 'Submit Application',
                  isLoading: isLoading,
                  onPressed: _handleSubmit,
                )
              : GestureDetector(
                  onTap: () {
                    FeedbackHelper.showWarning(
                      context,
                      'Booking is currently closed for this exhibition.',
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Booking Closed',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    // Build selected booth and package summary card.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exhibition.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Booth Spot: ${widget.boothSpot.spotNumber}'),
              Text(
                'RM ${widget.boothPackage.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryAccent,
                ),
              ),
            ],
          ),
          Text(
            'Package: ${widget.boothPackage.name} (${widget.boothPackage.size})',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}