import 'package:flutter/material.dart';
import '../data/models/booth_model.dart';
import '../data/services/booth_service.dart';

class BoothProvider extends ChangeNotifier {
  final BoothService _service = BoothService();

  List<BoothModel> _boothPackages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BoothModel> get boothPackages => _boothPackages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch booth packages for a specific exhibition.
  Future<void> fetchBoothPackages(String exhibitionId) async {
    _setLoading(true);
    _boothPackages = await _service.fetchBoothPackages(exhibitionId);
    _setLoading(false);
  }

  /// Create a new booth package.
  Future<bool> createBoothPackage(BoothModel booth) async {
    _setLoading(true);
    final success = await _service.createBoothPackage(booth);
    if (success) {
      await fetchBoothPackages(booth.exhibitionId);
    }
    _setLoading(false);
    return success;
  }

  /// Update an existing booth package.
  Future<bool> updateBoothPackage(BoothModel booth) async {
    _setLoading(true);
    final success = await _service.updateBoothPackage(booth);
    if (success) {
      await fetchBoothPackages(booth.exhibitionId);
    }
    _setLoading(false);
    return success;
  }

  /// Delete a booth package.
  Future<bool> deleteBoothPackage(String boothId, String exhibitionId) async {
    _setLoading(true);
    final success = await _service.deleteBoothPackage(boothId, exhibitionId);
    if (success) {
      await fetchBoothPackages(exhibitionId);
    }
    _setLoading(false);
    return success;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
