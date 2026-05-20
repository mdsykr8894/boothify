import 'package:flutter/material.dart';
import '../data/models/application_model.dart';
import '../data/services/application_service.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApplicationService _service = ApplicationService();

  List<ApplicationModel> _userApplications = [];
  List<ApplicationModel> _organizerApplications = [];
  List<ApplicationModel> _allApplications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ApplicationModel> get userApplications => _userApplications;
  List<ApplicationModel> get organizerApplications => _organizerApplications;
  List<ApplicationModel> get allApplications => _allApplications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Submit a new booth application.
  Future<bool> submitApplication(ApplicationModel application) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.submitApplication(application);
      if (success) {
        await fetchUserApplications(application.userId);
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch applications for a specific user.
  Future<void> fetchUserApplications(String userId) async {
    _setLoading(true);
    _userApplications = await _service.fetchUserApplications(userId);
    _setLoading(false);
  }

  /// Fetch applications for a specific organizer.
  Future<void> fetchOrganizerApplications(String organizerId) async {
    _setLoading(true);
    _organizerApplications = await _service.fetchOrganizerApplications(organizerId);
    _setLoading(false);
  }

  /// Fetch all applications for Admin.
  Future<void> fetchAllApplications() async {
    _setLoading(true);
    _allApplications = await _service.fetchAllApplications();
    _setLoading(false);
  }

  /// Update application status.
  Future<bool> updateApplicationStatus({
    required String applicationId,
    required String boothSpotId,
    required String status,
    String? rejectReason,
    String? organizerId,
  }) async {
    _setLoading(true);
    final success = await _service.updateApplicationStatus(
      applicationId: applicationId,
      boothSpotId: boothSpotId,
      status: status,
      rejectReason: rejectReason,
    );

    if (success) {
      // Refresh relevant lists
      if (organizerId != null) {
        await fetchOrganizerApplications(organizerId);
      }
      await fetchAllApplications();
    }
    _setLoading(false);
    return success;
  }

  /// Update application details.
  Future<bool> updateApplication(ApplicationModel application) async {
    _setLoading(true);
    final success = await _service.updateApplication(application);
    if (success) {
      // Refresh all lists to ensure consistency
      await fetchUserApplications(application.userId);
      await fetchAllApplications();
      // Note: Organizer list will be refreshed next time it's opened or through other triggers
    }
    _setLoading(false);
    return success;
  }

  /// Process simulated payment for an approved application.
  Future<bool> makePayment({
    required String applicationId,
    required String userId,
    required String paymentMethod,
    required String transactionId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _service.makePayment(
        applicationId: applicationId,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      if (success) {
        await fetchUserApplications(userId);
        await fetchAllApplications();
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
