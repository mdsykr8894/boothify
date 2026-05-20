import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import 'auth_text_field.dart';
import 'social_auth_section.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/feedback_helper.dart';

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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyAuthError(String? error) {
    if (error == null || error.isEmpty) {
      return 'Login failed. Please try again.';
    }

    final lower = error.toLowerCase();

    if (lower.contains('invalid-credential') ||
        lower.contains('wrong-password') ||
        lower.contains('user-not-found')) {
      return 'Invalid email or password. Please try again.';
    }

    if (lower.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }

    if (lower.contains('network')) {
      return 'Network error. Please check your connection.';
    }

    return 'Login failed. Please try again.';
  }

  void _handleLogin() async {
    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      if (success) {
        final role = authProvider.role;
        if (role == 'Admin') {
          context.go(AppRoutes.admin);
        } else if (role == 'Organizer') {
          context.go(AppRoutes.organizer);
        } else {
          context.go(AppRoutes.root);
        }
      } else {
        FeedbackHelper.showError(
          context,
          _friendlyAuthError(authProvider.errorMessage),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'Enter your email',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
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
                const Text(
                  'Remember me',
                  style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
                ),
              ],
            ),
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
        AppButton(
          text: 'Sign In',
          color: Colors.black,
          height: 58,
          isLoading: isLoading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 38),
        const SocialAuthSection(),
        const SizedBox(height: 38),
        Center(
          child: GestureDetector(
            onTap: widget.onSwitchToRegister,
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 15, color: AppColors.secondaryText),
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
