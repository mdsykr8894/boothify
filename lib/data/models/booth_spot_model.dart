import 'package:cloud_firestore/cloud_firestore.dart';

class BoothSpotModel {
  final String id;
  final String exhibitionId;
  final String boothPackageId;
  final String spotNumber;
  final String status; // Available, Pending, Booked
  final DateTime? createdAt;

  BoothSpotModel({
    required this.id,
    required this.exhibitionId,
    required this.boothPackageId,
    required this.spotNumber,
    this.status = 'Available',
    this.createdAt,
  });

  /// Parse Firestore document data to BoothSpotModel.
  factory BoothSpotModel.fromMap(Map<String, dynamic> data, String documentId) {
    return BoothSpotModel(
      id: documentId,
      exhibitionId: data['exhibitionId'] ?? '',
      boothPackageId: data['boothPackageId'] ?? '',
      spotNumber: data['spotNumber'] ?? '',
      status: data['status'] ?? 'Available',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert BoothSpotModel to Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return {
      'exhibitionId': exhibitionId,
      'boothPackageId': boothPackageId,
      'spotNumber': spotNumber,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy of BoothSpotModel with updated fields.
  BoothSpotModel copyWith({
    String? exhibitionId,
    String? boothPackageId,
    String? spotNumber,
    String? status,
    DateTime? createdAt,
  }) {
    return BoothSpotModel(
      id: id,
      exhibitionId: exhibitionId ?? this.exhibitionId,
      boothPackageId: boothPackageId ?? this.boothPackageId,
      spotNumber: spotNumber ?? this.spotNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
