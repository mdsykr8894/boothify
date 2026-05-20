import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet_scaffold.dart';
import '../../../../data/models/booth_model.dart';
import '../../../../providers/booth_provider.dart';

class BoothPackageBottomSheet extends StatefulWidget {
  final String exhibitionId;
  final BoothModel? package;

  const BoothPackageBottomSheet({
    super.key,
    required this.exhibitionId,
    this.package,
  });

  @override
  State<BoothPackageBottomSheet> createState() => _BoothPackageBottomSheetState();
}

class _BoothPackageBottomSheetState extends State<BoothPackageBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _priceController = TextEditingController();
  final _customAmenityController = TextEditingController();
  String? _formError;

  // Exactly 4 default premium amenities preset
  final List<String> _presets = ['Table', 'Chair', 'Electricity', 'Socket'];
  late List<String> _displayAmenities;
  final List<String> _selectedAmenities = [];

  @override
  void initState() {
    super.initState();
    _selectedAmenities.addAll(widget.package?.amenities ?? []);
    _displayAmenities = List.from(_presets);
    
    // Add any existing custom amenities from edit mode to the visible list, keeping case-insensitivity
    for (var amenity in _selectedAmenities) {
      final matchesPreset = _displayAmenities.any((p) => p.toLowerCase() == amenity.trim().toLowerCase());
      if (!matchesPreset) {
        _displayAmenities.add(amenity);
      }
    }

    if (widget.package != null) {
      _nameController.text = widget.package!.name;
      _priceController.text = widget.package!.price.toStringAsFixed(0);
      
      // Parse size safely (formats: "3m x 3m", "3 x 3", "3M X 3M", "3 m x 3 m")
      final sizeStr = widget.package!.size.trim();
      final regex = RegExp(r'^(\d+)\s*m?\s*[xX]\s*(\d+)\s*m?$');
      final match = regex.firstMatch(sizeStr);
      if (match != null) {
        _widthController.text = match.group(1) ?? '3';
        _heightController.text = match.group(2) ?? '3';
      } else {
        // Safe fallback
        _widthController.text = '3';
        _heightController.text = '3';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _priceController.dispose();
    _customAmenityController.dispose();
    super.dispose();
  }

  void _addCustomAmenity() {
    final text = _customAmenityController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _formError = 'Please enter an amenity name.';
      });
      return;
    }
    
    setState(() {
      _formError = null;
    });

    // Case-insensitive duplicate check
    final isDuplicate = _displayAmenities.any((a) => a.toLowerCase() == text.toLowerCase());
    if (!isDuplicate) {
      setState(() {
        _displayAmenities.add(text);
        _selectedAmenities.add(text);
      });
    } else {
      // Make sure the existing matching item is selected
      final existingName = _displayAmenities.firstWhere((a) => a.toLowerCase() == text.toLowerCase());
      if (!_selectedAmenities.contains(existingName)) {
        setState(() {
          _selectedAmenities.add(existingName);
        });
      }
    }
    _customAmenityController.clear();
  }

  void _handleSave() async {
    setState(() {
      _formError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final widthText = _widthController.text.trim();
    final heightText = _heightController.text.trim();
    final priceText = _priceController.text.trim();

    // 1. Package Name Validation
    if (name.isEmpty || name.length < 3) {
      setState(() {
        _formError = 'Please enter a valid package name.';
      });
      return;
    }

    // 2. Duplicate Check
    final provider = context.read<BoothProvider>();
    final isDuplicate = provider.boothPackages.any((p) {
      final matchesName = p.name.trim().toLowerCase() == name.toLowerCase();
      if (widget.package == null) {
        return matchesName;
      } else {
        return matchesName && p.id != widget.package!.id;
      }
    });

    if (isDuplicate) {
      setState(() {
        _formError = 'A package with this name already exists.';
      });
      return;
    }

    // 3. Size Validation
    final width = double.tryParse(widthText);
    final height = double.tryParse(heightText);
    if (width == null || height == null || width <= 0 || height <= 0) {
      setState(() {
        _formError = 'Please enter a valid booth size.';
      });
      return;
    }

    // 4. Price Validation
    final price = double.tryParse(priceText);
    if (price == null || price < 0) {
      setState(() {
        _formError = 'Please enter a valid package price.';
      });
      return;
    }

    // Standard single-string size output back to model
    final size = '${widthText}m x ${heightText}m';

    bool success;

    if (widget.package == null) {
      // Create mode
      final newPackage = BoothModel(
        id: '',
        exhibitionId: widget.exhibitionId,
        name: name,
        size: size,
        price: price,
        amenities: _selectedAmenities,
        createdAt: DateTime.now(),
      );
      success = await provider.createBoothPackage(newPackage);
    } else {
      // Edit mode
      final updatedPackage = widget.package!.copyWith(
        name: name,
        size: size,
        price: price,
        amenities: _selectedAmenities,
      );
      success = await provider.updateBoothPackage(updatedPackage);
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context, true); // Return true indicating successful operation
      } else {
        setState(() {
          _formError = provider.errorMessage ?? 'Operation failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<BoothProvider>().isLoading;

    return AppBottomSheetScaffold(
      title: widget.package == null ? 'New Booth Package' : 'Edit Booth Package',
      primaryLabel: widget.package == null ? 'Save Package' : 'Save Changes',
      showCloseButton: false, // Disabled top-right close icon X
      showCancelButton: false, // Disabled Cancel button completely
      showDivider: false, // Disabled visual divider line below title
      primaryColor: AppColors.primaryText, // Premium dark black CTA style
      primaryHeight: 62.0, // Enlarged primary action height 62 for high-end feel
      primaryBorderRadius: 16.0, // Dominant border radius 16
      isLoading: isLoading,
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
            const Text(
              'Package Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'e.g. Premium Corner'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Size Column
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Size (m)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _widthController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(hintText: '3'),
                              validator: (v) => v == null || v.isEmpty ? 'Req' : null,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'x',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(hintText: '3'),
                              validator: (v) => v == null || v.isEmpty ? 'Req' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Price Column
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price (RM)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: '500'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            const Text(
              'Included Amenities',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _displayAmenities.map((amenity) {
                final isSelected = _selectedAmenities.contains(amenity);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedAmenities.remove(amenity);
                      } else {
                        _selectedAmenities.add(amenity);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryAccent.withValues(alpha: 0.06) // Premium pink selection tint
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryAccent.withValues(alpha: 0.45) // Premium pink border selection
                            : Colors.grey.shade200,
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected) ...[
                          const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.primaryAccent,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          amenity,
                          style: TextStyle(
                            color: isSelected ? AppColors.primaryAccent : AppColors.primaryText,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customAmenityController,
                    decoration: InputDecoration(
                      hintText: 'Add custom amenity...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryAccent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addCustomAmenity,
                  icon: const Icon(Icons.add_circle, color: AppColors.primaryAccent, size: 28),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
