import 'package:flutter/material.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';

// Reusable page header.
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;

  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBackButton) {
      // Show main screen header.
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
          vertical: AppSpacing.s,
        ),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h1.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...?actions,
            ],
          ),
        ),
      );
    }

    // Show sub screen header.
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.s,
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            // Show back button.
            SizedBox(
              width: 48,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
            ),

            // Keep title centered.
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.h1.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Show right actions.
            SizedBox(
              width: 48,
              child: (actions != null && actions!.isNotEmpty)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!.map((a) {
                        if (a is IconButton) {
                          return IconButton(
                            onPressed: a.onPressed,
                            icon: a.icon,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerRight,
                            constraints: const BoxConstraints(),
                          );
                        }

                        // Keep custom action widget.
                        return a;
                      }).toList(),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable circular header action button.
class HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;

  const HeaderActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 22,
          color: iconColor ?? Colors.black87,
        ),
        padding: EdgeInsets.zero,
        splashRadius: 22,
      ),
    );
  }
}