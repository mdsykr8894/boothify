import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_sheet_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/bottom_sheet_dropdown_field.dart';
import '../../../../providers/booth_package_provider.dart';
import '../../../../providers/booth_spot_provider.dart';
import '../../../../providers/exhibition_provider.dart';
import '../../../../core/utils/feedback_helper.dart';

class CreateFloorLayoutBottomSheet extends StatefulWidget {
  final String exhibitionId;

  const CreateFloorLayoutBottomSheet({
    super.key,
    required this.exhibitionId,
  });

  @override
  State<CreateFloorLayoutBottomSheet> createState() => _CreateFloorLayoutBottomSheetState();
}

class _CreateFloorLayoutBottomSheetState extends State<CreateFloorLayoutBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _rowsController = TextEditingController();
  final _columnsController = TextEditingController();
  String? _selectedPackageId;
  bool _isAutoGenerate = true;
  String? _formError;

  @override
  void initState() {
    super.initState();
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

  void _handleGenerate() async {
    setState(() {
      _formError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final rowsText = _rowsController.text.trim();
    final colsText = _columnsController.text.trim();

    final rows = int.tryParse(rowsText);
    final cols = int.tryParse(colsText);

    if (rows == null || cols == null || rows <= 0 || cols <= 0) {
      setState(() {
        _formError = 'Please enter valid rows and columns.';
      });
      return;
    }

    if (rows > 10 || cols > 10) {
      setState(() {
        _formError = 'Layout size cannot exceed 10 rows or 10 columns.';
      });
      return;
    }

    final totalSpots = rows * cols;
    if (totalSpots > 100) {
      setState(() {
        _formError = 'Layout cannot exceed 100 booth spots.';
      });
      return;
    }

    if (_isAutoGenerate && _selectedPackageId == null) {
      setState(() {
        _formError = 'Please select a default booth package.';
      });
      return;
    }

    final provider = context.read<BoothSpotProvider>();
    if (provider.boothSpots.isNotEmpty) {
      setState(() {
        _formError = 'Floor layout already exists. Add spots manually instead.';
      });
      return;
    }

    final success = await provider.generateBoothLayout(
      exhibitionId: widget.exhibitionId,
      defaultPackageId: _isAutoGenerate ? _selectedPackageId! : '',
      rows: rows,
      columns: cols,
    );

    if (mounted) {
      if (success) {
        try {
          final exhibition = context.read<ExhibitionProvider>().organizerExhibitions.firstWhere((e) => e.id == widget.exhibitionId);
          context.read<ExhibitionProvider>().fetchOrganizerExhibitions(exhibition.organizerId);
        } catch (e) {
          debugPrint('Could not refresh exhibition: $e');
        }
        Navigator.pop(context);
        if (context.mounted) {
          FeedbackHelper.showSuccess(
            context, 
            _isAutoGenerate ? 'Floor layout generated successfully' : 'Empty floor layout created successfully',
          );
        }
      } else {
        setState(() {
          _formError = provider.errorMessage ?? 'Failed to generate floor layout';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boothProvider = context.watch<BoothPackageProvider>();
    final packages = boothProvider.boothPackages;

    // Calculate layout preview dynamically
    final rowsVal = int.tryParse(_rowsController.text.trim());
    final colsVal = int.tryParse(_columnsController.text.trim());
    final isValid = rowsVal != null && colsVal != null && rowsVal > 0 && colsVal > 0;
    final totalSpots = isValid ? (rowsVal * colsVal) : 0;

    return AppBottomSheetScaffold(
      title: 'Create Floor Layout',
      primaryLabel: _isAutoGenerate ? 'Generate Booth Spots' : 'Create Empty Layout',
      onPrimaryPressed: _handleGenerate,
      isPrimaryEnabled: !_isAutoGenerate || _selectedPackageId != null,
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
            Text(
              'Choose layout mode',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: AppSpacing.s + 2),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isAutoGenerate = false),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: !_isAutoGenerate 
                            ? AppColors.primaryAccent.withValues(alpha: 0.05) 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: !_isAutoGenerate 
                              ? AppColors.primaryAccent 
                              : Colors.grey.shade200,
                          width: !_isAutoGenerate ? 2.0 : 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.grid_off_rounded,
                            size: 18,
                            color: !_isAutoGenerate 
                                ? AppColors.primaryAccent 
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Empty Layout',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !_isAutoGenerate 
                                    ? AppColors.primaryAccent 
                                    : Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isAutoGenerate = true),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: _isAutoGenerate 
                            ? AppColors.primaryAccent.withValues(alpha: 0.05) 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isAutoGenerate 
                              ? AppColors.primaryAccent 
                              : Colors.grey.shade200,
                          width: _isAutoGenerate ? 2.0 : 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 18,
                            color: _isAutoGenerate 
                                ? AppColors.primaryAccent 
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Generate Spots',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _isAutoGenerate 
                                    ? AppColors.primaryAccent 
                                    : Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
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
                      if (val == null || val <= 0) return 'Invalid';
                      if (val > 10) return 'Max 10';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: AppTextField(
                    controller: _columnsController,
                    label: 'Columns (Max 10)',
                    hint: 'e.g. 5',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final val = int.tryParse(v);
                      if (val == null || val <= 0) return 'Invalid';
                      if (val > 10) return 'Max 10';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (_isAutoGenerate) ...[
              const SizedBox(height: AppSpacing.m),
              if (packages.isEmpty)
                const Text(
                  'Create a booth package first.',
                  style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500),
                )
              else
                BottomSheetDropdownField<String>(
                  label: 'Default Booth Package',
                  hint: 'Select default package',
                  value: _selectedPackageId,
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
            if (isValid && totalSpots > 0) ...[
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
                        _isAutoGenerate
                            ? 'This will create $totalSpots booth spots.'
                            : 'This will create an empty $rowsVal × $colsVal floor layout.',
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
            ],
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );
  }
}
