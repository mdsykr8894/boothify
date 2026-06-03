import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/booth_model.dart';
import 'exhibition_service.dart';

class BoothService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'booth_packages';
  final ExhibitionService _exhibitionService = ExhibitionService();

  Future<List<BoothModel>> fetchBoothPackages(String exhibitionId) async {
    try {
      // Fetch booth packages for one exhibition.
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('exhibitionId', isEqualTo: exhibitionId)
          .get();

      // Convert Firestore documents into BoothModel list.
      return querySnapshot.docs
          .map((doc) => BoothModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching booth packages: $e');
      return [];
    }
  }

  Future<bool> createBoothPackage(BoothModel booth) async {
    try {
      // Create new booth package document.
      await _firestore.collection(_collection).add(booth.toMap());

      // Update exhibition timestamp after package change.
      await _exhibitionService.touchExhibition(booth.exhibitionId);

      return true;
    } catch (e) {
      debugPrint('Error creating booth package: $e');
      return false;
    }
  }

  Future<bool> updateBoothPackage(BoothModel booth) async {
    try {
      // Update existing booth package document.
      await _firestore
          .collection(_collection)
          .doc(booth.id)
          .update(booth.toMap());

      // Update exhibition timestamp after package change.
      await _exhibitionService.touchExhibition(booth.exhibitionId);

      return true;
    } catch (e) {
      debugPrint('Error updating booth package: $e');
      return false;
    }
  }

  Future<bool> deleteBoothPackage(String boothId, String exhibitionId) async {
    try {
      // Delete booth package document.
      await _firestore.collection(_collection).doc(boothId).delete();

      // Update exhibition timestamp after package change.
      await _exhibitionService.touchExhibition(exhibitionId);

      return true;
    } catch (e) {
      debugPrint('Error deleting booth package: $e');
      return false;
    }
  }
}