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
    final aDate = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }

  /// Fetch all published exhibitions.
  Future<List<ExhibitionModel>> fetchPublishedExhibitions() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isPublished', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ExhibitionModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching published exhibitions: $e');
      return [];
    }
  }

  /// Fetch exhibitions owned by a specific organizer.
  Future<List<ExhibitionModel>> fetchOrganizerExhibitions(String organizerId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('organizerId', isEqualTo: organizerId)
          .get();

      final list = querySnapshot.docs
          .map((doc) => ExhibitionModel.fromMap(doc.data(), doc.id))
          .toList();

      list.sort(_compareByUpdatedOrCreated);
      return list;
    } catch (e) {
      debugPrint('Error fetching organizer exhibitions: $e');
      return [];
    }
  }

  /// Fetch all exhibitions for admin.
  Future<List<ExhibitionModel>> fetchAllExhibitions() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();

      final list = querySnapshot.docs
          .map((doc) => ExhibitionModel.fromMap(doc.data(), doc.id))
          .toList();

      list.sort(_compareByUpdatedOrCreated);
      return list;
    } catch (e) {
      debugPrint('Error fetching all exhibitions: $e');
      return [];
    }
  }

  /// Create a new exhibition.
  Future<String?> createExhibition(ExhibitionModel exhibition) async {
    try {
      final docRef = await _firestore.collection(_collection).add(exhibition.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating exhibition: $e');
      return null;
    }
  }

  /// Upload exhibition images to Firebase Storage.
  Future<List<String>> uploadExhibitionImages({
    required String exhibitionId,
    required List<XFile> images,
  }) async {
    final List<String> downloadUrls = [];

    for (int i = 0; i < images.length && i < 4; i++) {
      try {
        final image = images[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final ref = _storage
            .ref()
            .child('exhibitions/$exhibitionId/images/${timestamp}_$i.jpg');

        final bytes = await image.readAsBytes();
        
        final uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        
        final snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        downloadUrls.add(url);
      } catch (e) {
        debugPrint('Error uploading image $i: $e');
        throw Exception('Failed to upload image: $e');
      }
    }
    return downloadUrls;
  }

  /// Update only the image URLs of an exhibition.
  Future<bool> updateExhibitionImageUrls(String exhibitionId, List<String> imageUrls) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(exhibitionId)
          .update({
            'imageUrls': imageUrls,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      debugPrint('Error updating exhibition image URLs: $e');
      return false;
    }
  }

  /// Update an existing exhibition.
  Future<bool> updateExhibition(ExhibitionModel exhibition) async {
    try {
      final updatedModel = exhibition.copyWith(updatedAt: DateTime.now());
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

  /// Toggle the isPublished status of an exhibition.
  Future<bool> togglePublish(String exhibitionId, bool isPublished) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(exhibitionId)
          .update({
            'isPublished': isPublished,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      debugPrint('Error toggling publish status: $e');
      return false;
    }
  }

  /// Toggle the isBookingOpen status of an exhibition.
  Future<bool> toggleBookingOpen(String exhibitionId, bool isBookingOpen) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(exhibitionId)
          .update({
            'isBookingOpen': isBookingOpen,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      return true;
    } catch (e) {
      debugPrint('Error toggling booking status: $e');
      return false;
    }
  }

  /// Touch the exhibition's updatedAt timestamp.
  Future<void> touchExhibition(String exhibitionId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(exhibitionId)
          .update({'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error touching exhibition: $e');
    }
  }

  /// Delete an exhibition and all related booth packages and spots.
  Future<bool> deleteExhibition(String exhibitionId) async {
    try {
      final batch = _firestore.batch();

      // 1. Get all related booth packages
      final packagesSnapshot = await _firestore
          .collection('booth_packages')
          .where('exhibitionId', isEqualTo: exhibitionId)
          .get();
      for (final doc in packagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 2. Get all related booth spots
      final spotsSnapshot = await _firestore
          .collection('booth_spots')
          .where('exhibitionId', isEqualTo: exhibitionId)
          .get();
      for (final doc in spotsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 3. Delete the main exhibition document
      final exhibitionRef = _firestore.collection(_collection).doc(exhibitionId);
      batch.delete(exhibitionRef);

      // Commit the batch
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error deleting exhibition: $e');
      return false;
    }
  }

  /// Update floor plan layout bounds (rows and columns).
  Future<bool> updateLayoutDimensions(String exhibitionId, int rows, int columns) async {
    try {
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
