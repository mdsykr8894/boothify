import 'package:flutter/material.dart';
import '../constants/app_radius.dart';

// Shared snackbar feedback helper.
class FeedbackHelper {
  // Show success feedback.
  static void showSuccess(
    BuildContext context,
    String message,
  ) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF2ECC71),
    );
  }

  // Show error feedback.
  static void showError(
    BuildContext context,
    String message,
  ) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      iconColor: const Color(0xFFE74C3C),
    );
  }

  // Show warning feedback.
  static void showWarning(
    BuildContext context,
    String message,
  ) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFF1C40F),
    );
  }

  // Show info feedback.
  static void showInfo(
    BuildContext context,
    String message,
  ) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.info_outline_rounded,
      iconColor: const Color(0xFF3498DB),
    );
  }

  // Build shared snackbar layout.
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Remove existing snackbar before showing a new one.
    scaffoldMessenger.clearSnackBars();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF202225),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
        content: Row(
          children: [
            // Show feedback icon.
            Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 12),

            // Show feedback message.
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}