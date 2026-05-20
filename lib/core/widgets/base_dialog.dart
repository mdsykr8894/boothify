import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import 'app_button.dart';

/// A premium, reusable dialog box designed for standard confirmations, prompts,
/// notifications, and action alerts inside the Boothify system.
///
/// Supports 4 preset semantic variants:
/// * [DialogVariant.info] - Standard instructions or generic checks (Neutral dark accent, NOT brand pink by default)
/// * [DialogVariant.success] - Successful operation completion (Green accent)
/// * [DialogVariant.warning] - Cautions/Important reminders before proceeding (Orange/Amber accent)
/// * [DialogVariant.destructive] - Deletions, blocks, blocks block blocks (Red accent)
///
/// ### Examples of Usage:
///
/// #### 1. Warning Confirmation Dialog:
/// ```dart
/// BaseDialog.show(
///   context: context,
///   title: 'Unpublish Event?',
///   message: 'Are you sure you want to unpublish this exhibition? It will be hidden from draft and search explorers.',
///   variant: DialogVariant.warning,
///   primaryLabel: 'Unpublish',
///   onPrimaryPressed: () {
///     Navigator.pop(context);
///     // Perform action...
///   },
/// );
/// ```
///
/// #### 2. Destructive Confirmation Dialog:
/// ```dart
/// BaseDialog.show(
///   context: context,
///   title: 'Delete Package',
///   message: 'Are you sure you want to permanently delete this booth package? This action is irreversible.',
///   variant: DialogVariant.destructive,
///   primaryLabel: 'Delete',
///   onPrimaryPressed: () async {
///     // Perform delete logic...
///   },
/// );
/// ```
///
/// #### 3. Info / Neutral Confirmation:
/// ```dart
/// BaseDialog.show(
///   context: context,
///   title: 'Confirm Booking Details',
///   message: 'Please review your booking details before proceeding to the final payment gateway.',
///   variant: DialogVariant.info,
///   primaryLabel: 'Confirm',
///   secondaryLabel: 'Cancel',
///   onPrimaryPressed: () => print('Booking confirmed!'),
/// );
/// ```
///
/// #### 4. Dialog with Custom Body Slot (e.g. Reject Application Form):
/// ```dart
/// final reasonController = TextEditingController();
/// BaseDialog.show(
///   context: context,
///   title: 'Reject Application',
///   message: 'Please provide a justification for rejecting this application.',
///   variant: DialogVariant.destructive,
///   primaryLabel: 'Reject',
///   customBody: Padding(
///     padding: const EdgeInsets.only(top: 16.0),
///     child: AppTextField(
///       controller: reasonController,
///       label: 'Rejection Reason',
///       hint: 'e.g. Insufficient catalog detail',
///       maxLines: 2,
///     ),
///   ),
///   onPrimaryPressed: () {
///     final reason = reasonController.text.trim();
///     if (reason.isNotEmpty) {
///       Navigator.pop(context, reason);
///     }
///   },
/// );
/// ```
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

  /// Static helper to trigger the dialog directly in the screen tree context.
  /// Set [barrierDismissible] to false only for highly critical or submission operations.
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
            borderRadius: AppRadius.l, // matches standard app button style
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
                  // 1. Semantic Accent Icon
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

                  // 2. Bold Premium Title
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

                  // 3. Readable Description Message
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

                  // 4. Custom Body Slot
                  if (customBody != null) ...[
                    customBody!,
                  ],
                  const SizedBox(height: 24),

                  // 5. Standardized Action Footer
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
