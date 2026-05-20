import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _service = UserService();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch all users.
  Future<void> fetchAllUsers() async {
    _setLoading(true);
    _users = await _service.fetchAllUsers();
    _setLoading(false);
  }

  /// Update user active status.
  Future<bool> updateUserActiveStatus(String userId, bool isActive) async {
    _setLoading(true);
    final success = await _service.updateUserActiveStatus(userId, isActive);
    if (success) {
      // Refresh local list
      await fetchAllUsers();
    }
    _setLoading(false);
    return success;
  }

  /// Toggle an exhibition in the user's favorites list.
  Future<List<String>?> toggleFavorite({
    required String userId,
    required String exhibitionId,
    required List<String> currentFavorites,
  }) async {
    _setLoading(true);
    final List<String> updatedFavorites = List.from(currentFavorites);
    
    if (updatedFavorites.contains(exhibitionId)) {
      updatedFavorites.remove(exhibitionId);
    } else {
      updatedFavorites.add(exhibitionId);
    }

    final success = await _service.updateFavoriteExhibitions(userId, updatedFavorites);
    _setLoading(false);
    
    return success ? updatedFavorites : null;
  }

  /// Update user information.
  Future<bool> updateUser(UserModel user) async {
    _setLoading(true);
    final success = await _service.updateUser(user);
    if (success) {
      await fetchAllUsers();
    }
    _setLoading(false);
    return success;
  }

  /// Update granular user fields.
  Future<bool> updateUserFields(String userId, Map<String, dynamic> fields) async {
    _setLoading(true);
    final success = await _service.updateUserFields(userId, fields);
    if (success) {
      await fetchAllUsers();
    }
    _setLoading(false);
    return success;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
