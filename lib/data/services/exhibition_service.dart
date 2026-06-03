import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/exhibition_model.dart';

class ExhibitionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _collection = 'exhibitions';

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
}