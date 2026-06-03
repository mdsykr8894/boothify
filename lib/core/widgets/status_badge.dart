import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

// Reusable status badge.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
  });

  static Color getStatusColor(String status) {
    // Match status text with badge color.
    switch (status.toLowerCase()) {
      case 'pending':
      case 'draft':
      case 'active':
        return AppColors.warning;
      case 'approved':
      case 'published':
      case 'available':
      case 'ongoing':
        return AppColors.success;
      case 'rejected':
      case 'error':
        return AppColors.error;
      case 'booking closed':
        return AppColors.primaryAccent;
      case 'cancelled':
      case 'inactive':
      case 'completed':
        return AppColors.secondaryText;
      case 'paid':
      case 'booked':
      case 'upcoming':
        return AppColors.primaryAccent;
      case 'booking open':
        return AppColors.success;
      default:
        return AppColors.secondaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? getStatusColor(label);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: effectiveColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}