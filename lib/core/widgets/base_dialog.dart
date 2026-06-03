import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import 'app_button.dart';

// Reusable app dialog.
class BaseDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final DialogVariant variant;
  final String? primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final bool isLoading;
  final bool isStackedActions;
  final Widget? customBody;
  final Widget? customFooter;

  const BaseDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.variant = DialogVariant.info,
    this.primaryLabel,
    this.secondaryLabel,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.isLoading = false,
    this.isStackedActions = false,
    this.customBody,
    this.customFooter,
  });

  // Show dialog from screen context.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    DialogVariant variant = DialogVariant.info,
    String? primaryLabel,
    String? secondaryLabel,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    IconData? icon,
    bool isLoading = false,
    bool isStackedActions = false,
    Widget? customBody,
    Widget? customFooter,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => BaseDialog(
        title: title,
        message: message,
        variant: variant,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        onPrimaryPressed: onPrimaryPressed,
        onSecondaryPressed: onSecondaryPressed,
        icon: icon,
        isLoading: isLoading,
        isStackedActions: isStackedActions,
        customBody: customBody,
        customFooter: customFooter,
      ),
    );
  }

  Color _getVariantAccentColor() {
    // Set icon color based on dialog type.
    switch (variant) {
      case DialogVariant.success:
        return AppColors.success;
      case DialogVariant.warning:
        return AppColors.primaryText;
      case DialogVariant.destructive:
        return AppColors.primaryAccent;
      case DialogVariant.info:
        return AppColors.primaryText;
    }
  }

  Color _getVariantBgColor() {
    // Set icon background based on dialog type.
    switch (variant) {
      case DialogVariant.success:
        return const Color(0xFFE8F5E9);
      case DialogVariant.warning:
        return const Color(0xFFF5F5F5);
      case DialogVariant.destructive:
        return const Color(0xFFFFEEF2);
      case DialogVariant.info:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getVariantButtonColor() {
    // Set primary button color based on dialog type.
    switch (variant) {
      case DialogVariant.success:
        return AppColors.success;
      case DialogVariant.warning:
        return const Color(0xFF222222);
      case DialogVariant.destructive:
        return AppColors.primaryAccent;
      case DialogVariant.info:
        return const Color(0xFF222222);
    }
  }

  IconData _getVariantIcon() {
    if (icon != null) return icon!;

    // Use default icon based on dialog type.
    switch (variant) {
      case DialogVariant.success:
        return Icons.check_circle_outline_rounded;
      case DialogVariant.warning:
        return Icons.warning_amber_rounded;
      case DialogVariant.destructive:
        return Icons.error_outline_rounded;
      case DialogVariant.info:
        return Icons.info_outline_rounded;
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    if (customFooter != null) {
      return customFooter!;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (primaryLabel != null) ...[
          AppButton(
            text: primaryLabel!,
            color: _getVariantButtonColor(),
            height: 52,
            borderRadius: AppRadius.l,
            isLoading: isLoading,
            onPressed: onPrimaryPressed,
          ),
        ],
        if (primaryLabel != null && secondaryLabel != null)
          const SizedBox(height: 12),
        if (secondaryLabel != null) ...[
          OutlinedButton(
            onPressed: onSecondaryPressed ?? () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: _getVariantButtonColor(),
              side: BorderSide(color: _getVariantButtonColor(), width: 1.5),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.l),
              ),
              overlayColor: _getVariantButtonColor().withAlpha(20),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Text(secondaryLabel!),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double maxDialogHeight = MediaQuery.of(context).size.height * 0.85;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Show semantic dialog icon.
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _getVariantBgColor(),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getVariantIcon(),
                        color: _getVariantAccentColor(),
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  // Show optional custom content.
                  if (customBody != null) ...[
                    customBody!,
                  ],
                  const SizedBox(height: 24),

                  // Show dialog action buttons.
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum DialogVariant {
  info,
  success,
  warning,
  destructive,
}