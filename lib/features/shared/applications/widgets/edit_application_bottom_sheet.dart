import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/bottom_sheet_date_field.dart';
import '../../../../data/models/application_model.dart';
import '../../../../data/models/booth_model.dart';
import '../../../../data/models/booth_spot_model.dart';
import '../../../../providers/application_provider.dart';
import '../../../../providers/booth_provider.dart';
import '../../../../providers/booth_spot_provider.dart';
import '../../../../providers/exhibition_provider.dart';
import '../../../../core/utils/feedback_helper.dart';

// Bottom sheet for editing application details.
class EditApplicationBottomSheet extends StatefulWidget {
  final ApplicationModel application;

  const EditApplicationBottomSheet({super.key, required this.application});

  @override
  State<EditApplicationBottomSheet> createState() =>
      _EditApplicationBottomSheetState();
}

class _EditApplicationBottomSheetState
    extends State<EditApplicationBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _productController;
  late TextEditingController _descriptionController;
  late List<String> _selectedRequirements;
  final _customRequirementController = TextEditingController();
  String? _formError;

  DateTime? _participationStartDate;
  DateTime? _participationEndDate;
  bool _datesInitialized = false;

  final List<String> _availableRequirements = [
    'WiFi',
    'Extra Table & Chair',
  ];

  @override
  void initState() {
    super.initState();

    // Fill form fields with current application data.
    _companyController =
        TextEditingController(text: widget.application.companyName);
    _productController =
        TextEditingController(text: widget.application.productName);
    _descriptionController =
        TextEditingController(text: widget.application.description);
    _selectedRequirements = List.from(widget.application.requirements);

    // Initialize participation dates from exhibition.
    final exhibitions = context.read<ExhibitionProvider>().allExhibitions;
    final exhibition = exhibitions
        .where((e) => e.id == widget.application.exhibitionId)
        .firstOrNull;

    if (exhibition != null) {
      _participationStartDate =
          widget.application.participationStartDate ?? exhibition.startDate;
      _participationEndDate =
          widget.application.participationEndDate ?? exhibition.endDate;
      _datesInitialized = true;
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _productController.dispose();
    _descriptionController.dispose();
    _customRequirementController.dispose();
    super.dispose();
  }

  void _addCustomRequirement() {
    final text = _customRequirementController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _formError = 'Please enter a requirement name.';
      });
      return;
    }

    setState(() {
      _formError = null;
    });

    // Avoid duplicate custom requirements.
    final isDuplicate = _selectedRequirements.any(
      (r) => r.toLowerCase() == text.toLowerCase(),
    );

    if (!isDuplicate) {
      setState(() {
        _selectedRequirements.add(text);
      });
    }

    _customRequirementController.clear();
  }

  Future<void> _selectParticipationDate(
    BuildContext context,
    bool isStart,
    DateTime exhibitionStart,
    DateTime exhibitionEnd,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_participationStartDate ?? exhibitionStart)
          : (_participationEndDate ?? exhibitionEnd),
      firstDate: exhibitionStart,
      lastDate: exhibitionEnd,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          // Apply app date picker styling.
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
          _participationStartDate = picked;

          // Keep end date after start date.
          if (_participationEndDate != null &&
              _participationStartDate!.isAfter(_participationEndDate!)) {
            _participationEndDate = _participationStartDate;
          }
        } else {
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

  bool _hasRealChanges() {
    final app = widget.application;
    final sameCompany = _companyController.text.trim() == app.companyName;
    final sameProduct = _productController.text.trim() == app.productName;
    final sameDescription =
        _descriptionController.text.trim() == app.description;

    final sameStartDate =
        _participationStartDate == app.participationStartDate;
    final sameEndDate = _participationEndDate == app.participationEndDate;

    // Check requirement list changes.
    final reqsChanged = _selectedRequirements.length != app.requirements.length ||
        !_selectedRequirements.every((r) => app.requirements.contains(r)) ||
        !app.requirements.every((r) => _selectedRequirements.contains(r));

    return !sameCompany ||
        !sameProduct ||
        !sameDescription ||
        reqsChanged ||
        !sameStartDate ||
        !sameEndDate;
  }

  void _handleSave() async {
    setState(() {
      _formError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final exhibitions = context.read<ExhibitionProvider>().allExhibitions;
    final exhibition = exhibitions
        .where((e) => e.id == widget.application.exhibitionId)
        .firstOrNull;

    // Validate participation dates.
    if (exhibition != null) {
      if (_participationStartDate == null || _participationEndDate == null) {
        setState(() {
          _formError = 'Please select participation dates.';
        });
        return;
      }

      if (_participationStartDate!.isAfter(_participationEndDate!)) {
        setState(() {
          _formError = 'Start date cannot be after end date.';
        });
        return;
      }

      if (_participationStartDate!.isBefore(exhibition.startDate) ||
          _participationEndDate!.isAfter(exhibition.endDate)) {
        setState(() {
          _formError =
              'Participation dates must be within the exhibition duration.';
        });
        return;
      }
    }

    final navigator = Navigator.of(context);
    final provider = context.read<ApplicationProvider>();

    final hasChanges = _hasRealChanges();

    // Prepare updated application data.
    final updatedApp = widget.application.copyWith(
      companyName: _companyController.text.trim(),
      productName: _productController.text.trim(),
      description: _descriptionController.text.trim(),
      requirements: _selectedRequirements,
      participationStartDate: _participationStartDate,
      participationEndDate: _participationEndDate,
    );

    final success = await provider.updateApplication(updatedApp);

    if (mounted) {
      if (success) {
        navigator.pop(hasChanges);

        if (context.mounted) {
          FeedbackHelper.showSuccess(
            context,
            'Application updated successfully',
          );
        }
      } else {
        setState(() {
          _formError = 'Update failed. Please try again.';
        });
      }
    }
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: AppColors.primaryText,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BoothSpotModel spot, BoothModel? package) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show selected booth summary.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booth Spot: ${spot.spotNumber}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                  color: AppColors.primaryText,
                ),
              ),
              if (package != null)
                Text(
                  'RM ${package.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: AppColors.primaryAccent,
                  ),
                ),
            ],
          ),
          if (package != null) ...[
            const SizedBox(height: 4),
            Text(
              'Package: ${package.name} (${package.size})',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boothProvider = context.watch<BoothProvider>();
    final spotProvider = context.watch<BoothSpotProvider>();

    final exhibitions = context.watch<ExhibitionProvider>().allExhibitions;
    final exhibition = exhibitions
        .where((e) => e.id == widget.application.exhibitionId)
        .firstOrNull;

    // Initialize dates when exhibition data becomes available.
    if (exhibition != null && !_datesInitialized) {
      _participationStartDate =
          widget.application.participationStartDate ?? exhibition.startDate;
      _participationEndDate =
          widget.application.participationEndDate ?? exhibition.endDate;
      _datesInitialized = true;
    }

    final spot = spotProvider.boothSpots.firstWhere(
      (s) => s.id == widget.application.boothSpotId,
      orElse: () => BoothSpotModel(
        id: widget.application.boothSpotId,
        exhibitionId: widget.application.exhibitionId,
        spotNumber: widget.application.boothNumber,
        boothPackageId: '',
        status: 'Booked',
      ),
    );

    final package = spot.boothPackageId.isNotEmpty
        ? boothProvider.boothPackages
            .where((p) => p.id == spot.boothPackageId)
            .firstOrNull
        : null;

    final List<Widget> requirementChips = [];

    // Build predefined requirement chips.
    for (var req in _availableRequirements) {
      final isSelected = _selectedRequirements.contains(req);

      requirementChips.add(
        FilterChip(
          label: Text(req),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              if (_selectedRequirements.contains(req)) {
                _selectedRequirements.remove(req);
              } else {
                _selectedRequirements.add(req);
              }
            });
          },
          selectedColor: AppColors.primaryAccent.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primaryAccent,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.primaryAccent : Colors.grey.shade200,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Build custom requirement chips.
    final customRequirements = _selectedRequirements
        .where((r) => !_availableRequirements.contains(r))
        .toList();

    for (var req in customRequirements) {
      requirementChips.add(
        FilterChip(
          label: Text(req),
          selected: true,
          onSelected: (_) {
            setState(() {
              _selectedRequirements.remove(req);
            });
          },
          selectedColor: AppColors.primaryAccent.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primaryAccent,
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: AppColors.primaryAccent,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    return AppBottomSheetScaffold(
      title: 'Edit Application',
      primaryLabel: 'Save Changes',
      isLoading: context.watch<ApplicationProvider>().isLoading,
      onPrimaryPressed: _handleSave,
      isScrollable: true,
      maxHeightFactor: 0.8,
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

            // Show booth and package summary.
            _buildSummaryCard(spot, package),

            // Show company information section.
            _buildSectionHeader('Company Information'),
            AppTextField(
              controller: _companyController,
              label: 'Company Name',
              hint: 'Enter registered company name',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _buildReadOnlyField(
              label: 'Business Type',
              value: widget.application.businessType,
            ),
            const SizedBox(height: 14),

            // Show participation date section.
            if (exhibition != null) ...[
              _buildSectionHeader('Participation Period'),
              Row(
                children: [
                  BottomSheetDateField(
                    innerLabel: 'Start Date',
                    date: _participationStartDate ?? exhibition.startDate,
                    onTap: () => _selectParticipationDate(
                      context,
                      true,
                      exhibition.startDate,
                      exhibition.endDate,
                    ),
                    dateFormat: DateFormat('d MMM yyyy'),
                  ),
                  const SizedBox(width: 16),
                  BottomSheetDateField(
                    innerLabel: 'End Date',
                    date: _participationEndDate ?? exhibition.endDate,
                    onTap: () => _selectParticipationDate(
                      context,
                      false,
                      exhibition.startDate,
                      exhibition.endDate,
                    ),
                    dateFormat: DateFormat('d MMM yyyy'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Participation Period: ${_participationStartDate != null && _participationEndDate != null ? "${DateFormat('d MMM yyyy').format(_participationStartDate!)} - ${DateFormat('d MMM yyyy').format(_participationEndDate!)}" : "Full Event Duration"}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Show booth details section.
            _buildSectionHeader('Booth Details'),
            AppTextField(
              controller: _productController,
              label: 'Product / Service Name',
              hint: 'What are you showcasing?',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _descriptionController,
              label: 'Product / Booth Description',
              hint: 'Briefly describe your display goals',
              maxLines: 3,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),

            // Show included amenities.
            if (package != null && package.amenities.isNotEmpty) ...[
              _buildSectionHeader('Included Amenities'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: package.amenities.map((a) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check,
                          size: 13,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          a,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // Show additional requirement chips.
            _buildSectionHeader('Additional Requirements'),
            if (requirementChips.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: requirementChips,
              ),
              const SizedBox(height: 12),
            ],

            // Add custom requirement input.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customRequirementController,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add custom requirement...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryAccent,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _addCustomRequirement(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addCustomRequirement,
                  icon: const Icon(
                    Icons.add_circle,
                    color: AppColors.primaryAccent,
                    size: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}