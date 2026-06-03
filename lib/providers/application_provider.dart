import 'package:flutter/material.dart';
import '../data/models/application_model.dart';
import '../data/services/application_service.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApplicationService _service = ApplicationService();

  // Store applications submitted by current exhibitor user.
  List<ApplicationModel> _userApplications = [];

  // Store applications related to organizer exhibitions.
  List<ApplicationModel> _organizerApplications = [];

  // Store all applications for admin view.
  List<ApplicationModel> _allApplications = [];

  // Track loading state for UI buttons and screens.
  bool _isLoading = false;

  // Store error message for UI feedback.
  String? _errorMessage;

  List<ApplicationModel> get userApplications => _userApplications;
  List<ApplicationModel> get organizerApplications => _organizerApplications;
  List<ApplicationModel> get allApplications => _allApplications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> submitApplication(ApplicationModel application) async {
    // Start loading while submitting application.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Submit new application through service.
      final success = await _service.submitApplication(application);

      if (success) {
        // Refresh current user's application list after submit.
        await fetchUserApplications(application.userId);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      // Store cleaned error message for UI display.
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchUserApplications(String userId) async {
    // Load applications submitted by one user.
    _setLoading(true);

    try {
      _userApplications = await _service.fetchUserApplications(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _setLoading(false);
  }

  Future<void> fetchOrganizerApplications(String organizerId) async {
    // Load applications for exhibitions owned by organizer.
    _setLoading(true);

    try {
      _organizerApplications =
          await _service.fetchOrganizerApplications(organizerId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _setLoading(false);
  }

  Future<void> fetchAllApplications() async {
    // Load all applications for admin.
    _setLoading(true);

    try {
      _allApplications = await _service.fetchAllApplications();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _setLoading(false);
  }

  Future<bool> updateApplicationStatus({
    required String applicationId,
    required String boothSpotId,
    required String status,
    String? rejectReason,
    String? organizerId,
  }) async {
    // Start loading while updating application status.
    _setLoading(true);

    try {
      // Update application status through service.
      final success = await _service.updateApplicationStatus(
        applicationId: applicationId,
        boothSpotId: boothSpotId,
        status: status,
        rejectReason: rejectReason,
      );

      if (success) {
        // Refresh organizer list if update came from organizer view.
        if (organizerId != null) {
          await fetchOrganizerApplications(organizerId);
        }

        // Refresh admin list after status update.
        await fetchAllApplications();
      }

      _setLoading(false);
      return success;
    } catch (e) {
      // Store update error message.
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateApplication(ApplicationModel application) async {
    // Start loading while updating application details.
    _setLoading(true);

    try {
      // Update application data through service.
      final success = await _service.updateApplication(application);

      if (success) {
        // Refresh user application list after edit.
        await fetchUserApplications(application.userId);

        // Refresh admin list to keep data consistent.
        await fetchAllApplications();
      }

      _setLoading(false);
      return success;
    } catch (e) {
      // Store update error message.
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> makePayment({
    required String applicationId,
    required String userId,
    required String paymentMethod,
    required String transactionId,
  }) async {
    // Start loading while processing payment.
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Save simulated payment information through service.
      final success = await _service.makePayment(
        applicationId: applicationId,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
      );

      if (success) {
        // Refresh user and admin application lists after payment.
        await fetchUserApplications(userId);
        await fetchAllApplications();
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      // Store cleaned error message for UI display.
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    // Update loading state and notify UI.
    _isLoading = value;
    notifyListeners();
  }
}