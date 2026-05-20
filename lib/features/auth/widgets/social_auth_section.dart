import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/feedback_helper.dart';

class SocialAuthSection extends StatelessWidget {
  const SocialAuthSection({super.key});

  void _showComingSoon(BuildContext context) {
    FeedbackHelper.showInfo(context, 'Social login coming soon');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divider Row
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey.shade200,
                thickness: 1.5,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Colors.grey.shade200,
                thickness: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Social Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              context: context,
              child: const Icon(Icons.apple, size: 28),
              onTap: () => _showComingSoon(context),
            ),
            const SizedBox(width: 24),
            _buildSocialButton(
              context: context,
              child: const Text(
                'G',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              onTap: () => _showComingSoon(context),
            ),
            const SizedBox(width: 24),
            _buildSocialButton(
              context: context,
              child: const Text(
                'f',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  color: AppColors.primaryText,
                ),
              ),
              onTap: () => _showComingSoon(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}
