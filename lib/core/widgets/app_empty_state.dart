import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import 'app_button.dart';

// Reusable empty state view.
class AppEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final bool compact;

  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionLabel,
    this.onActionPressed,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double iconBgSize = compact ? 90 : 118;
    final double iconSize = compact ? 44 : 52;

    return Align(
      alignment: const Alignment(0, -0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show empty state icon.
            Container(
              width: iconBgSize,
              height: iconBgSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: iconSize,
                color: AppColors.secondaryText.withValues(alpha: 0.3),
              ),
            ),
            SizedBox(height: compact ? 20 : 32),
            Text(
              title,
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                message,
                style: AppTextStyles.bodyL.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Show optional action button.
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: AppSpacing.l),
              AppButton(
                text: actionLabel!,
                onPressed: onActionPressed,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}