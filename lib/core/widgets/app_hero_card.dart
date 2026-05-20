import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';

class AppHeroCard extends StatelessWidget {
  final String title; // Badge pill text (e.g. "Platform", "Organizer", "Live Now")
  final String mainValue; // Headline text
  final String? subtitle; // Short supporting description text
  final IconData? icon; // Optional badge icon (e.g. Icons.auto_awesome, Icons.shield_outlined)
  final bool isDark; // Signature compatibility
  final List<Widget>? stats; // Optional bottom stats widgets
  final String? ctaText; // Optional bottom CTA text
  final bool isPromotional; // Signature compatibility
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
    const Color backgroundColor = AppColors.primaryText; // 0xFF222222 premium dark charcoal
    const Color textColor = Colors.white;
    final Color secondaryTextColor = Colors.white.withValues(alpha: 0.8);
    const Color eyebrowColor = AppColors.primaryAccent;

    // Abstract overlapping circular right-side visual anchor to balance left-heavy layouts
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
                color: eyebrowColor.withValues(alpha: 0.05), // Extremely low-opacity pink circle
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
                  color: Colors.white.withValues(alpha: 0.02), // Subdued white inner circle accent
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Main card content area
    Widget cardContent = Container(
      constraints: const BoxConstraints(minHeight: 230), // Consistent 230px minimum height globally
      padding: const EdgeInsets.all(24.0), // Consistent 24px padding across screens
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space out top text and bottom rows naturally
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Premium Unified Translucent Pink Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: eyebrowColor.withValues(alpha: 0.15), // Translucent pink
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
                        icon, // Dynamic pill badge icon
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
              const SizedBox(height: 18), // Top badge to headline gap: 18px
              
              // 2. Large Bold Main Headline (Wraps naturally to 2 lines)
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
              
              // 3. Short Supporting Subtext (Light grey / white with opacity)
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 10), // Headline to subtext gap: 10px
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor, // Highly readable white/light-grey
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),

          // 4. Bottom Info Row: CTA (Explore) or Stats (Dashboards)
          if (ctaText != null) ...[
            const SizedBox(height: 20), // Subtext to bottom CTA gap
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ctaText!,
                  style: const TextStyle(
                    color: Colors.white, // Pure white like the reference
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward,
                  color: eyebrowColor, // Elegant brand pink arrow
                  size: 16,
                ),
              ],
            ),
          ] else if (stats != null && stats!.isNotEmpty) ...[
            const SizedBox(height: 20), // Subtext to bottom stats gap
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
        borderRadius: BorderRadius.circular(AppRadius.xl), // Premium 24px radius
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
            // Abstract circular right-side visual anchor to balance left-heavy layout
            rightVisualAnchor,
            
            // Hero card main contents
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
