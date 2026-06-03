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

  Future<void> loadCurrentUser() async {
    // Start loading while checking saved login session.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Load current Firebase user data from Firestore.
      _currentUser = await _authService.getCurrentUserData();
    } catch (e) {
      // Store error message if user loading fails.
      _errorMessage = e.toString();
    } finally {
      // Mark auth checking as completed.
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    // Start loading while signing in.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sign in and store logged-in user data.
      _currentUser = await _authService.signIn(email, password);

      // Return true only if user data is available.
      return _currentUser != null;
    } catch (e) {
      // Store cleaned error message for UI display.
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      // Stop loading after sign in process ends.
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? companyName,
  }) async {
    // Start loading while creating account.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Register user and store new user data.
      _currentUser = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        companyName: companyName,
      );

      // Return true only if user data is available.
      return _currentUser != null;
    } catch (e) {
      // Store cleaned error message for UI display.
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      // Stop loading after registration process ends.
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    // Sign out from Firebase.
    await _authService.signOut();

    // Clear local user state.
    _currentUser = null;
    notifyListeners();
  }

  void updateFavorites(List<String> favoriteIds) {
    // Update favorite exhibitions in local user state.
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(favoriteExhibitionIds: favoriteIds);
      notifyListeners();
    }
  }

  Future<bool> updatePersonalInformation(Map<String, dynamic> fields) async {
    // Prevent update if no user is logged in.
    if (_currentUser == null) return false;

    // Start loading while updating profile.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Update user fields in Firestore.
      final success = await UserService().updateUserFields(
        _currentUser!.uid,
        fields,
      );

      if (success) {
        // Update local user data after Firestore update succeeds.
        _currentUser = _currentUser!.copyWith(
          name: fields['name'] ?? _currentUser!.name,
          email: fields['email'] ?? _currentUser!.email,
          preferredName: fields['preferredName'] ?? _currentUser!.preferredName,
          phoneNumber: fields['phoneNumber'] ?? _currentUser!.phoneNumber,
          residentialAddress:
              fields['residentialAddress'] ?? _currentUser!.residentialAddress,
          postalAddress: fields['postalAddress'] ?? _currentUser!.postalAddress,
          emergencyContact:
              fields['emergencyContact'] ?? _currentUser!.emergencyContact,
          contactEmail: fields['contactEmail'] ?? _currentUser!.contactEmail,
          isVerified: fields['isVerified'] ?? _currentUser!.isVerified,
          updatedAt: DateTime.now(),
        );

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      // Store update error message.
      _errorMessage = e.toString();
      return false;
    } finally {
      // Stop loading after update process ends.
      _isLoading = false;
      notifyListeners();
    }
  }
}