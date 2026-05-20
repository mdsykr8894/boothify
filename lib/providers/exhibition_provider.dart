import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/models/exhibition_model.dart';
import '../data/services/exhibition_service.dart';

class ExhibitionProvider extends ChangeNotifier {
  final ExhibitionService _service = ExhibitionService();

  List<ExhibitionModel> _publishedExhibitions = [];
  List<ExhibitionModel> _organizerExhibitions = [];
  List<ExhibitionModel> _allExhibitions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ExhibitionModel> get publishedExhibitions => _publishedExhibitions;
  List<ExhibitionModel> get organizerExhibitions => _organizerExhibitions;
  List<ExhibitionModel> get allExhibitions => _allExhibitions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns only published exhibitions that are not yet completed.
  List<ExhibitionModel> get visibleExploreExhibitions {
    return _publishedExhibitions.where((e) => e.shouldShowInExplore).toList();
  }

  /// Fetch all published exhibitions.
  Future<void> fetchPublishedExhibitions() async {
    _setLoading(true);
    _publishedExhibitions = await _service.fetchPublishedExhibitions();
    _setLoading(false);
  }

  /// Fetch exhibitions for a specific organizer.
  Future<void> fetchOrganizerExhibitions(String organizerId) async {
    _setLoading(true);
    _organizerExhibitions = await _service.fetchOrganizerExhibitions(organizerId);
    _setLoading(false);
  }

  /// Fetch all exhibitions for admin.
  Future<void> fetchAllExhibitions() async {
    _setLoading(true);
    _allExhibitions = await _service.fetchAllExhibitions();
    _setLoading(false);
  }

  /// Create a new exhibition.
  Future<bool> createExhibition(ExhibitionModel exhibition, {List<XFile>? selectedImages}) async {
    _setLoading(true);
    _errorMessage = null;
    final docId = await _service.createExhibition(exhibition);
    if (docId == null) {
      _errorMessage = 'Failed to create exhibition in database.';
      _setLoading(false);
      return false;
    }

    if (selectedImages != null && selectedImages.isNotEmpty) {
      try {
        final urls = await _service.uploadExhibitionImages(
          exhibitionId: docId,
          images: selectedImages,
        );
        if (urls.isNotEmpty) {
          final success = await _service.updateExhibitionImageUrls(docId, urls);
          if (!success) {
            _errorMessage = 'Event created, but image URLs failed to persist in database.';
          }
        }
      } catch (e) {
        debugPrint('Image upload failed: $e');
        _errorMessage = 'Event created, but image upload failed. Please try adding photos again.';
      }
    }

    await _refreshAllLists(exhibition.organizerId);
    _setLoading(false);
    return true;
  }

  /// Update an existing exhibition.
  Future<bool> updateExhibition(ExhibitionModel exhibition) async {
    _setLoading(true);
    final success = await _service.updateExhibition(exhibition);
    if (success) {
      await _refreshAllLists(exhibition.organizerId);
    }
    _setLoading(false);
    return success;
  }

  /// Toggle publish status.
  Future<bool> togglePublish(String exhibitionId, bool isPublished, String organizerId) async {
    _setLoading(true);
    final success = await _service.togglePublish(exhibitionId, isPublished);
    if (success) {
      await _refreshAllLists(organizerId);
    }
    _setLoading(false);
    return success;
  }

  /// Toggle booking open status.
  Future<bool> toggleBookingOpen(String exhibitionId, bool isBookingOpen, String organizerId) async {
    _setLoading(true);
    final success = await _service.toggleBookingOpen(exhibitionId, isBookingOpen);
    if (success) {
      await _refreshAllLists(organizerId);
    }
    _setLoading(false);
    return success;
  }

  /// Delete an exhibition.
  Future<bool> deleteExhibition(String exhibitionId, String organizerId) async {
    _setLoading(true);
    final success = await _service.deleteExhibition(exhibitionId);
    if (success) {
      await _refreshAllLists(organizerId);
    }
    _setLoading(false);
    return success;
  }

  /// Refresh all local lists.
  Future<void> _refreshAllLists(String organizerId) async {
    await Future.wait([
      _service.fetchPublishedExhibitions().then((list) => _publishedExhibitions = list),
      _service.fetchOrganizerExhibitions(organizerId).then((list) => _organizerExhibitions = list),
      _service.fetchAllExhibitions().then((list) => _allExhibitions = list),
    ]);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
