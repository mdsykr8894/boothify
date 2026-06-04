import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../../core/utils/date_format_helper.dart';
import '../../../core/utils/feedback_helper.dart';
import '../../../data/services/application_service.dart';
import '../../../data/services/exhibition_service.dart';
import '../../../data/services/user_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../data/models/notification_model.dart';

// Display user notifications in real-time.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    // Subscribe to notification stream after first frame layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<NotificationProvider>().subscribeToNotifications(user.uid);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'application_approved':
        return Icons.check_circle_rounded;
      case 'application_rejected':
        return Icons.cancel_rounded;
      case 'application_withdrawn':
        return Icons.remove_circle_rounded;
      case 'payment_completed':
      case 'payment_completed_organizer':
      case 'admin_payment_completed':
        return Icons.payments_rounded;
      case 'application_submitted_self':
      case 'application_submitted_organizer':
      case 'admin_application_submitted':
        return Icons.assignment_rounded;
      case 'application_resubmitted':
      case 'application_resubmitted_self':
      case 'admin_application_resubmitted':
        return Icons.assignment_return_rounded;
      case 'admin_exhibition_created':
        return Icons.event_available_rounded;
      case 'admin_user_registered':
        return Icons.person_add_alt_1_rounded;
      case 'exhibition_created_self':
      case 'exhibition_published':
        return Icons.event_note_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'application_approved':
        return Colors.green;
      case 'application_rejected':
        return Colors.red;
      case 'application_withdrawn':
        return Colors.orange;
      case 'payment_completed':
      case 'payment_completed_organizer':
      case 'admin_payment_completed':
        return Colors.teal;
      case 'application_submitted_self':
      case 'application_submitted_organizer':
      case 'admin_application_submitted':
        return AppColors.primaryAccent;
      case 'application_resubmitted':
      case 'application_resubmitted_self':
      case 'admin_application_resubmitted':
        return Colors.blue;
      case 'admin_exhibition_created':
        return Colors.purple;
      case 'admin_user_registered':
        return Colors.indigo;
      case 'exhibition_created_self':
      case 'exhibition_published':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    final provider = context.read<NotificationProvider>();
    
    // Mark as read in Firestore.
    if (!notification.isRead) {
      await provider.markAsRead(notification.id);
    }

    if (notification.relatedId == null || notification.relatedId!.isEmpty) return;

    setState(() {
      _isLoadingDetails = true;
    });

    try {
      if (notification.relatedType == 'application') {
        final application = await ApplicationService().fetchApplicationById(notification.relatedId!);
        
        if (!mounted) return;
        setState(() {
          _isLoadingDetails = false;
        });

        if (application != null) {
          context.push(AppRoutes.applicationDetails, extra: application);
        } else {
          FeedbackHelper.showError(context, 'Failed to load application details.');
        }
      } else if (notification.relatedType == 'exhibition') {
        final exhibition = await ExhibitionService().fetchExhibitionById(notification.relatedId!);

        if (!mounted) return;
        setState(() {
          _isLoadingDetails = false;
        });

        if (exhibition != null) {
          final role = context.read<AuthProvider>().currentUser?.role;
          if (role == 'Admin') {
            context.push(AppRoutes.adminExhibitionDetails, extra: exhibition);
          } else if (role == 'Organizer') {
            context.push(AppRoutes.organizerExhibitionDetails, extra: exhibition);
          } else {
            context.push(AppRoutes.exhibitionDetails, extra: exhibition);
          }
        } else {
          FeedbackHelper.showError(context, 'Failed to load exhibition details.');
        }
      } else if (notification.relatedType == 'user') {
        final user = await UserService().fetchUserById(notification.relatedId!);

        if (!mounted) return;
        setState(() {
          _isLoadingDetails = false;
        });

        if (user != null) {
          context.push(AppRoutes.adminUserDetails, extra: user);
        } else {
          FeedbackHelper.showError(context, 'Failed to load user details.');
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingDetails = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
        FeedbackHelper.showError(context, 'An error occurred while loading details: $e');
      }
    }
  }

  void _markAllAsRead(String userId) {
    context.read<NotificationProvider>().markAllAsRead(userId);
    FeedbackHelper.showSuccess(context, 'All notifications marked as read');
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;
    final unreadCount = notificationProvider.unreadCount;

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                AppPageHeader(
                  title: 'Notifications',
                  showBackButton: true,
                  actions: [
                    if (user != null && unreadCount > 0)
                      HeaderActionButton(
                        icon: Icons.done_all_rounded,
                        iconColor: AppColors.primaryAccent,
                        onPressed: () => _markAllAsRead(user.uid),
                      ),
                  ],
                ),

                // Show notifications content.
                Expanded(
                  child: notifications.isEmpty
                      ? const AppEmptyState(
                          title: 'No Notifications',
                          message: 'Important updates will appear here.',
                          icon: Icons.notifications_none,
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            if (user != null) {
                              context.read<NotificationProvider>().subscribeToNotifications(user.uid);
                            }
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(
                              left: AppSpacing.screenHorizontal,
                              right: AppSpacing.screenHorizontal,
                              top: AppSpacing.m,
                              bottom: AppSpacing.xl,
                            ),
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              final notification = notifications[index];
                              final icon = _getIconForType(notification.type);
                              final color = _getColorForType(notification.type);
                              final timeStr = notification.createdAt != null
                                  ? DateFormatHelper.formatDateTime(notification.createdAt!)
                                  : 'N/A';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: notification.isRead ? Colors.white : const Color(0xFFF7FAFC),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: notification.isRead ? Colors.grey.shade100 : AppColors.primaryAccent.withValues(alpha: 0.15),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: InkWell(
                                    onTap: () => _handleNotificationTap(notification),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0,
                                        vertical: 18.0,
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Notification status icon.
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.08),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: color.withValues(alpha: 0.15),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                icon,
                                                color: color,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Notification contents.
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        notification.title,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: notification.isRead ? FontWeight.bold : FontWeight.w800,
                                                          color: AppColors.primaryText,
                                                        ),
                                                      ),
                                                    ),
                                                    if (!notification.isRead) ...[
                                                      const SizedBox(width: 8),
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: const BoxDecoration(
                                                          color: AppColors.primaryAccent,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  notification.body,
                                                  style: TextStyle(
                                                    fontSize: 13.5,
                                                    color: notification.isRead ? Colors.grey.shade600 : AppColors.primaryText.withValues(alpha: 0.8),
                                                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w500,
                                                    height: 1.4,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  timeStr,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey.shade400,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoadingDetails)
          const Positioned.fill(
            child: Stack(
              children: [
                ModalBarrier(
                  color: Colors.black12,
                  dismissible: false,
                ),
                Center(
                  child: AppLoading(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}