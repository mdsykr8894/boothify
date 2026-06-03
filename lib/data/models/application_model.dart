import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String id;
  final String userId;
  final String exhibitionId;
  final String boothSpotId;
  final String boothNumber;
  final String companyName;
  final String businessType;
  final String productName;
  final String description;
  final List<String> requirements;
  final String status; // Pending, Approved, Rejected, Cancelled
  final String? rejectReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? paymentMethod;
  final DateTime? paidAt;
  final String? transactionId;
  final DateTime? participationStartDate;
  final DateTime? participationEndDate;

  ApplicationModel({
    required this.id,
    required this.userId,
    required this.exhibitionId,
    required this.boothSpotId,
    required this.boothNumber,
    required this.companyName,
    required this.businessType,
    required this.productName,
    required this.description,
    this.requirements = const [],
    this.status = 'Pending',
    this.rejectReason,
    this.createdAt,
    this.updatedAt,
    this.paymentMethod,
    this.paidAt,
    this.transactionId,
    this.participationStartDate,
    this.participationEndDate,
  });

  /// Parse Firestore document data to ApplicationModel.
  factory ApplicationModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ApplicationModel(
      id: documentId,
      userId: data['userId'] ?? '',
      exhibitionId: data['exhibitionId'] ?? '',
      boothSpotId: data['boothSpotId'] ?? '',
      boothNumber: data['boothNumber'] ?? '',
      companyName: data['companyName'] ?? '',
      businessType: data['businessType'] ?? '',
      productName: data['productName'] ?? '',
      description: data['description'] ?? '',
      requirements: List<String>.from(data['requirements'] ?? []),
      status: data['status'] ?? 'Pending',
      rejectReason: data['rejectReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      paymentMethod: data['paymentMethod'],
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
      transactionId: data['transactionId'],
      participationStartDate: (data['participationStartDate'] as Timestamp?)?.toDate(),
      participationEndDate: (data['participationEndDate'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert ApplicationModel to Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'exhibitionId': exhibitionId,
      'boothSpotId': boothSpotId,
      'boothNumber': boothNumber,
      'companyName': companyName,
      'businessType': businessType,
      'productName': productName,
      'description': description,
      'requirements': requirements,
      'status': status,
      'rejectReason': rejectReason,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'paymentMethod': paymentMethod,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'transactionId': transactionId,
      'participationStartDate': participationStartDate != null ? Timestamp.fromDate(participationStartDate!) : null,
      'participationEndDate': participationEndDate != null ? Timestamp.fromDate(participationEndDate!) : null,
    };
  }

  /// Create a copy of ApplicationModel with updated fields.
  ApplicationModel copyWith({
    String? userId,
    String? exhibitionId,
    String? boothSpotId,
    String? boothNumber,
    String? companyName,
    String? businessType,
    String? productName,
    String? description,
    List<String>? requirements,
    String? status,
    String? rejectReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paymentMethod,
    DateTime? paidAt,
    String? transactionId,
    DateTime? participationStartDate,
    DateTime? participationEndDate,
  }) {
    return ApplicationModel(
      id: id,
      userId: userId ?? this.userId,
      exhibitionId: exhibitionId ?? this.exhibitionId,
      boothSpotId: boothSpotId ?? this.boothSpotId,
      boothNumber: boothNumber ?? this.boothNumber,
      companyName: companyName ?? this.companyName,
      businessType: businessType ?? this.businessType,
      productName: productName ?? this.productName,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      status: status ?? this.status,
      rejectReason: rejectReason ?? this.rejectReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paidAt: paidAt ?? this.paidAt,
      transactionId: transactionId ?? this.transactionId,
      participationStartDate: participationStartDate ?? this.participationStartDate,
      participationEndDate: participationEndDate ?? this.participationEndDate,
    );
  }
}
