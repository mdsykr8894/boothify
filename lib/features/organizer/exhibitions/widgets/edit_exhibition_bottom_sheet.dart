import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_bottom_sheet_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/bottom_sheet_dropdown_field.dart';
import '../../../../core/widgets/bottom_sheet_date_field.dart';
import '../../../../data/models/exhibition_model.dart';
import '../../../../providers/exhibition_provider.dart';
import '../../../../core/utils/feedback_helper.dart';

class EditExhibitionBottomSheet extends StatefulWidget {
  final ExhibitionModel exhibition;

  const EditExhibitionBottomSheet({super.key, required this.exhibition});

  @override
  State<EditExhibitionBottomSheet> createState() => _EditExhibitionBottomSheetState();
}

class _EditExhibitionBottomSheetState extends State<EditExhibitionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late DateTime _endDate;
  String? _formError;

  static const List<String> _categories = [
    'Technology',
    'Food',
    'Education',
    'Fashion',
    'Business',
    'Health',
    'Art',
    'Other',
  ];

  static const List<String> _eventTypes = [
    'Indoor',
    'Outdoor',
    'Hybrid',
  ];

  late String _selectedCategory;
  String? _selectedEventType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exhibition.name);
    _locationController = TextEditingController(text: widget.exhibition.location);
    _descriptionController = TextEditingController(text: widget.exhibition.description);
    _startDate = widget.exhibition.startDate;
    _endDate = widget.exhibition.endDate;

    _selectedCategory = widget.exhibition.category.isNotEmpty ? widget.exhibition.category : 'General';
    _selectedEventType = widget.exhibition.eventType.isNotEmpty ? widget.exhibition.eventType : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
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
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _handleSave() async {
    setState(() {
      _formError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    if (_endDate.isBefore(_startDate)) {
      setState(() {
        _formError = 'End date cannot be before start date';
      });
      return;
    }

    final updatedExhibition = widget.exhibition.copyWith(
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      category: _selectedCategory,
      eventType: _selectedEventType ?? '',
    );

    final provider = context.read<ExhibitionProvider>();
    final success = await provider.updateExhibition(updatedExhibition);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        if (context.mounted) {
          FeedbackHelper.showSuccess(
            context,
            'Exhibition updated successfully',
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
    final dateFormat = DateFormat('d MMM yyyy');

    return AppBottomSheetScaffold(
      title: 'Edit Exhibition',
      primaryLabel: 'Save Changes',
      isLoading: context.watch<ExhibitionProvider>().isLoading,
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
            AppTextField(
              controller: _nameController,
              label: 'Exhibition Name',
              hint: 'e.g. Food & Beverage Expo 2024',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.m),
            BottomSheetDropdownField<String>(
              label: 'Category',
              hint: 'Select category',
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.m),
            BottomSheetDropdownField<String>(
              label: 'Event Type (Optional)',
              hint: 'Select event type',
              value: _selectedEventType,
              items: _eventTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedEventType = val),
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'e.g. KLCC Convention Centre',
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.m),
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Briefly describe the event',
              maxLines: 3,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                BottomSheetDateField(
                  innerLabel: 'Start',
                  date: _startDate,
                  onTap: () => _selectDate(context, true),
                  dateFormat: dateFormat,
                ),
                const SizedBox(width: 16),
                BottomSheetDateField(
                  innerLabel: 'End',
                  date: _endDate,
                  onTap: () => _selectDate(context, false),
                  dateFormat: dateFormat,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
