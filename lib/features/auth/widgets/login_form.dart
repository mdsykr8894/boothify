import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/utils/feedback_helper.dart';
import '../../../providers/auth_provider.dart';
import 'auth_text_field.dart';
import 'social_auth_section.dart';

class LoginForm extends StatefulWidget {
  final VoidCallback onSwitchToRegister;

  const LoginForm({
    super.key,
    required this.onSwitchToRegister,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // Controllers store user input from the login fields.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // UI state for the remember me checkbox.
  bool _rememberMe = false;

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyAuthError(String? error) {
    // Convert auth errors into user-friendly messages.
    if (error == null || error.isEmpty) {
      return 'Login failed. Please try again.';
    }

    final lower = error.toLowerCase();

    // Handle common wrong login credential errors.
    if (lower.contains('invalid-credential') ||
        lower.contains('wrong-password') ||
        lower.contains('user-not-found')) {
      return 'Invalid email or password. Please try again.';
    }

    // Handle invalid email format error.
    if (lower.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }

    // Handle internet connection related error.
    if (lower.contains('network')) {
      return 'Network error. Please check your connection.';
    }

    // Default message for unknown login error.
    return 'Login failed. Please try again.';
  }

  void _handleLogin() async {
    // Get AuthProvider without rebuilding this widget.
    final authProvider = context.read<AuthProvider>();

    // Attempt login using email and password.
    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // Ensure widget still exists before using context.
    if (mounted) {
      if (success) {
        // Get the logged-in user's role.
        final role = authProvider.role;

        // Redirect admin user to admin area.
        if (role == 'Admin') {
          context.go(AppRoutes.admin);
        }

        // Redirect organizer user to organizer area.
        else if (role == 'Organizer') {
          context.go(AppRoutes.organizer);
        }

        // Redirect exhibitor or normal user to public home.
        else {
          context.go(AppRoutes.root);
        }
      } else {
        // Show readable error message if login fails.
        FeedbackHelper.showError(
          context,
          _friendlyAuthError(authProvider.errorMessage),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch loading state to update the sign in button.
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email input field.
        AuthTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your email',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),

        // Password input field.
        AuthTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Remember me checkbox UI.
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: AppColors.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (val) => setState(() => _rememberMe = val!),
                  ),
                ),
                const SizedBox(width: 8),

                // Remember me label.
                const Text(
                  'Remember me',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),

            // Forgot password placeholder.
            TextButton(
              onPressed: () {
                FeedbackHelper.showInfo(context, 'Coming soon');
              },
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Main login button.
        AppButton(
          text: 'Sign In',
          color: Colors.black,
          height: 58,
          isLoading: isLoading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 38),

        // Social login section placeholder.
        const SocialAuthSection(),
        const SizedBox(height: 38),

        // Link to switch into register form.
        Center(
          child: GestureDetector(
            onTap: widget.onSwitchToRegister,
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.secondaryText,
                ),
                children: [
                  TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: "Sign up",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}