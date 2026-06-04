import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/exhibition_model.dart';
import '../data/services/exhibition_service.dart';
import '../data/services/booth_spot_service.dart';

class ExhibitionProvider extends ChangeNotifier {
  final ExhibitionService _service = ExhibitionService();

  // Store published exhibitions for public/exhibitor explore screen.
  List<ExhibitionModel> _publishedExhibitions = [];

  // Store exhibitions created by one organizer.
  List<ExhibitionModel> _organizerExhibitions = [];

  // Store all exhibitions for admin view.
  List<ExhibitionModel> _allExhibitions = [];

  // Track loading state for UI.
  bool _isLoading = false;

  // Store error message for UI feedback.
  String? _errorMessage;

  List<ExhibitionModel> get publishedExhibitions => _publishedExhibitions;
  List<ExhibitionModel> get organizerExhibitions => _organizerExhibitions;
  List<ExhibitionModel> get allExhibitions => _allExhibitions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Return published exhibitions that are not completed.
  List<ExhibitionModel> get visibleExploreExhibitions {
    return _publishedExhibitions.where((e) => e.shouldShowInExplore).toList();
  }

  Future<void> fetchPublishedExhibitions() async {
    // Load published exhibitions for explore screen.
    _setLoading(true);
    _errorMessage = null;

    try {
      _publishedExhibitions = await _service.fetchPublishedExhibitions();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _setLoading(false);
  }

  Future<void> fetchOrganizerExhibitions(String organizerId) async {
    // Load exhibitions created by selected organizer.
    _setLoading(true);
    _errorMessage = null;

    try {
      _organizerExhibitions =
          await _service.fetchOrganizerExhibitions(organizerId);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _setLoading(false);
  }

  Future<void> fetchAllExhibitions() async {
    // Load all exhibitions for admin.
    _setLoading(true);
    _errorMessage = null;

    try {
      _allExhibitions = await _service.fetchAllExhibitions();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _setLoading(false);
  }

  Future<bool> createExhibition(
    ExhibitionModel exhibition, {
    List<XFile>? selectedImages,
  }) async {
    // Start loading while creating exhibition.
    _setLoading(true);
    _errorMessage = null;

    try {
      // Create exhibition document first.
      final docId = await _service.createExhibition(exhibition);

      if (docId == null) {
        _errorMessage = 'Failed to create exhibition in database.';
        _setLoading(false);
        return false;
      }

      // Upload images if organizer selected photos.
      if (selectedImages != null && selectedImages.isNotEmpty) {
        try {
          final urls = await _service.uploadExhibitionImages(
            exhibitionId: docId,
            images: selectedImages,
          );

          // Save uploaded image URLs back to exhibition document.
          if (urls.isNotEmpty) {
            final success =
                await _service.updateExhibitionImageUrls(docId, urls);

            if (!success) {
              _errorMessage =
                  'Event created, but image URLs failed to persist in database.';
            }
          }
        } catch (e) {
          debugPrint('Image upload failed: $e');
          _errorMessage =
              'Event created, but image upload failed. Please try adding photos again.';
        }
      }

      // Refresh all exhibition lists after creation.
      await _refreshAllLists(exhibition.organizerId);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateExhibition(ExhibitionModel exhibition) async {
    // Update existing exhibition data.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.updateExhibition(exhibition);

      if (success) {
        // Refresh lists after update.
        await _refreshAllLists(exhibition.organizerId);
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> togglePublish(
    String exhibitionId,
    bool isPublished,
    String organizerId,
  ) async {
    // Update publish status.
    _setLoading(true);
    _errorMessage = null;

    try {
      if (isPublished) {
        final spots = await BoothSpotService().fetchBoothSpots(exhibitionId);
        if (spots.isEmpty) {
          _errorMessage = 'Please create a floor plan before publishing this exhibition.';
          _setLoading(false);
          return false;
        }
        
        final assignedSpots = spots.where((s) => s.boothPackageId.trim().isNotEmpty).toList();
        if (assignedSpots.isEmpty) {
          _errorMessage = 'Please assign at least one booth package before publishing this exhibition.';
          _setLoading(false);
          return false;
        }
      }

      final success = await _service.togglePublish(
        exhibitionId,
        isPublished,
      );

      if (success) {
        // Refresh lists after publish status changes.
        await _refreshAllLists(organizerId);
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> toggleBookingOpen(
    String exhibitionId,
    bool isBookingOpen,
    String organizerId,
  ) async {
    // Update booking open or closed status.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.toggleBookingOpen(
        exhibitionId,
        isBookingOpen,
      );

      if (success) {
        // Refresh lists after booking status changes.
        await _refreshAllLists(organizerId);
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteExhibition(String exhibitionId, String organizerId) async {
    // Delete exhibition and related data.
    _setLoading(true);
    _errorMessage = null;

    try {
      final success = await _service.deleteExhibition(exhibitionId);

      if (success) {
        // Refresh lists after deletion.
        await _refreshAllLists(organizerId);
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<void> _refreshAllLists(String organizerId) async {
    // Refresh public, organizer, and admin exhibition lists.
    await Future.wait([
      _service.fetchPublishedExhibitions().then(
            (list) => _publishedExhibitions = list,
          ),
      _service.fetchOrganizerExhibitions(organizerId).then(
            (list) => _organizerExhibitions = list,
          ),
      _service.fetchAllExhibitions().then(
            (list) => _allExhibitions = list,
          ),
    ]);
  }

  void _setLoading(bool value) {
    // Update loading state and notify UI.
    _isLoading = value;
    notifyListeners();
  }
}