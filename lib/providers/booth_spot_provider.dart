import 'package:flutter/material.dart';
import '../data/models/booth_spot_model.dart';
import '../data/services/booth_spot_service.dart';

class BoothSpotProvider extends ChangeNotifier {
  final BoothSpotService _service = BoothSpotService();

  // Store booth spots for selected exhibition.
  List<BoothSpotModel> _boothSpots = [];

  // Track loading state for UI.
  bool _isLoading = false;

  // Store error message for UI feedback.
  String? _errorMessage;

  List<BoothSpotModel> get boothSpots => _boothSpots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get available booth spots only.
  List<BoothSpotModel> get availableSpots =>
      _boothSpots.where((s) => s.status == 'Available').toList();

  // Get pending booth spots only.
  List<BoothSpotModel> get pendingSpots =>
      _boothSpots.where((s) => s.status == 'Pending').toList();

  // Get booked booth spots only.
  List<BoothSpotModel> get bookedSpots =>
      _boothSpots.where((s) => s.status == 'Booked').toList();

  Future<void> fetchBoothSpots(String exhibitionId) async {
    // Load booth spots for one exhibition.
    _setLoading(true);
    _errorMessage = null;

    try {
      final spots = await _service.fetchBoothSpots(exhibitionId);

      // Sort spots by booth number for stable layout display.
      spots.sort((a, b) => a.spotNumber.compareTo(b.spotNumber));

      _boothSpots = spots;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _setLoading(false);
  }

  Future<bool> createBoothSpot(BoothSpotModel spot) async {
    // Create new booth spot.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.createBoothSpot(spot);

      if (success) {
        // Refresh booth spots after creating.
        await fetchBoothSpots(spot.exhibitionId);
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateBoothSpot(BoothSpotModel spot) async {
    // Update existing booth spot.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.updateBoothSpot(spot);

      if (success) {
        // Refresh booth spots after updating.
        await fetchBoothSpots(spot.exhibitionId);
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateBoothSpotStatus(
    String spotId,
    String status,
    String exhibitionId,
  ) async {
    // Update booth spot status only.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.updateBoothSpotStatus(
        spotId,
        status,
        exhibitionId: exhibitionId,
      );

      if (success) {
        // Refresh booth spots after status update.
        await fetchBoothSpots(exhibitionId);
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteBoothSpot(String spotId, String exhibitionId) async {
    // Delete booth spot from selected exhibition.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.deleteBoothSpot(spotId, exhibitionId);

      if (success) {
        // Refresh booth spots after deleting.
        await fetchBoothSpots(exhibitionId);
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> generateBoothLayout({
    required String exhibitionId,
    required String defaultPackageId,
    required int rows,
    required int columns,
  }) async {
    // Generate booth spots automatically in grid layout.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.generateBoothLayout(
        exhibitionId: exhibitionId,
        defaultPackageId: defaultPackageId,
        rows: rows,
        columns: columns,
      );

      if (success) {
        // Refresh booth spots after layout generation.
        await fetchBoothSpots(exhibitionId);
      } else {
        _errorMessage = 'Failed to generate layout in database';
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateLayoutDimensions(
    String exhibitionId,
    int rows,
    int columns,
  ) async {
    // Update saved floor layout size.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.updateLayoutDimensions(
        exhibitionId,
        rows,
        columns,
      );

      if (success) {
        // Refresh booth spots after layout dimension update.
        await fetchBoothSpots(exhibitionId);
      } else {
        _errorMessage = 'Failed to update layout dimensions in database';
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