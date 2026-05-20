import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import 'auth_role_selector.dart';
import 'auth_text_field.dart';
import 'social_auth_section.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/feedback_helper.dart';

class RegisterForm extends StatefulWidget {
  final VoidCallback onSwitchToLogin;

  const RegisterForm({
    super.key,
    required this.onSwitchToLogin,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Exhibitor';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyAuthError(String? error) {
    if (error == null || error.isEmpty) {
      return 'Registration failed. Please try again.';
    }

    final lower = error.toLowerCase();

    if (lower.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }

    if (lower.contains('weak-password')) {
      return 'Password is too weak. Please use a stronger password.';
    }

    if (lower.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }

    if (lower.contains('network')) {
      return 'Network error. Please check your connection.';
    }

    return 'Registration failed. Please try again.';
  }

  void _handleRegister() async {
    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      role: _selectedRole,
    );

    if (mounted) {
      if (success) {
        if (_selectedRole == 'Organizer') {
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
        AuthRoleSelector(
          selectedRole: _selectedRole,
          onRoleChanged: (role) => setState(() => _selectedRole = role),
        ),
        const SizedBox(height: 24),
        AuthTextField(
          controller: _nameController,
          label: 'Full Name',
          hint: 'Enter your full name',
          prefixIcon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
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
          hint: 'Create a password',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
        ),
        const SizedBox(height: 32),
        AppButton(
          text: 'Sign Up',
          color: Colors.black,
          height: 58,
          isLoading: isLoading,
          onPressed: _handleRegister,
        ),
        const SizedBox(height: 38),
        const SocialAuthSection(),
        const SizedBox(height: 38),
        Center(
          child: GestureDetector(
            onTap: widget.onSwitchToLogin,
            child: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 15, color: AppColors.secondaryText),
                children: [
                  TextSpan(text: "Already have an account? "),
                  TextSpan(
                    text: "Log in",
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
        const SizedBox(height: 20),
      ],
    );
  }
}
