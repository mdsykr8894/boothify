import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/widgets/base_dialog.dart';
import '../../../core/utils/feedback_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPageHeader(
              title: 'Profile',
              actions: user == null
                  ? null
                  : [
                      HeaderActionButton(
                        onPressed: () => context.push(AppRoutes.notifications),
                        icon: Icons.notifications_none_rounded,
                      ),
                    ],
            ),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenHorizontal,
                    vertical: AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      _ProfileCard(user: user),
                      const SizedBox(height: 32),
                      if (user == null) ...[
                        _buildGuestMenu(context),
                      ] else ...[
                        _buildUserMenu(context, user),
                      ],
                      const SizedBox(height: 24),
                      _buildActionButton(context, user),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestMenu(BuildContext context) {
    return Column(
      children: [
        const _ProfileSectionTitle(title: 'SUPPORT'),
        _ProfileMenuItem(
          icon: Icons.help_outline_rounded,
          title: 'Help Center',
          onTap: () => _showComingSoon(context),
        ),
        _ProfileMenuItem(
          icon: Icons.info_outline_rounded,
          title: 'About Boothify',
          onTap: () => _showComingSoon(context),
        ),
        _ProfileMenuItem(
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  Widget _buildUserMenu(BuildContext context, dynamic user) {
    String roleSpecificTitle = 'Profile Details';

    if (user.role == 'Exhibitor') {
      roleSpecificTitle = 'Company Profile';
    } else if (user.role == 'Organizer') {
      roleSpecificTitle = 'Organization Profile';
    } else if (user.role == 'Admin') {
      roleSpecificTitle = 'Admin Profile';
    }

    return Column(
      children: [
        const _ProfileSectionTitle(title: 'ACCOUNT'),
        _ProfileMenuItem(
          icon: Icons.person_outline_rounded,
          title: 'Personal Information',
          onTap: () => context.push(AppRoutes.personalInformation),
        ),
        _ProfileMenuItem(
          icon: Icons.business_center_outlined,
          title: roleSpecificTitle,
          onTap: () => _showComingSoon(context),
        ),
        _ProfileMenuItem(
          icon: Icons.notifications_none_rounded,
          title: 'Notification Preferences',
          onTap: () => context.push(AppRoutes.notifications),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 28),
        const _ProfileSectionTitle(title: 'PREFERENCES'),
        _ProfileMenuItem(
          icon: Icons.language_rounded,
          title: 'Language',
          onTap: () => _showComingSoon(context),
        ),
        _ProfileMenuItem(
          icon: Icons.palette_outlined,
          title: 'Theme',
          onTap: () => _showComingSoon(context),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 28),
        const _ProfileSectionTitle(title: 'SUPPORT'),
        _ProfileMenuItem(
          icon: Icons.help_outline_rounded,
          title: 'Help Center',
          onTap: () => _showComingSoon(context),
        ),
        _ProfileMenuItem(
          icon: Icons.info_outline_rounded,
          title: 'About Boothify',
          onTap: () => _showComingSoon(context),
        ),
        _ProfileMenuItem(
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          onTap: () => _showComingSoon(context),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, dynamic user) {
    if (user == null) {
      return AppButton(
        text: 'Log In / Sign Up',
        color: Colors.black,
        height: 54,
        onPressed: () => context.go(AppRoutes.login),
      );
    }

    return AppButton(
      text: 'Log Out',
      isSecondary: true,
      color: AppColors.primaryAccent,
      height: 54,
      onPressed: () {
        BaseDialog.show(
          context: context,
          title: 'Log Out',
          message: 'Are you sure you want to log out of your account?',
          variant: DialogVariant.destructive,
          primaryLabel: 'Log Out',
          secondaryLabel: 'Cancel',
          onPrimaryPressed: () async {
            Navigator.pop(context); // Close confirmation dialog
            await context.read<AuthProvider>().signOut();
            if (context.mounted) {
              context.go(AppRoutes.root);
            }
          },
        );
      },
    );
  }

  void _showComingSoon(BuildContext context) {
    FeedbackHelper.showInfo(context, 'Coming soon');
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic user;

  const _ProfileCard({required this.user});

  double _calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.size.width;
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuest = user == null;
    final String name = isGuest ? 'Guest User' : user.name;
    final String email = isGuest
        ? 'Log in to personalize your experience'
        : user.email;
    final String initial = isGuest ? 'G' : name.substring(0, 1).toUpperCase();

    const nameStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.primaryText,
    );
    const emailStyle = TextStyle(
      fontSize: 14,
      color: AppColors.secondaryText,
    );

    final nameWidth = _calculateTextWidth(name, nameStyle);
    final emailWidth = _calculateTextWidth(email, emailStyle);

    final bool badgeBesideName = !isGuest && nameWidth <= emailWidth;
    final bool badgeBesideEmail = !isGuest && emailWidth < nameWidth;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Ring
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.08),
                    width: 2,
                  ),
                ),
              ),
              // Avatar
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
              ),
              if (!isGuest)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name,
                  style: nameStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeBesideName) ...[
                const SizedBox(width: 8),
                StatusBadge(
                  label: user.role,
                  color: AppColors.primaryAccent,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  email,
                  style: emailStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeBesideEmail) ...[
                const SizedBox(width: 8),
                StatusBadge(
                  label: user.role,
                  color: AppColors.primaryAccent,
                ),
              ],
            ],
          ),
          // If text is very long and we forced badge below
          if (!isGuest && !badgeBesideName && !badgeBesideEmail) ...[
            const SizedBox(height: 12),
            StatusBadge(
              label: user.role,
              color: AppColors.primaryAccent,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileSectionTitle extends StatelessWidget {
  final String title;

  const _ProfileSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: 16,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.secondaryText,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: AppColors.primaryText,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade300,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
