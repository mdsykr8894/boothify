import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booth_model.dart';
import 'exhibition_service.dart';

class BoothService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'booth_packages';
  final ExhibitionService _exhibitionService = ExhibitionService();

  /// Fetch all booth packages for a specific exhibition.
  Future<List<BoothModel>> fetchBoothPackages(String exhibitionId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('exhibitionId', isEqualTo: exhibitionId)
          .get();

      return querySnapshot.docs
          .map((doc) => BoothModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching booth packages: $e');
      return [];
    }
  }

  /// Create a new booth package.
  Future<bool> createBoothPackage(BoothModel booth) async {
    try {
      await _firestore.collection(_collection).add(booth.toMap());
      await _exhibitionService.touchExhibition(booth.exhibitionId);
      return true;
    } catch (e) {
      debugPrint('Error creating booth package: $e');
      return false;
    }
  }

  /// Update an existing booth package.
  Future<bool> updateBoothPackage(BoothModel booth) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(booth.id)
          .update(booth.toMap());
      await _exhibitionService.touchExhibition(booth.exhibitionId);
      return true;
    } catch (e) {
      debugPrint('Error updating booth package: $e');
      return false;
    }
  }

  /// Delete a booth package.
  Future<bool> deleteBoothPackage(String boothId, String exhibitionId) async {
    try {
      await _firestore.collection(_collection).doc(boothId).delete();
      await _exhibitionService.touchExhibition(exhibitionId);
      return true;
    } catch (e) {
      debugPrint('Error deleting booth package: $e');
      return false;
    }
  }
}
