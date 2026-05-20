import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/application_model.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'applications';
  final String _boothSpotsCollection = 'booth_spots';

  /// Submit an application and update the selected booth spot to 'Pending'.
  /// Uses a transaction to prevent double booking.
  Future<bool> submitApplication(ApplicationModel application) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 1. Get latest booth spot data
        final spotRef = _firestore.collection(_boothSpotsCollection).doc(application.boothSpotId);
        final spotDoc = await transaction.get(spotRef);

        if (!spotDoc.exists) {
          throw Exception('Booth spot not found');
        }

        // 2. Check if still available
        final status = spotDoc.data()?['status'] ?? '';
        if (status != 'Available') {
          throw Exception('This booth is no longer available. Please choose another booth.');
        }

        // 3. Create application document
        final appRef = _firestore.collection(_collection).doc();
        transaction.set(appRef, application.toMap());

        // 4. Update booth spot status to Pending
        transaction.update(spotRef, {'status': 'Pending'});
      });
      return true;
    } catch (e) {
      debugPrint('Error submitting application: $e');
      rethrow;
    }
  }

  int _compareByUpdatedOrCreated(ApplicationModel a, ApplicationModel b) {
    final aDate = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDate = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  }

  /// Fetch applications for a specific user (Exhibitor).
  Future<List<ApplicationModel>> fetchUserApplications(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final apps = querySnapshot.docs
          .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
          .toList();

      apps.sort(_compareByUpdatedOrCreated);
      return apps;
    } catch (e) {
      debugPrint('Error fetching user applications: $e');
      return [];
    }
  }

  /// Fetch applications for a specific organizer's exhibitions.
  Future<List<ApplicationModel>> fetchOrganizerApplications(String organizerId) async {
    try {
      // 1. Fetch exhibitions managed by this organizer
      final exhibitionsSnapshot = await _firestore
          .collection('exhibitions')
          .where('organizerId', isEqualTo: organizerId)
          .get();

      final exhibitionIds = exhibitionsSnapshot.docs.map((doc) => doc.id).toList();

      if (exhibitionIds.isEmpty) return [];

      // 2. Fetch applications for these exhibitions
      // Firestore 'whereIn' is limited to 30 items, suitable for this assignment scale.
      final applicationsSnapshot = await _firestore
          .collection(_collection)
          .where('exhibitionId', whereIn: exhibitionIds)
          .get();

      final apps = applicationsSnapshot.docs
          .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
          .toList();

      apps.sort(_compareByUpdatedOrCreated);
      return apps;
    } catch (e) {
      debugPrint('Error fetching organizer applications: $e');
      return [];
    }
  }

  /// Fetch all applications (for Admin).
  Future<List<ApplicationModel>> fetchAllApplications() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .get();

      final apps = querySnapshot.docs
          .map((doc) => ApplicationModel.fromMap(doc.data(), doc.id))
          .toList();

      apps.sort(_compareByUpdatedOrCreated);
      return apps;
    } catch (e) {
      debugPrint('Error fetching all applications: $e');
      return [];
    }
  }

  /// Update application status and corresponding booth spot status.
  Future<bool> updateApplicationStatus({
    required String applicationId,
    required String boothSpotId,
    required String status,
    String? rejectReason,
  }) async {
    try {
      final batch = _firestore.batch();

      // 1. Update application status
      final appRef = _firestore.collection(_collection).doc(applicationId);
      final Map<String, dynamic> appUpdates = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (rejectReason != null) appUpdates['rejectReason'] = rejectReason;
      batch.update(appRef, appUpdates);

      // 2. Determine booth spot status
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

      // 3. Update booth spot
      final spotRef = _firestore.collection(_boothSpotsCollection).doc(boothSpotId);
      batch.update(spotRef, {'status': spotStatus});

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error updating application status: $e');
      return false;
    }
  }

  /// Transition application from 'Approved' to 'Paid' and store payment metadata.
  Future<bool> makePayment({
    required String applicationId,
    required String paymentMethod,
    required String transactionId,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final appRef = _firestore.collection(_collection).doc(applicationId);
        final appDoc = await transaction.get(appRef);

        if (!appDoc.exists) {
          throw Exception('Application not found');
        }

        final currentStatus = appDoc.data()?['status'] ?? '';
        if (currentStatus != 'Approved') {
          throw Exception('Only approved applications can be paid. Current status: $currentStatus');
        }

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

  /// Update an existing application details.
  Future<bool> updateApplication(ApplicationModel application) async {
    try {
      final updatedModel = application.copyWith(updatedAt: DateTime.now());
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
