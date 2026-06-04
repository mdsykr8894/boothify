import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String recipientId;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final String? relatedType; // "application" or "exhibition"
  final String? senderName;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.relatedType,
    this.senderName,
    this.isRead = false,
    this.createdAt,
  });

  // Convert Firestore document snapshot into NotificationModel.
  factory NotificationModel.fromMap(Map<String, dynamic> data, String documentId) {
    return NotificationModel(
      id: documentId,
      recipientId: data['recipientId'] ?? '',
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      type: data['type'] ?? '',
      relatedId: data['relatedId'],
      relatedType: data['relatedType'],
      senderName: data['senderName'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert NotificationModel into Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'type': type,
      'relatedId': relatedId,
      'relatedType': relatedType,
      'senderName': senderName,
      'isRead': isRead,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // Create a new NotificationModel with updated values.
  NotificationModel copyWith({
    String? recipientId,
    String? title,
    String? body,
    String? type,
    String? relatedId,
    String? relatedType,
    String? senderName,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id,
      recipientId: recipientId ?? this.recipientId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
      senderName: senderName ?? this.senderName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
