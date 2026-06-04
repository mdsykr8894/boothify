import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  // Stream of notifications for a specific user, sorted by creation date descending.
  Stream<List<NotificationModel>> getNotificationsStream(String recipientId) {
    return _firestore
        .collection(_collection)
        .where('recipientId', isEqualTo: recipientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Send a single notification (safe, caught errors will only print).
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      await _firestore.collection(_collection).add(notification.toMap());
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  // Send notification to all admin users.
  Future<void> sendNotificationsToAdmins({
    required String title,
    required String body,
    required String type,
    String? relatedId,
    String? relatedType,
    String? senderName,
    List<String> excludedUserIds = const [],
  }) async {
    try {
      final adminsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Admin')
          .get();

      if (adminsSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      bool hasUpdates = false;
      for (final doc in adminsSnapshot.docs) {
        if (excludedUserIds.contains(doc.id)) continue;

        final ref = _firestore.collection(_collection).doc();
        batch.set(ref, {
          'recipientId': doc.id,
          'title': title,
          'body': body,
          'type': type,
          'relatedId': relatedId,
          'relatedType': relatedType,
          'senderName': senderName,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        hasUpdates = true;
      }

      if (hasUpdates) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error sending notifications to admins: $e');
    }
  }

  // Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Mark all notifications for a specific recipient as read.
  Future<void> markAllAsRead(String recipientId) async {
    try {
      final unreadSnapshot = await _firestore
          .collection(_collection)
          .where('recipientId', isEqualTo: recipientId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
