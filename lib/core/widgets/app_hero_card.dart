import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';

// Reusable hero card.
class AppHeroCard extends StatelessWidget {
  final String title;
  final String mainValue;
  final String? subtitle;
  final IconData? icon;
  final bool isDark;
  final List<Widget>? stats;
  final String? ctaText;
  final bool isPromotional;
  final VoidCallback? onTap;

  const AppHeroCard({
    super.key,
    required this.title,
    required this.mainValue,
    this.subtitle,
    this.icon,
    this.isDark = true,
    this.stats,
    this.ctaText,
    this.isPromotional = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = AppColors.primaryText;
    const Color textColor = Colors.white;
    final Color secondaryTextColor = Colors.white.withValues(alpha: 0.8);
    const Color eyebrowColor = AppColors.primaryAccent;

    // Add decorative circle background.
    final Widget rightVisualAnchor = Positioned(
      right: -30,
      bottom: -30,
      child: IgnorePointer(
        child: Stack(
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: eyebrowColor.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              right: 25,
              bottom: 25,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.02),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Build hero card content.
    Widget cardContent = Container(
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show badge label.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: eyebrowColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: eyebrowColor.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 13,
                        color: eyebrowColor,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        color: eyebrowColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              Text(
                mainValue,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.6,
                  color: textColor,
                  height: 1.2,
                ),
              ),

              // Show optional subtitle.
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),

          // Show CTA row or stats row.
          if (ctaText != null) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ctaText!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward,
                  color: eyebrowColor,
                  size: 16,
                ),
              ],
            ),
          ] else if (stats != null && stats!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: stats!,
            ),
          ],
        ],
      ),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          children: [
            rightVisualAnchor,

            // Make hero card tappable when action exists.
            onTap != null
                ? InkWell(
                    onTap: onTap,
                    splashColor: Colors.white.withValues(alpha: 0.05),
                    highlightColor: Colors.white.withValues(alpha: 0.02),
                    child: cardContent,
                  )
                : cardContent,
          ],
        ),
      ),
    );
  }
}