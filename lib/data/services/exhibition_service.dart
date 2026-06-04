import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/exhibition_model.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';

class ExhibitionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'exhibitions';
  final NotificationService _notificationService = NotificationService();

  int _compareByUpdatedOrCreated(ExhibitionModel a, ExhibitionModel b) {
    // Sort by updated date first, then created date.
    final aDate =
        a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate =
        b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    // Latest exhibition appears first.
    return bDate.compareTo(aDate);
  }

  Future<List<ExhibitionModel>> fetchPublishedExhibitions() async {
    try {
      // Fetch exhibitions that are published.
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isPublished', isEqualTo: true)
          .get();

      // Convert Firestore documents into ExhibitionModel list.
      final list = querySnapshot.docs
          .map((doc) => ExhibitionModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort latest exhibitions first.
      list.sort(_compareByUpdatedOrCreated);

      return list;
    } catch (e) {
      debugPrint('Error fetching published exhibitions: $e');
      return [];
    }
  }

  Future<List<ExhibitionModel>> fetchOrganizerExhibitions(
    String organizerId,
  ) async {
    try {
      // Fetch exhibitions created by one organizer.
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('organizerId', isEqualTo: organizerId)
          .get();

      // Convert Firestore documents into ExhibitionModel list.
      final list = querySnapshot.docs
          .map((doc) => ExhibitionModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort latest exhibitions first.
      list.sort(_compareByUpdatedOrCreated);

      return list;
    } catch (e) {
      debugPrint('Error fetching organizer exhibitions: $e');
      return [];
    }
  }

  Future<List<ExhibitionModel>> fetchAllExhibitions() async {
    try {
      // Fetch all exhibitions for admin.
      final querySnapshot = await _firestore.collection(_collection).get();

      // Convert Firestore documents into ExhibitionModel list.
      final list = querySnapshot.docs
          .map((doc) => ExhibitionModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort latest exhibitions first.
      list.sort(_compareByUpdatedOrCreated);

      return list;
    } catch (e) {
      debugPrint('Error fetching all exhibitions: $e');
      return [];
    }
  }

  Future<String?> createExhibition(ExhibitionModel exhibition) async {
    try {
      // Create new exhibition document.
      final docRef = await _firestore
          .collection(_collection)
          .add(exhibition.toMap());

      // Trigger admin notification safely in the background.
      _triggerCreateExhibitionNotification(exhibition, docRef.id);

      // Trigger self-confirmation notification for organizer.
      _triggerCreateExhibitionSelfNotification(exhibition, docRef.id);

      // Return generated document ID.
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating exhibition: $e');
      return null;
    }
  }

  Future<List<String>> uploadExhibitionImages({
    required String exhibitionId,
    required List<XFile> images,
  }) async {
    // Store uploaded image download URLs.
    final List<String> downloadUrls = [];

    // Upload maximum 4 images only.
    for (int i = 0; i < images.length && i < 4; i++) {
      try {
        final image = images[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        // Create unique Firebase Storage path.
        final ref = _storage
            .ref()
            .child('exhibitions/$exhibitionId/images/${timestamp}_$i.jpg');

        // Read image file as bytes.
        final bytes = await image.readAsBytes();

        // Upload image bytes to Firebase Storage.
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // Wait until upload completes.
        final snapshot = await uploadTask;

        // Get image download URL.
        final url = await snapshot.ref.getDownloadURL();

        downloadUrls.add(url);
      } catch (e) {
        debugPrint('Error uploading image $i: $e');
        throw Exception('Failed to upload image: $e');
      }
    }

    return downloadUrls;
  }

  Future<bool> updateExhibitionImageUrls(
    String exhibitionId,
    List<String> imageUrls,
  ) async {
    try {
      // Save uploaded image URLs into exhibition document.
      await _firestore.collection(_collection).doc(exhibitionId).update({
        'imageUrls': imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating exhibition image URLs: $e');
      return false;
    }
  }

  Future<bool> updateExhibition(ExhibitionModel exhibition) async {
    try {
      // Create updated model with latest updatedAt value.
      final updatedModel = exhibition.copyWith(updatedAt: DateTime.now());

      // Update exhibition document in Firestore.
      await _firestore
          .collection(_collection)
          .doc(exhibition.id)
          .update(updatedModel.toMap());

      return true;
    } catch (e) {
      debugPrint('Error updating exhibition: $e');
      return false;
    }
  }

  Future<bool> togglePublish(
    String exhibitionId,
    bool isPublished,
  ) async {
    try {
      // Update publish status.
      await _firestore.collection(_collection).doc(exhibitionId).update({
        'isPublished': isPublished,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Trigger notification to organizer if published.
      if (isPublished) {
        _triggerPublishNotification(exhibitionId);
      }

      return true;
    } catch (e) {
      debugPrint('Error toggling publish status: $e');
      return false;
    }
  }

  Future<bool> toggleBookingOpen(
    String exhibitionId,
    bool isBookingOpen,
  ) async {
    try {
      // Update booking open or closed status.
      await _firestore.collection(_collection).doc(exhibitionId).update({
        'isBookingOpen': isBookingOpen,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error toggling booking status: $e');
      return false;
    }
  }

  Future<void> touchExhibition(String exhibitionId) async {
    try {
      // Update only exhibition updatedAt timestamp.
      await _firestore.collection(_collection).doc(exhibitionId).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error touching exhibition: $e');
    }
  }

  Future<bool> deleteExhibition(String exhibitionId) async {
    try {
      // Use batch to delete exhibition and related data together.
      final batch = _firestore.batch();

      // Get all booth packages related to this exhibition.
      final packagesSnapshot = await _firestore
          .collection('booth_packages')
          .where('exhibitionId', isEqualTo: exhibitionId)
          .get();

      // Add booth package delete operations to batch.
      for (final doc in packagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Get all booth spots related to this exhibition.
      final spotsSnapshot = await _firestore
          .collection('booth_spots')
          .where('exhibitionId', isEqualTo: exhibitionId)
          .get();

      // Add booth spot delete operations to batch.
      for (final doc in spotsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Add main exhibition delete operation to batch.
      final exhibitionRef = _firestore.collection(_collection).doc(exhibitionId);
      batch.delete(exhibitionRef);

      // Commit all delete operations together.
      await batch.commit();

      return true;
    } catch (e) {
      debugPrint('Error deleting exhibition: $e');
      return false;
    }
  }

  Future<bool> updateLayoutDimensions(
    String exhibitionId,
    int rows,
    int columns,
  ) async {
    try {
      // Update floor layout row and column size.
      await _firestore.collection(_collection).doc(exhibitionId).update({
        'layoutRows': rows,
        'layoutColumns': columns,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating layout dimensions: $e');
      return false;
    }
  }

  // Fetch a single exhibition by ID helper.
  Future<ExhibitionModel?> fetchExhibitionById(String exhibitionId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(exhibitionId).get();
      if (!doc.exists) return null;
      return ExhibitionModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error fetching exhibition by ID: $e');
      return null;
    }
  }

  // Safe background trigger to notify admins about new exhibitions created by organizers or admins.
  void _triggerCreateExhibitionNotification(ExhibitionModel exhibition, String exhibitionId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(exhibition.organizerId).get();
      if (!userDoc.exists) return;
      final role = userDoc.data()?['role'] ?? '';
      
      // Only notify admins if created by an Organizer or an Admin.
      if (role != 'Organizer' && role != 'Admin') return;

      final creatorName = userDoc.data()?['name'] ?? 'Someone';

      // If creator is Admin, exclude them from the notification recipients.
      final List<String> excludedUserIds = role == 'Admin' ? [exhibition.organizerId] : [];

      await _notificationService.sendNotificationsToAdmins(
        title: 'New Exhibition Created',
        body: '${exhibition.name} has been created by $creatorName.',
        type: 'admin_exhibition_created',
        relatedId: exhibitionId,
        relatedType: 'exhibition',
        senderName: creatorName,
        excludedUserIds: excludedUserIds,
      );
    } catch (e) {
      debugPrint('Error triggering exhibition created notification: $e');
    }
  }

  // Safe background trigger to notify organizer about their newly created exhibition.
  void _triggerCreateExhibitionSelfNotification(ExhibitionModel exhibition, String exhibitionId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(exhibition.organizerId).get();
      if (!userDoc.exists) return;
      final role = userDoc.data()?['role'] ?? '';
      
      // Do not send self notification if creator is Admin.
      if (role == 'Admin') return;

      final organizerName = userDoc.data()?['name'] ?? 'Organizer';

      await _notificationService.sendNotification(NotificationModel(
        id: '',
        recipientId: exhibition.organizerId,
        title: 'Exhibition Created',
        body: 'Your exhibition ${exhibition.name} has been created successfully.',
        type: 'exhibition_created_self',
        relatedId: exhibitionId,
        relatedType: 'exhibition',
        senderName: organizerName,
      ));
    } catch (e) {
      debugPrint('Error triggering self exhibition created notification: $e');
    }
  }

  // Safe background trigger to notify organizer when their exhibition is published by an admin.
  void _triggerPublishNotification(String exhibitionId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(exhibitionId).get();
      if (!doc.exists) return;
      final data = doc.data();
      final organizerId = data?['organizerId'] ?? '';
      final exhibitionName = data?['name'] ?? 'Exhibition';

      if (organizerId.isEmpty) return;

      // Get publisher/admin name.
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      String publisherName = 'Admin';
      if (currentUid != null) {
        final adminDoc = await _firestore.collection('users').doc(currentUid).get();
        if (adminDoc.exists) {
          publisherName = adminDoc.data()?['name'] ?? 'Admin';
        }
      }

      await _notificationService.sendNotification(NotificationModel(
        id: '',
        recipientId: organizerId,
        title: 'Exhibition Published',
        body: 'Your exhibition $exhibitionName has been published.',
        type: 'exhibition_published',
        relatedId: exhibitionId,
        relatedType: 'exhibition',
        senderName: publisherName,
      ));
    } catch (e) {
      debugPrint('Error triggering publish notification: $e');
    }
  }
}