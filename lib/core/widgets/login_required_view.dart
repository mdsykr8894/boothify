import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import 'app_button.dart';

// Reusable login required message.
class LoginRequiredView extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onLoginPressed;
  final double? topSpacing;

  const LoginRequiredView({
    super.key,
    required this.title,
    required this.message,
    this.buttonText = 'Log in',
    required this.onLoginPressed,
    this.topSpacing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topSpacing ?? 56),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 22),
            Text(
              message,
              style: const TextStyle(
                fontSize: 17,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 38),

            // Send user to login flow.
            AppButton(
              text: buttonText,
              width: 170,
              height: 58,
              onPressed: onLoginPressed,
            ),
          ],
        ),
      ),
    );
  }
}