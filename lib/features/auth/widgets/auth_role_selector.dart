import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AuthRoleSelector extends StatelessWidget {
  final String selectedRole;
  final Function(String) onRoleChanged;

  const AuthRoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'I am an:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildRoleChip('Exhibitor', Icons.person_outline),
            const SizedBox(width: 12),
            _buildRoleChip('Organizer', Icons.business_center_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleChip(String role, IconData icon) {
    final isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => onRoleChanged(role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.primaryAccent.withValues(alpha: 0.05) 
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? AppColors.primaryAccent 
                  : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primaryAccent : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                role,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.primaryAccent : Colors.black54,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppColors.primaryAccent,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
