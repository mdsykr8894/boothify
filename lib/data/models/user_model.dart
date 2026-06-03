import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // Admin, Organizer, Exhibitor
  final bool isActive;
  final String? companyName;
  final List<String> favoriteExhibitionIds;
  final DateTime? createdAt;

  // Optional personal profile fields.
  final String? preferredName;
  final String? phoneNumber;
  final String? residentialAddress;
  final String? postalAddress;
  final String? emergencyContact;
  final String? contactEmail;
  final bool isVerified;
  final DateTime? updatedAt;

  // Optional exhibitor/company profile fields.
  final String? businessType;
  final String? companyRegistration;
  final String? productCategory;
  final String? contactPerson;
  final String? companyPhone;
  final String? companyEmail;

  // Optional organizer profile fields.
  final String? organizationName;
  final String? organizerPhone;
  final String? organizerEmail;
  final String? organizerVerificationStatus;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.companyName,
    this.favoriteExhibitionIds = const [],
    this.createdAt,
    this.preferredName,
    this.phoneNumber,
    this.residentialAddress,
    this.postalAddress,
    this.emergencyContact,
    this.contactEmail,
    this.isVerified = false,
    this.updatedAt,
    this.businessType,
    this.companyRegistration,
    this.productCategory,
    this.contactPerson,
    this.companyPhone,
    this.companyEmail,
    this.organizationName,
    this.organizerPhone,
    this.organizerEmail,
    this.organizerVerificationStatus,
  });

  // Convert Firestore document data into UserModel.
  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'Exhibitor',
      isActive: data['isActive'] ?? true,
      companyName: data['companyName'],
      favoriteExhibitionIds: List<String>.from(
        data['favoriteExhibitionIds'] ?? [],
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      preferredName: data['preferredName'],

      // Support old phone field if phoneNumber is not available.
      phoneNumber: data['phoneNumber'] ?? data['phone'],

      residentialAddress: data['residentialAddress'],
      postalAddress: data['postalAddress'],
      emergencyContact: data['emergencyContact'],
      contactEmail: data['contactEmail'],

      // Support both boolean isVerified and text verificationStatus.
      isVerified: data['isVerified'] ?? (data['verificationStatus'] == 'Verified'),

      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      businessType: data['businessType'],

      // Support old registrationNumber field if companyRegistration is missing.
      companyRegistration:
          data['companyRegistration'] ?? data['registrationNumber'],

      productCategory: data['productCategory'],
      contactPerson: data['contactPerson'],
      companyPhone: data['companyPhone'],
      companyEmail: data['companyEmail'],
      organizationName: data['organizationName'],
      organizerPhone: data['organizerPhone'],
      organizerEmail: data['organizerEmail'],
      organizerVerificationStatus: data['organizerVerificationStatus'],
    );
  }

  // Convert UserModel into Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
      'companyName': companyName,
      'favoriteExhibitionIds': favoriteExhibitionIds,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'preferredName': preferredName,
      'phoneNumber': phoneNumber,
      'residentialAddress': residentialAddress,
      'postalAddress': postalAddress,
      'emergencyContact': emergencyContact,
      'contactEmail': contactEmail,
      'isVerified': isVerified,
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
      'businessType': businessType,
      'companyRegistration': companyRegistration,
      'productCategory': productCategory,
      'contactPerson': contactPerson,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'organizationName': organizationName,
      'organizerPhone': organizerPhone,
      'organizerEmail': organizerEmail,
      'organizerVerificationStatus': organizerVerificationStatus,
    };
  }

  // Create a new UserModel with updated values.
  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    bool? isActive,
    String? companyName,
    List<String>? favoriteExhibitionIds,
    DateTime? createdAt,
    String? preferredName,
    String? phoneNumber,
    String? residentialAddress,
    String? postalAddress,
    String? emergencyContact,
    String? contactEmail,
    bool? isVerified,
    DateTime? updatedAt,
    String? businessType,
    String? companyRegistration,
    String? productCategory,
    String? contactPerson,
    String? companyPhone,
    String? companyEmail,
    String? organizationName,
    String? organizerPhone,
    String? organizerEmail,
    String? organizerVerificationStatus,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      companyName: companyName ?? this.companyName,
      favoriteExhibitionIds: favoriteExhibitionIds ?? this.favoriteExhibitionIds,
      createdAt: createdAt ?? this.createdAt,
      preferredName: preferredName ?? this.preferredName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      residentialAddress: residentialAddress ?? this.residentialAddress,
      postalAddress: postalAddress ?? this.postalAddress,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      contactEmail: contactEmail ?? this.contactEmail,
      isVerified: isVerified ?? this.isVerified,
      updatedAt: updatedAt ?? this.updatedAt,
      businessType: businessType ?? this.businessType,
      companyRegistration: companyRegistration ?? this.companyRegistration,
      productCategory: productCategory ?? this.productCategory,
      contactPerson: contactPerson ?? this.contactPerson,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      organizationName: organizationName ?? this.organizationName,
      organizerPhone: organizerPhone ?? this.organizerPhone,
      organizerEmail: organizerEmail ?? this.organizerEmail,
      organizerVerificationStatus:
          organizerVerificationStatus ?? this.organizerVerificationStatus,
    );
  }
}