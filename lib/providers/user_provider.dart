import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _service = UserService();

  // Store all users for admin and organizer lookup.
  List<UserModel> _users = [];

  // Track loading state for UI.
  bool _isLoading = false;

  // Store error message for UI feedback.
  String? _errorMessage;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAllUsers() async {
    // Load all users from Firestore.
    _setLoading(true);
    _errorMessage = null;

    try {
      _users = await _service.fetchAllUsers();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _setLoading(false);
  }

  Future<bool> updateUserActiveStatus(String userId, bool isActive) async {
    // Activate or deactivate user account.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.updateUserActiveStatus(userId, isActive);

      if (success) {
        // Refresh local user list after status update.
        await fetchAllUsers();
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<List<String>?> toggleFavorite({
    required String userId,
    required String exhibitionId,
    required List<String> currentFavorites,
  }) async {
    // Add or remove exhibition from favorites.
    _setLoading(true);
    _errorMessage = null;

    try {
      // Create editable copy of current favorites.
      final List<String> updatedFavorites = List.from(currentFavorites);

      if (updatedFavorites.contains(exhibitionId)) {
        // Remove exhibition if already favorited.
        updatedFavorites.remove(exhibitionId);
      } else {
        // Add exhibition if not favorited yet.
        updatedFavorites.add(exhibitionId);
      }

      // Save updated favorite list to Firestore.
      final success = await _service.updateFavoriteExhibitions(
        userId,
        updatedFavorites,
      );

      _setLoading(false);

      // Return updated list only if Firestore update succeeds.
      return success ? updatedFavorites : null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updateUser(UserModel user) async {
    // Update basic user information.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.updateUser(user);

      if (success) {
        // Refresh user list after update.
        await fetchAllUsers();
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateUserFields(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    // Update specific user profile fields.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.updateUserFields(userId, fields);

      if (success) {
        // Refresh user list after field update.
        await fetchAllUsers();
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    // Update loading state and notify UI.
    _isLoading = value;
    notifyListeners();
  }
}