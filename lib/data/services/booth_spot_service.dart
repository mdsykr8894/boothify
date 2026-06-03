import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booth_spot_model.dart';
import 'exhibition_service.dart';

class BoothSpotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'booth_spots';
  final ExhibitionService _exhibitionService = ExhibitionService();

  Future<List<BoothSpotModel>> fetchBoothSpots(String exhibitionId) async {
    try {
      // Fetch all booth spots for one exhibition.
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('exhibitionId', isEqualTo: exhibitionId)
          .get();

      // Convert Firestore documents into BoothSpotModel list.
      return querySnapshot.docs
          .map((doc) => BoothSpotModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching booth spots: $e');
      return [];
    }
  }

  Future<bool> createBoothSpot(BoothSpotModel spot) async {
    try {
      // Create new booth spot document.
      await _firestore.collection(_collection).add(spot.toMap());

      // Update exhibition timestamp after booth spot change.
      await _exhibitionService.touchExhibition(spot.exhibitionId);

      return true;
    } catch (e) {
      debugPrint('Error creating booth spot: $e');
      return false;
    }
  }

  Future<bool> updateBoothSpot(BoothSpotModel spot) async {
    try {
      // Update existing booth spot document.
      await _firestore
          .collection(_collection)
          .doc(spot.id)
          .update(spot.toMap());

      // Update exhibition timestamp after booth spot change.
      await _exhibitionService.touchExhibition(spot.exhibitionId);

      return true;
    } catch (e) {
      debugPrint('Error updating booth spot: $e');
      return false;
    }
  }

  Future<bool> updateBoothSpotStatus(
    String spotId,
    String status, {
    String? exhibitionId,
  }) async {
    try {
      // Update only booth spot status.
      await _firestore.collection(_collection).doc(spotId).update({
        'status': status,
      });

      // Update exhibition timestamp if exhibition ID is provided.
      if (exhibitionId != null) {
        await _exhibitionService.touchExhibition(exhibitionId);
      }

      return true;
    } catch (e) {
      debugPrint('Error updating booth spot status: $e');
      return false;
    }
  }

  Future<bool> deleteBoothSpot(String spotId, String exhibitionId) async {
    try {
      // Delete booth spot document.
      await _firestore.collection(_collection).doc(spotId).delete();

      // Update exhibition timestamp after booth spot change.
      await _exhibitionService.touchExhibition(exhibitionId);

      return true;
    } catch (e) {
      debugPrint('Error deleting booth spot: $e');
      return false;
    }
  }

  Future<bool> generateBoothLayout({
    required String exhibitionId,
    required String defaultPackageId,
    required int rows,
    required int columns,
  }) async {
    try {
      // Use batch to create many booth spots together.
      final batch = _firestore.batch();
      final collectionRef = _firestore.collection(_collection);

      // Save layout dimensions to exhibition document.
      final exhibitionRef =
          _firestore.collection('exhibitions').doc(exhibitionId);

      batch.update(exhibitionRef, {
        'layoutRows': rows,
        'layoutColumns': columns,
      });

      for (int r = 0; r < rows; r++) {
        // Convert row index into row letter.
        final rowLetter = String.fromCharCode('A'.codeUnitAt(0) + r);

        for (int c = 0; c < columns; c++) {
          // Create booth number such as A01, A02, B01.
          final colNumber = (c + 1).toString().padLeft(2, '0');
          final spotNumber = '$rowLetter$colNumber';

          final docRef = collectionRef.doc();

          final spotMap = {
            'exhibitionId': exhibitionId,
            'boothPackageId': defaultPackageId,
            'spotNumber': spotNumber,
            'status': 'Available',
            'createdAt': FieldValue.serverTimestamp(),
          };

          // Add generated booth spot to batch.
          batch.set(docRef, spotMap);
        }
      }

      // Commit all generated booth spots together.
      await batch.commit();

      // Update exhibition timestamp after layout generation.
      await _exhibitionService.touchExhibition(exhibitionId);

      return true;
    } catch (e) {
      debugPrint('Error generating booth layout: $e');
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
      await _firestore.collection('exhibitions').doc(exhibitionId).update({
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