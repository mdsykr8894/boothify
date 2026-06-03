import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/application_model.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'applications';
  final String _boothSpotsCollection = 'booth_spots';

  Future<bool> submitApplication(ApplicationModel application) async {
    try {
      // Use transaction to prevent double booking.
      await _firestore.runTransaction((transaction) async {
        // Get latest booth spot data.
        final spotRef = _firestore
            .collection(_boothSpotsCollection)
            .doc(application.boothSpotId);

        final spotDoc = await transaction.get(spotRef);

        // Stop if booth spot does not exist.
        if (!spotDoc.exists) {
          throw Exception('Booth spot not found');
        }

        // Check if booth spot is still available.
        final status = spotDoc.data()?['status'] ?? '';

        if (status != 'Available') {
          throw Exception(
            'This booth is no longer available. Please choose another booth.',
          );
        }

        // Get existing applications for the same exhibition.
        final activeAppsSnapshot = await _firestore
            .collection(_collection)
            .where('exhibitionId', isEqualTo: application.exhibitionId)
            .get();

        // Normalize new business type for comparison.
        final normalizedNewBusinessType = application.businessType
            .trim()
            .toLowerCase();

        for (final doc in activeAppsSnapshot.docs) {
          // Skip same application during conflict check.
          if (doc.id == application.id) continue;

          final appData = doc.data();
          final appStatus = appData['status'] ?? '';

          // Check only active or reserved applications.
          if (appStatus == 'Pending' ||
              appStatus == 'Approved' ||
              appStatus == 'Paid' ||
              appStatus == 'Booked') {
            final existingBusinessType =
                (appData['businessType'] as String? ?? '').trim().toLowerCase();

            // Check nearby booth if business type is similar.
            if (existingBusinessType == normalizedNewBusinessType) {
              final existingBoothNumber =
                  appData['boothNumber'] as String? ?? '';

              if (_isAdjacentSpot(
                application.boothNumber,
                existingBoothNumber,
              )) {
                throw Exception(
                  'A nearby booth is already reserved by a similar business type. Please choose another booth.',
                );
              }
            }
          }
        }

        // Create new application document.
        final appRef = _firestore.collection(_collection).doc();
        transaction.set(appRef, application.toMap());

        // Mark selected booth spot as pending.
        transaction.update(spotRef, {'status': 'Pending'});
      });

      return true;
    } catch (e) {
      debugPrint('Error submitting application: $e');
      rethrow;
    }
  }

  bool _isAdjacentSpot(String spot1, String spot2) {
    // Return false if booth spot format is invalid.
    if (spot1.length < 2 || spot2.length < 2) return false;

    // Extract row and column from first booth spot.
    final row1 = spot1[0].toUpperCase().codeUnitAt(0);
    final col1 = int.tryParse(spot1.substring(1));

    // Extract row and column from second booth spot.
    final row2 = spot2[0].toUpperCase().codeUnitAt(0);
    final col2 = int.tryParse(spot2.substring(1));

    // Return false if column cannot be parsed.
    if (col1 == null || col2 == null) return false;

    // Calculate row and column distance.
    final rowDiff = (row1 - row2).abs();
    final colDiff = (col1 - col2).abs();

    // Adjacent means next to each other horizontally or vertically.
    return (rowDiff == 0 && colDiff == 1) || (rowDiff == 1 && colDiff == 0);
  }

  int _compareByUpdatedOrCreated(ApplicationModel a, ApplicationModel b) {
    // Sort by updated date first, then created date.
    final aDate =
        a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate =
        b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

    // Latest application appears first.
    return bDate.compareTo(aDate);
  }

  Future<List<ApplicationModel>> fetchUserApplications(String userId) async {
    try {
      // Fetch applications submitted by one exhibitor user.
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      // Convert Firestore documents into ApplicationModel list.
      final apps = querySnapshot.docs
          .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort latest applications first.
      apps.sort(_compareByUpdatedOrCreated);

      return apps;
    } catch (e) {
      debugPrint('Error fetching user applications: $e');
      return [];
    }
  }

  Future<List<ApplicationModel>> fetchOrganizerApplications(
    String organizerId,
  ) async {
    try {
      // Fetch exhibitions managed by this organizer.
      final exhibitionsSnapshot = await _firestore
          .collection('exhibitions')
          .where('organizerId', isEqualTo: organizerId)
          .get();

      // Collect exhibition IDs owned by organizer.
      final exhibitionIds = exhibitionsSnapshot.docs
          .map((doc) => doc.id)
          .toList();

      // Return empty list if organizer has no exhibitions.
      if (exhibitionIds.isEmpty) return [];

      // Fetch applications for organizer exhibitions.
      final applicationsSnapshot = await _firestore
          .collection(_collection)
          .where('exhibitionId', whereIn: exhibitionIds)
          .get();

      // Convert Firestore documents into ApplicationModel list.
      final apps = applicationsSnapshot.docs
          .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort latest applications first.
      apps.sort(_compareByUpdatedOrCreated);

      return apps;
    } catch (e) {
      debugPrint('Error fetching organizer applications: $e');
      return [];
    }
  }

  Future<List<ApplicationModel>> fetchAllApplications() async {
    try {
      // Fetch all applications for admin.
      final querySnapshot = await _firestore.collection(_collection).get();

      // Convert Firestore documents into ApplicationModel list.
      final apps = querySnapshot.docs
          .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
          .toList();

      // Sort latest applications first.
      apps.sort(_compareByUpdatedOrCreated);

      return apps;
    } catch (e) {
      debugPrint('Error fetching all applications: $e');
      return [];
    }
  }

  Future<bool> updateApplicationStatus({
    required String applicationId,
    required String boothSpotId,
    required String status,
    String? rejectReason,
  }) async {
    try {
      // Use batch to update application and booth spot together.
      final batch = _firestore.batch();

      // Prepare application status update.
      final appRef = _firestore.collection(_collection).doc(applicationId);

      final Map<String, dynamic> appUpdates = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save reject reason when application is rejected.
      if (rejectReason != null) {
        appUpdates['rejectReason'] = rejectReason;
      }

      // Add application update to batch.
      batch.update(appRef, appUpdates);

      // Determine booth spot status based on application status.
      String spotStatus;

      switch (status) {
        case 'Approved':
          spotStatus = 'Booked';
          break;
        case 'Rejected':
        case 'Cancelled':
          spotStatus = 'Available';
          break;
        default:
          spotStatus = 'Pending';
      }

      // Add booth spot status update to batch.
      final spotRef = _firestore
          .collection(_boothSpotsCollection)
          .doc(boothSpotId);

      batch.update(spotRef, {'status': spotStatus});

      // Commit both updates together.
      await batch.commit();

      return true;
    } catch (e) {
      debugPrint('Error updating application status: $e');
      return false;
    }
  }

  Future<bool> makePayment({
    required String applicationId,
    required String paymentMethod,
    required String transactionId,
  }) async {
    try {
      // Use transaction to validate status before payment.
      await _firestore.runTransaction((transaction) async {
        final appRef = _firestore.collection(_collection).doc(applicationId);
        final appDoc = await transaction.get(appRef);

        // Stop if application does not exist.
        if (!appDoc.exists) {
          throw Exception('Application not found');
        }

        // Payment is only allowed for approved applications.
        final currentStatus = appDoc.data()?['status'] ?? '';

        if (currentStatus != 'Approved') {
          throw Exception(
            'Only approved applications can be paid. Current status: $currentStatus',
          );
        }

        // Mark application as paid and store payment details.
        transaction.update(appRef, {
          'status': 'Paid',
          'paymentMethod': paymentMethod,
          'paidAt': FieldValue.serverTimestamp(),
          'transactionId': transactionId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      return true;
    } catch (e) {
      debugPrint('Error making payment: $e');
      rethrow;
    }
  }

  Future<bool> updateApplication(ApplicationModel application) async {
    try {
      // Create updated model with latest updatedAt value.
      final updatedModel = application.copyWith(updatedAt: DateTime.now());

      // Update application document in Firestore.
      await _firestore
          .collection(_collection)
          .doc(application.id)
          .update(updatedModel.toMap());

      return true;
    } catch (e) {
      debugPrint('Error updating application details: $e');
      return false;
    }
  }
}
