import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  /// Fetch all users from Firestore.
  Future<List<UserModel>> fetchAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching all users: $e');
      return [];
    }
  }

  /// Update the active status of a user.
  Future<bool> updateUserActiveStatus(String userId, bool isActive) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .update({'isActive': isActive});
      return true;
    } catch (e) {
      debugPrint('Error updating user active status: $e');
      return false;
    }
  }

  /// Update the favorite exhibitions list for a user.
  Future<bool> updateFavoriteExhibitions(String userId, List<String> favoriteIds) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(userId)
          .update({'favoriteExhibitionIds': favoriteIds});
      return true;
    } catch (e) {
      debugPrint('Error updating favorite exhibitions: $e');
      return false;
    }
  }

  /// Update user information (name and role).
  Future<bool> updateUser(UserModel user) async {
    try {
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

  /// Update granular user profile fields in Firestore.
  Future<bool> updateUserFields(String userId, Map<String, dynamic> fields) async {
    try {
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
