import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/app_text_field.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _selectedRequirements = [];
  final List<String> _availableRequirements = [
    'Electricity',
    'WiFi',
    'Extra Table & Chair',
  ];

  void _toggleRequirement(String req) {
    setState(() {
      if (_selectedRequirements.contains(req)) {
        _selectedRequirements.remove(req);
      } else {
        _selectedRequirements.add(req);
      }
    });
  }

  void _handleSubmit() async {
    // 1. Fast local check
    if (!widget.exhibition.isBookingOpen) {
      FeedbackHelper.showError(
        context,
        'Booking is closed. You cannot submit an application for this exhibition.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      FeedbackHelper.showWarning(context, 'Please login to submit application.');
      context.go(AppRoutes.login);
      return;
    }

    // 2. Real-time Firestore check
    try {
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
      debugPrint('Error verifying booking status: $e');
    }

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
    );

    if (!mounted) return;
    final appProvider = context.read<ApplicationProvider>();
    final success = await appProvider.submitApplication(application);

    if (mounted) {
      if (success) {
        FeedbackHelper.showSuccess(context, 'Application submitted successfully!');
        // Navigate back to root/home
        context.go(AppRoutes.root);
      } else {
        FeedbackHelper.showError(context, appProvider.errorMessage ?? 'Submission failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      // Booth Summary Card
                      _buildSummaryCard(),
                      const SizedBox(height: AppSpacing.xl),

                      const Text(
                        'Company Information',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      AppTextField(
                        controller: _companyController,
                        label: 'Company Name',
                        hint: 'Enter registered company name',
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      AppTextField(
                        controller: _businessTypeController,
                        label: 'Business Type',
                        hint: 'e.g. Technology, Retail, Food',
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      AppTextField(
                        controller: _productNameController,
                        label: 'Product / Service Name',
                        hint: 'What are you showcasing?',
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      AppTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Briefly describe your participation',
                        maxLines: 3,
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      const Text(
                        'Additional Requirements',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Wrap(
                        spacing: 8,
                        children: _availableRequirements.map((req) {
                          final isSelected = _selectedRequirements.contains(req);
                          return FilterChip(
                            label: Text(req),
                            selected: isSelected,
                            onSelected: (_) => _toggleRequirement(req),
                            selectedColor: AppColors.primaryAccent.withValues(alpha: 0.2),
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
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Booth Spot: ${widget.boothSpot.spotNumber}'),
              Text(
                'RM ${widget.boothPackage.price.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryAccent),
              ),
            ],
          ),
          Text(
            'Package: ${widget.boothPackage.name} (${widget.boothPackage.size})',
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
