import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  Future<List<UserModel>> fetchAllUsers() async {
    try {
      // Fetch all users ordered by newest account first.
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      // Convert Firestore documents into UserModel list.
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }

  Future<bool> updateUserActiveStatus(String userId, bool isActive) async {
    try {
      // Update whether user account is active or deactivated.
      await _firestore.collection(_collection).doc(userId).update({
        'isActive': isActive,
      });

      return true;
    } catch (e) {
      debugPrint('Error updating user active status: $e');
      return false;
    }
  }

  Future<bool> updateFavoriteExhibitions(
    String userId,
    List<String> favoriteIds,
  ) async {
    try {
      // Save user's favorite exhibition IDs.
      await _firestore.collection(_collection).doc(userId).update({
        'favoriteExhibitionIds': favoriteIds,
      });

      return true;
    } catch (e) {
      debugPrint('Error updating favorite exhibitions: $e');
      return false;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    try {
      // Update basic user fields.
      await _firestore.collection(_collection).doc(user.uid).update({
        'name': user.name,
        'role': user.role,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  Future<bool> updateUserFields(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
      // Update selected user profile fields.
      await _firestore.collection(_collection).doc(userId).update({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating user fields: $e');
      return false;
    }
  }
}