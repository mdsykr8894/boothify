import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_page_header.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../../data/models/exhibition_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/exhibition_provider.dart';
import '../../../core/utils/feedback_helper.dart';

// Form screen for creating a new exhibition.
class CreateExhibitionScreen extends StatefulWidget {
  const CreateExhibitionScreen({super.key});

  @override
  State<CreateExhibitionScreen> createState() => _CreateExhibitionScreenState();
}

class _CreateExhibitionScreenState extends State<CreateExhibitionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 4) {
      FeedbackHelper.showWarning(
        context,
        'You can upload up to 4 images only.',
      );
      return;
    }

    try {
      // Pick multiple exhibition images.
      final List<XFile> pickedFiles = await _picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            if (_selectedImages.length < 4) {
              _selectedImages.add(file);
            } else {
              FeedbackHelper.showWarning(
                context,
                'You can upload up to 4 images only.',
              );
              break;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  void _removeImage(int index) {
    // Remove selected image preview.
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  DateTime? _startDate;
  DateTime? _endDate;

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

  static const List<String> _eventTypes = ['Indoor', 'Outdoor', 'Hybrid'];

  String? _selectedCategory;
  String? _selectedEventType;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final DateTime initialDate;
    final DateTime firstDate;

    // Prepare start or end date picker range.
    if (isStart) {
      initialDate = _startDate ?? today;
      firstDate = today;
    } else {
      final minimumEndDate = _startDate ?? today;
      initialDate = _endDate ?? minimumEndDate;
      firstDate = minimumEndDate;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: today.add(const Duration(days: 365 * 2)),
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
          _startDate = picked;

          // Reset end date when it becomes invalid.
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    // Require both event dates.
    if (_startDate == null || _endDate == null) {
      FeedbackHelper.showWarning(
        context,
        'Please select both start and end dates',
      );
      return;
    }

    // Validate event date order.
    if (_endDate!.isBefore(_startDate!)) {
      FeedbackHelper.showWarning(
        context,
        'End date cannot be before start date',
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final exhibitionProvider = context.read<ExhibitionProvider>();
    final organizerId = authProvider.currentUser?.uid;

    if (organizerId == null) return;

    // Build new exhibition model.
    final newExhibition = ExhibitionModel(
      id: '',
      organizerId: organizerId,
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      description: _descriptionController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      isPublished: false,
      createdAt: DateTime.now(),
      category: _selectedCategory ?? 'General',
      eventType: _selectedEventType ?? '',
      contactEmail: '',
      contactPhone: '',
      openingHours: '',
      expectedVisitors: '',
    );

    // Create exhibition through provider.
    final success = await exhibitionProvider.createExhibition(
      newExhibition,
      selectedImages: _selectedImages,
    );

    if (mounted) {
      if (success) {
        if (exhibitionProvider.errorMessage != null) {
          FeedbackHelper.showError(context, exhibitionProvider.errorMessage!);
        } else {
          FeedbackHelper.showSuccess(
            context,
            'Exhibition created successfully!',
          );
        }

        context.pop();
      } else {
        FeedbackHelper.showError(
          context,
          exhibitionProvider.errorMessage ?? 'Failed to create exhibition',
        );
      }
    }
  }

  Widget _buildFormSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool isAccentFocus = false,
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
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            fillColor: Colors.white,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isAccentFocus
                    ? AppColors.primaryAccent
                    : AppColors.primaryText,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
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
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          validator: validator,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade400,
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            fillColor: Colors.white,
            filled: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primaryText,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
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

  Widget _buildDateCard({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required DateFormat dateFormat,
  }) {
    return Expanded(
      child: InkWell(
        // Open date picker.
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      date == null ? 'Select Date' : dateFormat.format(date),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: date == null
                            ? Colors.grey.shade400
                            : AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: date == null
                    ? Colors.grey.shade400
                    : AppColors.primaryAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ExhibitionProvider>().isLoading;
    final dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppPageHeader(
              title: 'Create Exhibition',
              showBackButton: true,
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show basic event information fields.
                        _buildFormSection(
                          title: 'Basic Information',
                          children: [
                            _buildTextField(
                              controller: _nameController,
                              label: 'Exhibition Name',
                              hint: 'e.g. Startup Connect MY',
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _locationController,
                              label: 'Location',
                              hint: 'e.g. Convention Centre',
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildDropdownField(
                              label: 'Category',
                              hint: 'Select category',
                              value: _selectedCategory,
                              items: _categories,
                              onChanged: (val) =>
                                  setState(() => _selectedCategory = val),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 20),
                            _buildDropdownField(
                              label: 'Event Type (Optional)',
                              hint: 'Select event type',
                              value: _selectedEventType,
                              items: _eventTypes,
                              onChanged: (val) =>
                                  setState(() => _selectedEventType = val),
                            ),
                          ],
                        ),

                        // Show event date fields.
                        _buildFormSection(
                          title: 'Event Dates',
                          children: [
                            Row(
                              children: [
                                _buildDateCard(
                                  label: 'Start Date',
                                  date: _startDate,
                                  onTap: () => _selectDate(context, true),
                                  dateFormat: dateFormat,
                                ),
                                const SizedBox(width: 16),
                                _buildDateCard(
                                  label: 'End Date',
                                  date: _endDate,
                                  onTap: () => _selectDate(context, false),
                                  dateFormat: dateFormat,
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Show event description field.
                        _buildFormSection(
                          title: 'Description',
                          children: [
                            _buildTextField(
                              controller: _descriptionController,
                              label: 'Details',
                              hint:
                                  'Tell exhibitors what this event is about...',
                              maxLines: 5,
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                              isAccentFocus: true,
                            ),
                          ],
                        ),

                        // Show event image upload section.
                        _buildFormSection(
                          title: 'Event Images',
                          children: [
                            Text(
                              'Upload up to 4 images for this exhibition. This is optional.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryText.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '(${_selectedImages.length}/4 selected)',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Show selected image previews.
                            if (_selectedImages.isNotEmpty) ...[
                              SizedBox(
                                height: 90,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: _selectedImages.length,
                                  itemBuilder: (context, index) {
                                    final file = _selectedImages[index];

                                    return Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      width: 90,
                                      height: 90,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: kIsWeb
                                                ? Image.network(
                                                    file.path,
                                                    width: 90,
                                                    height: 90,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.file(
                                                    File(file.path),
                                                    width: 90,
                                                    height: 90,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Show add image button.
                            if (_selectedImages.length < 4)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _pickImages,
                                  icon: const Icon(
                                    Icons.add_photo_alternate_outlined,
                                  ),
                                  label: const Text('Add Images'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryAccent,
                                    side: const BorderSide(
                                      color: AppColors.primaryAccent,
                                      width: 1.5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Show create exhibition action.
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleCreate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Create Exhibition',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
