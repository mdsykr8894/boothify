import 'package:flutter/material.dart';
import '../data/models/booth_spot_model.dart';
import '../data/services/booth_spot_service.dart';

class BoothSpotProvider extends ChangeNotifier {
  final BoothSpotService _service = BoothSpotService();

  List<BoothSpotModel> _boothSpots = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BoothSpotModel> get boothSpots => _boothSpots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getters for filtered spots
  List<BoothSpotModel> get availableSpots =>
      _boothSpots.where((s) => s.status == 'Available').toList();
  List<BoothSpotModel> get pendingSpots =>
      _boothSpots.where((s) => s.status == 'Pending').toList();
  List<BoothSpotModel> get bookedSpots =>
      _boothSpots.where((s) => s.status == 'Booked').toList();

  /// Fetch booth spots for a specific exhibition.
  Future<void> fetchBoothSpots(String exhibitionId) async {
    _setLoading(true);
    final spots = await _service.fetchBoothSpots(exhibitionId);
    spots.sort((a, b) => a.spotNumber.compareTo(b.spotNumber));
    _boothSpots = spots;
    _setLoading(false);
  }

  /// Create a new booth spot.
  Future<bool> createBoothSpot(BoothSpotModel spot) async {
    _setLoading(true);
    final success = await _service.createBoothSpot(spot);
    if (success) {
      await fetchBoothSpots(spot.exhibitionId);
    }
    _setLoading(false);
    return success;
  }

  /// Update an existing booth spot.
  Future<bool> updateBoothSpot(BoothSpotModel spot) async {
    _setLoading(true);
    final success = await _service.updateBoothSpot(spot);
    if (success) {
      await fetchBoothSpots(spot.exhibitionId);
    }
    _setLoading(false);
    return success;
  }

  /// Update the status of a booth spot.
  Future<bool> updateBoothSpotStatus(String spotId, String status, String exhibitionId) async {
    _setLoading(true);
    final success = await _service.updateBoothSpotStatus(spotId, status, exhibitionId: exhibitionId);
    if (success) {
      await fetchBoothSpots(exhibitionId);
    }
    _setLoading(false);
    return success;
  }

  /// Delete a booth spot.
  Future<bool> deleteBoothSpot(String spotId, String exhibitionId) async {
    _setLoading(true);
    final success = await _service.deleteBoothSpot(spotId, exhibitionId);
    if (success) {
      await fetchBoothSpots(exhibitionId);
    }
    _setLoading(false);
    return success;
  }

  /// Generate multiple booth spots in a grid layout.
  Future<bool> generateBoothLayout({
    required String exhibitionId,
    required String defaultPackageId,
    required int rows,
    required int columns,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    final success = await _service.generateBoothLayout(
      exhibitionId: exhibitionId,
      defaultPackageId: defaultPackageId,
      rows: rows,
      columns: columns,
    );
    if (success) {
      await fetchBoothSpots(exhibitionId);
    } else {
      _errorMessage = 'Failed to generate layout in database';
    }
    _setLoading(false);
    return success;
  }

  /// Update floor plan layout bounds (rows and columns).
  Future<bool> updateLayoutDimensions(String exhibitionId, int rows, int columns) async {
    _setLoading(true);
    _errorMessage = null;
    final success = await _service.updateLayoutDimensions(exhibitionId, rows, columns);
    if (success) {
      await fetchBoothSpots(exhibitionId);
    } else {
      _errorMessage = 'Failed to update layout dimensions in database';
    }
    _setLoading(false);
    return success;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
