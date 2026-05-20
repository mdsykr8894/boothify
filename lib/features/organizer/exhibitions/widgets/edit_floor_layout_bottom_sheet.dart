import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../data/models/exhibition_model.dart';
import '../../../../providers/booth_spot_provider.dart';
import '../../../../core/utils/feedback_helper.dart';

class EditFloorLayoutBottomSheet extends StatefulWidget {
  final ExhibitionModel exhibition;
  final int currentRows;
  final int currentColumns;

  const EditFloorLayoutBottomSheet({
    super.key,
    required this.exhibition,
    required this.currentRows,
    required this.currentColumns,
  });

  @override
  State<EditFloorLayoutBottomSheet> createState() => _EditFloorLayoutBottomSheetState();
}

class _EditFloorLayoutBottomSheetState extends State<EditFloorLayoutBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _rowsController = TextEditingController();
  final _columnsController = TextEditingController();
  String? _formError;

  @override
  void initState() {
    super.initState();
    _rowsController.text = widget.currentRows.toString();
    _columnsController.text = widget.currentColumns.toString();
    _rowsController.addListener(_updatePreview);
    _columnsController.addListener(_updatePreview);
  }

  @override
  void dispose() {
    _rowsController.removeListener(_updatePreview);
    _columnsController.removeListener(_updatePreview);
    _rowsController.dispose();
    _columnsController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    setState(() {});
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

    final rowsText = _rowsController.text.trim();
    final colsText = _columnsController.text.trim();

    final newRows = int.tryParse(rowsText);
    final newCols = int.tryParse(colsText);

    if (newRows == null || newCols == null || newRows <= 0 || newCols <= 0) {
      setState(() {
        _formError = 'Please enter valid rows and columns.';
      });
      return;
    }

    if (newRows > 10 || newCols > 10) {
      setState(() {
        _formError = 'Layout size cannot exceed 10 rows or 10 columns.';
      });
      return;
    }

    final totalSpots = newRows * newCols;
    if (totalSpots > 100) {
      setState(() {
        _formError = 'Layout cannot exceed 100 booth spots.';
      });
      return;
    }

    // Safety checks for reducing layout:
    // Any existing spot must not be outside the new boundaries.
    final provider = context.read<BoothSpotProvider>();
    final spots = provider.boothSpots;
    
    final bool hasSpotsOutside = spots.any((spot) {
      final r = getRowIndex(spot.spotNumber);
      final c = getColIndex(spot.spotNumber);
      return r >= newRows || c >= newCols;
    });

    if (hasSpotsOutside) {
      setState(() {
        _formError = 'Cannot reduce layout because some booth spots are outside the new size. Delete or move those spots first.';
      });
      return;
    }

    final success = await provider.updateLayoutDimensions(
      widget.exhibition.id,
      newRows,
      newCols,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        if (context.mounted) {
          FeedbackHelper.showSuccess(
            context,
            'Floor layout updated successfully',
          );
        }
      } else {
        setState(() {
          _formError = provider.errorMessage ?? 'Failed to update layout dimensions';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rowsText = _rowsController.text.trim();
    final colsText = _columnsController.text.trim();

    final rowsVal = int.tryParse(rowsText) ?? widget.currentRows;
    final colsVal = int.tryParse(colsText) ?? widget.currentColumns;

    final isChanged = rowsVal != widget.currentRows || colsVal != widget.currentColumns;

    return AppBottomSheetScaffold(
      title: 'Edit Floor Layout',
      primaryLabel: 'Save Layout',
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
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _rowsController,
                    label: 'Rows (Max 10)',
                    hint: 'e.g. 3',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = int.tryParse(v);
                      if (val == null || val <= 0 || val > 10) return '1-10';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: AppTextField(
                    controller: _columnsController,
                    label: 'Columns (Max 10)',
                    hint: 'e.g. 3',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = int.tryParse(v);
                      if (val == null || val <= 0 || val > 10) return '1-10';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.2), width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.grid_on_rounded,
                    color: AppColors.primaryAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isChanged
                          ? 'This will resize the layout to $rowsVal × $colsVal.'
                          : 'Current layout: ${widget.currentRows} × ${widget.currentColumns}',
                      style: const TextStyle(
                        color: AppColors.primaryAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }
}
