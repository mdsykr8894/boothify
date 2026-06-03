import 'package:flutter/material.dart';
import '../data/models/booth_model.dart';
import '../data/services/booth_service.dart';

class BoothProvider extends ChangeNotifier {
  final BoothService _service = BoothService();

  // Store booth packages for selected exhibition.
  List<BoothModel> _boothPackages = [];

  // Track loading state for UI.
  bool _isLoading = false;

  // Store error message for UI feedback.
  String? _errorMessage;

  List<BoothModel> get boothPackages => _boothPackages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBoothPackages(String exhibitionId) async {
    // Load booth packages for one exhibition.
    _setLoading(true);
    _errorMessage = null;

    try {
      _boothPackages = await _service.fetchBoothPackages(exhibitionId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _setLoading(false);
  }

  Future<bool> createBoothPackage(BoothModel booth) async {
    // Create new booth package.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.createBoothPackage(booth);

      if (success) {
        // Refresh booth packages after creating.
        await fetchBoothPackages(booth.exhibitionId);
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateBoothPackage(BoothModel booth) async {
    // Update existing booth package.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.updateBoothPackage(booth);

      if (success) {
        // Refresh booth packages after updating.
        await fetchBoothPackages(booth.exhibitionId);
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteBoothPackage(String boothId, String exhibitionId) async {
    // Delete booth package from selected exhibition.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.deleteBoothPackage(boothId, exhibitionId);

      if (success) {
        // Refresh booth packages after deleting.
        await fetchBoothPackages(exhibitionId);
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