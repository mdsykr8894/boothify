import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/application_model.dart';
import '../../../../data/models/booth_model.dart';
import '../../../../data/models/booth_spot_model.dart';
import '../../../../providers/application_provider.dart';
import '../../../../providers/booth_provider.dart';
import '../../../../providers/booth_spot_provider.dart';
import '../../../../core/utils/feedback_helper.dart';

class EditApplicationBottomSheet extends StatefulWidget {
  final ApplicationModel application;

  const EditApplicationBottomSheet({super.key, required this.application});

  @override
  State<EditApplicationBottomSheet> createState() => _EditApplicationBottomSheetState();
}

class _EditApplicationBottomSheetState extends State<EditApplicationBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyController;
  late TextEditingController _businessTypeController;
  late TextEditingController _productController;
  late TextEditingController _descriptionController;
  late List<String> _selectedRequirements;
  final _customRequirementController = TextEditingController();
  String? _selectedBusinessType;
  String? _formError;

  static const List<String> _businessTypeOptions = [
    'Technology',
    'Retail',
    'Food & Beverage',
    'Fashion',
    'Education',
    'Health & Wellness',
    'Art & Creative',
    'Services',
    'Other',
  ];

  final List<String> _availableRequirements = [
    'WiFi',
    'Extra Table & Chair',
  ];

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.application.companyName);
    _businessTypeController = TextEditingController(text: widget.application.businessType);
    _productController = TextEditingController(text: widget.application.productName);
    _descriptionController = TextEditingController(text: widget.application.description);
    _selectedRequirements = List.from(widget.application.requirements);

    final businessType = widget.application.businessType;
    if (_businessTypeOptions.contains(businessType)) {
      _selectedBusinessType = businessType;
    } else if (businessType.isNotEmpty) {
      _selectedBusinessType = 'Other';
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _businessTypeController.dispose();
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

    final isDuplicate = _selectedRequirements.any((r) => r.toLowerCase() == text.toLowerCase());
    if (!isDuplicate) {
      setState(() {
        _selectedRequirements.add(text);
      });
    }
    _customRequirementController.clear();
  }

  bool _hasRealChanges() {
    final app = widget.application;
    final sameCompany = _companyController.text.trim() == app.companyName;
    final sameBusinessType = _businessTypeController.text.trim() == app.businessType;
    final sameProduct = _productController.text.trim() == app.productName;
    final sameDescription = _descriptionController.text.trim() == app.description;

    // Requirements comparison
    final reqsChanged = _selectedRequirements.length != app.requirements.length ||
        !_selectedRequirements.every((r) => app.requirements.contains(r)) ||
        !app.requirements.every((r) => _selectedRequirements.contains(r));

    return !sameCompany || !sameBusinessType || !sameProduct || !sameDescription || reqsChanged;
  }

  void _handleSave() async {
    setState(() {
      _formError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    final provider = context.read<ApplicationProvider>();

    final hasChanges = _hasRealChanges();

    final updatedApp = widget.application.copyWith(
      companyName: _companyController.text.trim(),
      businessType: _businessTypeController.text.trim(),
      productName: _productController.text.trim(),
      description: _descriptionController.text.trim(),
      requirements: _selectedRequirements,
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

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
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
        DropdownButtonFormField<String>(
          initialValue: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade400),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            fillColor: Colors.white,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final boothProvider = context.watch<BoothProvider>();
    final spotProvider = context.watch<BoothSpotProvider>();

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
        ? boothProvider.boothPackages.where((p) => p.id == spot.boothPackageId).firstOrNull
        : null;

    // Gather requirement chips
    final List<Widget> requirementChips = [];

    // Pre-defined chips
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

    // Custom requirement chips (items in _selectedRequirements but not in _availableRequirements)
    final customRequirements = _selectedRequirements.where((r) => !_availableRequirements.contains(r)).toList();
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
            // Read-only Booth Spot & Package Summary
            _buildSummaryCard(spot, package),

            // Section 1: Company Information
            _buildSectionHeader('Company Information'),
            AppTextField(
              controller: _companyController,
              label: 'Company Name',
              hint: 'Enter registered company name',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            _buildDropdownField(
              label: 'Business Type',
              hint: 'Select business type',
              value: _selectedBusinessType,
              items: _businessTypeOptions,
              onChanged: (val) {
                setState(() {
                  _selectedBusinessType = val;
                  if (val != 'Other') {
                    _businessTypeController.text = val ?? '';
                  } else {
                    _businessTypeController.clear();
                  }
                });
              },
              validator: (v) => v == null ? 'Required' : null,
            ),
            if (_selectedBusinessType == 'Other') ...[
              const SizedBox(height: 14),
              AppTextField(
                controller: _businessTypeController,
                label: 'Specify Business Type',
                hint: 'Enter your business type',
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
            ],

            // Section 2: Booth Details
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

            // Section 3: Included Amenities (Read-only)
            if (package != null && package.amenities.isNotEmpty) ...[
              _buildSectionHeader('Included Amenities'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: package.amenities.map((a) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 13, color: Colors.green.shade600),
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

            // Section 4: Additional Requirements (Selectable chips + text input)
            _buildSectionHeader('Additional Requirements'),
            if (requirementChips.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: requirementChips,
              ),
              const SizedBox(height: 12),
            ],
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      fillColor: Colors.white,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryAccent, width: 1.5),
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
