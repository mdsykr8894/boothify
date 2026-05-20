import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/bottom_sheet_dropdown_field.dart';
import '../../../../data/models/booth_spot_model.dart';
import '../../../../providers/booth_provider.dart';
import '../../../../providers/booth_spot_provider.dart';

class BoothSpotBottomSheet extends StatefulWidget {
  final String exhibitionId;
  final BoothSpotModel? spot;
  final int rows;
  final int columns;
  final String? presetSpotNumber;

  const BoothSpotBottomSheet({
    super.key,
    required this.exhibitionId,
    this.spot,
    required this.rows,
    required this.columns,
    this.presetSpotNumber,
  });

  @override
  State<BoothSpotBottomSheet> createState() => _BoothSpotBottomSheetState();
}

class _BoothSpotBottomSheetState extends State<BoothSpotBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  String? _selectedPackageId;
  String? _formError;

  @override
  void initState() {
    super.initState();
    if (widget.spot != null) {
      _numberController.text = widget.spot!.spotNumber;
      _selectedPackageId = widget.spot!.boothPackageId;
    } else if (widget.presetSpotNumber != null) {
      _numberController.text = widget.presetSpotNumber!;
    }
  }

  int getRowIndex(String spotNumber) {
    if (spotNumber.isEmpty) return 0;
    final firstChar = spotNumber[0].toUpperCase();
    if (firstChar.codeUnitAt(0) >= 'A'.codeUnitAt(0) && firstChar.codeUnitAt(0) <= 'Z'.codeUnitAt(0)) {
      return firstChar.codeUnitAt(0) - 'A'.codeUnitAt(0);
    }
    return 0;
  }

  int getColIndex(String spotNumber) {
    if (spotNumber.length < 2) return 0;
    final digits = spotNumber.substring(1);
    final val = int.tryParse(digits);
    if (val != null) {
      return val - 1; // 0-indexed
    }
    return 0;
  }

  void _handleSave() async {
    setState(() {
      _formError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final spotNumber = _numberController.text.trim().toUpperCase();
    _numberController.text = spotNumber; // Automatically set field text to uppercase for user convenience

    // A. Spot number format check (e.g. A01, B12, Z99)
    final formatRegex = RegExp(r'^[A-Z]\d{2}$');
    if (!formatRegex.hasMatch(spotNumber)) {
      setState(() {
        _formError = 'Use a valid spot number such as A01.';
      });
      return;
    }

    // B. Layout bounds check
    final r = getRowIndex(spotNumber);
    final c = getColIndex(spotNumber);
    if (r >= widget.rows || c >= widget.columns) {
      setState(() {
        _formError = 'Spot number must be within the current layout bounds.';
      });
      return;
    }

    final provider = context.read<BoothSpotProvider>();

    // C. Duplicate check
    final isDuplicate = provider.boothSpots.any((s) {
      final matchesNumber = s.spotNumber.trim().toUpperCase() == spotNumber;
      if (widget.spot == null) {
        return matchesNumber;
      } else {
        return matchesNumber && s.id != widget.spot!.id;
      }
    });

    if (isDuplicate) {
      setState(() {
        _formError = 'This spot number already exists.';
      });
      return;
    }

    // D. Package missing check
    if (_selectedPackageId == null) {
      setState(() {
        _formError = 'Please select a booth package.';
      });
      return;
    }

    bool success;

    if (widget.spot == null) {
      // Create mode
      final newSpot = BoothSpotModel(
        id: '',
        exhibitionId: widget.exhibitionId,
        boothPackageId: _selectedPackageId!,
        spotNumber: spotNumber,
        status: 'Available',
        createdAt: DateTime.now(),
      );
      success = await provider.createBoothSpot(newSpot);
    } else {
      // Edit mode
      final updatedSpot = widget.spot!.copyWith(
        spotNumber: spotNumber,
        boothPackageId: _selectedPackageId!,
      );
      success = await provider.updateBoothSpot(updatedSpot);
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context, true); // Return true to indicate successful save
      } else {
        setState(() {
          _formError = provider.errorMessage ?? 'Operation failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boothProvider = context.watch<BoothProvider>();
    final spotProvider = context.watch<BoothSpotProvider>();
    final packages = boothProvider.boothPackages;
    final isLoading = spotProvider.isLoading || boothProvider.isLoading;

    return AppBottomSheetScaffold(
      title: widget.spot == null ? 'Add Booth Spot' : 'Edit Booth Spot',
      primaryLabel: widget.spot == null ? 'Create Spot' : 'Update Spot',
      isLoading: isLoading,
      isPrimaryEnabled: packages.isNotEmpty,
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
              controller: _numberController,
              label: 'Spot Number',
              hint: 'e.g. A01',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.m),
            if (packages.isEmpty)
              const Text(
                'Create a booth package first.',
                style: TextStyle(color: Colors.red, fontSize: 14),
              )
            else
              BottomSheetDropdownField<String>(
                label: 'Booth Package',
                hint: 'Select package',
                value: packages.any((p) => p.id == _selectedPackageId) ? _selectedPackageId : null,
                items: packages.map((p) {
                  return DropdownMenuItem(
                    value: p.id,
                    child: Text('${p.name} (${p.size})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPackageId = val),
                validator: (v) => v == null ? 'Required' : null,
              ),
          ],
        ),
      ),
    );
  }
}
