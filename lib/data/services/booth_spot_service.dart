import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booth_spot_model.dart';
import 'exhibition_service.dart';

class BoothSpotService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'booth_spots';
  final ExhibitionService _exhibitionService = ExhibitionService();

  /// Fetch all booth spots for a specific exhibition.
  Future<List<BoothSpotModel>> fetchBoothSpots(String exhibitionId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('exhibitionId', isEqualTo: exhibitionId)
          .get();

      return querySnapshot.docs
          .map((doc) => BoothSpotModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching booth spots: $e');
      return [];
    }
  }

  /// Create a new booth spot.
  Future<bool> createBoothSpot(BoothSpotModel spot) async {
    try {
      await _firestore.collection(_collection).add(spot.toMap());
      await _exhibitionService.touchExhibition(spot.exhibitionId);
      return true;
    } catch (e) {
      debugPrint('Error creating booth spot: $e');
      return false;
    }
  }

  /// Update an existing booth spot.
  Future<bool> updateBoothSpot(BoothSpotModel spot) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(spot.id)
          .update(spot.toMap());
      await _exhibitionService.touchExhibition(spot.exhibitionId);
      return true;
    } catch (e) {
      debugPrint('Error updating booth spot: $e');
      return false;
    }
  }

  /// Update only the status of a booth spot.
  Future<bool> updateBoothSpotStatus(String spotId, String status, {String? exhibitionId}) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(spotId)
          .update({'status': status});
      if (exhibitionId != null) {
        await _exhibitionService.touchExhibition(exhibitionId);
      }
      return true;
    } catch (e) {
      debugPrint('Error updating booth spot status: $e');
      return false;
    }
  }

  /// Delete a booth spot.
  Future<bool> deleteBoothSpot(String spotId, String exhibitionId) async {
    try {
      await _firestore.collection(_collection).doc(spotId).delete();
      await _exhibitionService.touchExhibition(exhibitionId);
      return true;
    } catch (e) {
      debugPrint('Error deleting booth spot: $e');
      return false;
    }
  }

  /// Generate multiple booth spots in a grid layout using standard Firestore batch writes.
  Future<bool> generateBoothLayout({
    required String exhibitionId,
    required String defaultPackageId,
    required int rows,
    required int columns,
  }) async {
    try {
      final batch = _firestore.batch();
      final collectionRef = _firestore.collection(_collection);

      // Save initial layout dimensions to the exhibition document
      final exhibitionRef = _firestore.collection('exhibitions').doc(exhibitionId);
      batch.update(exhibitionRef, {
        'layoutRows': rows,
        'layoutColumns': columns,
      });

      for (int r = 0; r < rows; r++) {
        final rowLetter = String.fromCharCode('A'.codeUnitAt(0) + r);
        for (int c = 0; c < columns; c++) {
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
          batch.set(docRef, spotMap);
        }
      }

      await batch.commit();
      await _exhibitionService.touchExhibition(exhibitionId);
      return true;
    } catch (e) {
      debugPrint('Error generating booth layout: $e');
      return false;
    }
  }

  /// Update floor plan layout bounds (rows and columns).
  Future<bool> updateLayoutDimensions(String exhibitionId, int rows, int columns) async {
    try {
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
