import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class BottomSheetDropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;

  const BottomSheetDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          initialValue: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
          borderRadius: BorderRadius.circular(16),
          items: items,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}
