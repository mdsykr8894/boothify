import 'package:flutter/material.dart';
import '../data/models/user_model.dart';
import '../data/services/auth_service.dart';
import '../data/services/user_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  String? get role => _currentUser?.role;

  /// Load current user data on app start or login change.
  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.getCurrentUserData();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Sign in user and update state.
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.signIn(email, password);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register user and update state.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? companyName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        companyName: companyName,
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out and clear state.
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Update the current user's favorites list locally.
  void updateFavorites(List<String> favoriteIds) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(favoriteExhibitionIds: favoriteIds);
      notifyListeners();
    }
  }

  /// Update specific fields of the current logged-in user's profile.
  Future<bool> updatePersonalInformation(Map<String, dynamic> fields) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final success = await UserService().updateUserFields(_currentUser!.uid, fields);
      if (success) {
        _currentUser = _currentUser!.copyWith(
          name: fields['name'] ?? _currentUser!.name,
          email: fields['email'] ?? _currentUser!.email,
          preferredName: fields['preferredName'] ?? _currentUser!.preferredName,
          phoneNumber: fields['phoneNumber'] ?? _currentUser!.phoneNumber,
          residentialAddress: fields['residentialAddress'] ?? _currentUser!.residentialAddress,
          postalAddress: fields['postalAddress'] ?? _currentUser!.postalAddress,
          emergencyContact: fields['emergencyContact'] ?? _currentUser!.emergencyContact,
          contactEmail: fields['contactEmail'] ?? _currentUser!.contactEmail,
          isVerified: fields['isVerified'] ?? _currentUser!.isVerified,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
