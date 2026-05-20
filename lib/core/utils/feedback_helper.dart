import 'package:flutter/material.dart';
import '../constants/app_radius.dart';

class FeedbackHelper {
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

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF202225), // Elegant dark slate
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.m),
        ),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 28), // Premium bottom margin
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
        content: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 12),
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
