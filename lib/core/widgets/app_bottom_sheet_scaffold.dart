import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'app_button.dart';

// Reusable bottom sheet layout.
class AppBottomSheetScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final String secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final bool isLoading;
  final bool isPrimaryEnabled;
  final Color? primaryColor;
  final bool showCloseButton;
  final bool showCancelButton;
  final double primaryHeight;
  final double primaryBorderRadius;
  final bool showDivider;
  final bool isScrollable;
  final double? maxHeightFactor;

  const AppBottomSheetScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.primaryLabel,
    this.onPrimaryPressed,
    this.secondaryLabel = 'Cancel',
    this.onSecondaryPressed,
    this.isLoading = false,
    this.isPrimaryEnabled = true,
    this.primaryColor,
    this.showCloseButton = false,
    this.showCancelButton = false,
    this.primaryHeight = 62.0,
    this.primaryBorderRadius = 16.0,
    this.showDivider = false,
    this.isScrollable = false,
    this.maxHeightFactor,
  });

  Widget _buildDragHandle() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 38,
        height: 5,
        margin: const EdgeInsets.only(top: 2, bottom: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2.5),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),

        // Show optional close button.
        if (showCloseButton) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: onSecondaryPressed ?? () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              size: 24,
              color: AppColors.primaryText.withValues(alpha: 0.6),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ],
    );
  }

  Widget _buildDividerOrSpacer() {
    if (showDivider) {
      return const Divider(height: 32, color: Color(0xFFF5F5F5));
    } else {
      return const SizedBox(height: 16);
    }
  }

  Widget _buildChild(BuildContext context) {
    return Theme(
      // Apply bottom sheet input styling.
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
          labelStyle: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.primaryAccent,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Show optional cancel button.
        if (showCancelButton &&
            (onSecondaryPressed != null || secondaryLabel == 'Cancel')) ...[
          Expanded(
            child: TextButton(
              onPressed: onSecondaryPressed ?? () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: Size(double.infinity, primaryHeight),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                secondaryLabel,
                style: TextStyle(
                  color: AppColors.primaryText.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],

        // Show primary action button.
        Expanded(
          flex: showCancelButton ? 2 : 1,
          child: AppButton(
            text: primaryLabel,
            color: primaryColor ?? AppColors.primaryText,
            height: primaryHeight,
            borderRadius: primaryBorderRadius,
            onPressed: isPrimaryEnabled ? onPrimaryPressed : null,
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget mainContent;

    if (!isScrollable) {
      // Use compact bottom sheet layout.
      mainContent = Container(
        padding: EdgeInsets.only(
          left: AppSpacing.screenHorizontal,
          right: AppSpacing.screenHorizontal,
          top: 10.0,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDragHandle(),
                _buildHeader(context),
                _buildDividerOrSpacer(),
                _buildChild(context),
                const SizedBox(height: 28),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      );
    } else {
      // Use scrollable bottom sheet layout.
      final screenHeight = MediaQuery.of(context).size.height;
      final maxSheetHeight = screenHeight * (maxHeightFactor ?? 0.85);

      mainContent = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxSheetHeight,
        ),
        child: Container(
          padding: EdgeInsets.only(
            left: AppSpacing.screenHorizontal,
            right: AppSpacing.screenHorizontal,
            top: 10.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDragHandle(),
                _buildHeader(context),
                _buildDividerOrSpacer(),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: _buildChild(context),
                  ),
                ),
                const SizedBox(height: 20),
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: NoOverscrollBehavior(),
      child: mainContent,
    );
  }
}

// Remove overscroll glow effect.
class NoOverscrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}