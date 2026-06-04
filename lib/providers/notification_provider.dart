import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/notification_model.dart';
import '../data/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  // Internal list of notifications.
  List<NotificationModel> _notifications = [];
  
  // Real-time stream subscription reference.
  StreamSubscription<List<NotificationModel>>? _subscription;

  // Track the active user ID for current subscription to prevent duplicate subscribes.
  String? _currentUserId;

  // Track if provider is disposed to prevent notifyListeners calls.
  bool _isDisposed = false;

  List<NotificationModel> get notifications => _notifications;

  // Calculate unread notifications dynamically.
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Subscribe to real-time notification stream for current user.
  void subscribeToNotifications(String userId) {
    if (userId.isEmpty) {
      unsubscribe();
      return;
    }
    
    if (_currentUserId == userId && _subscription != null) {
      return;
    }
    
    _currentUserId = userId;
    
    // Cancel any active subscription first to avoid duplicate listeners.
    _subscription?.cancel();

    _subscription = _service.getNotificationsStream(userId).listen(
      (list) {
        _notifications = list;
        if (!_isDisposed) {
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('Error in notifications stream: $error');
      },
    );
  }

  // Cancel subscription and clear notifications.
  void unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    _currentUserId = null;
    _notifications = [];
    
    if (!_isDisposed) {
      // Defer notifying listeners to prevent "setState() or markNeedsBuild() called during build"
      // when unsubscribe is invoked inside build-phase dependency changes or widget disposals.
      Future.microtask(() {
        if (!_isDisposed) {
          notifyListeners();
        }
      });
    }
  }

  // Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    await _service.markAsRead(notificationId);
  }

  // Mark all user notifications as read.
  Future<void> markAllAsRead(String recipientId) async {
    await _service.markAllAsRead(recipientId);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
