import 'package:cloud_firestore/cloud_firestore.dart';

class BoothPackageModel {
  final String id;
  final String exhibitionId;
  final String name;
  final String size;
  final double price;
  final List<String> amenities;
  final DateTime? createdAt;

  BoothPackageModel({
    required this.id,
    required this.exhibitionId,
    required this.name,
    required this.size,
    required this.price,
    this.amenities = const [],
    this.createdAt,
  });

  // Convert Firestore document data into BoothPackageModel.
  factory BoothPackageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return BoothPackageModel(
      id: documentId,
      exhibitionId: data['exhibitionId'] ?? '',
      name: data['name'] ?? '',
      size: data['size'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      amenities: List<String>.from(data['amenities'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert BoothPackageModel into Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return {
      'exhibitionId': exhibitionId,
      'name': name,
      'size': size,
      'price': price,
      'amenities': amenities,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  // Create a new BoothPackageModel with updated values.
  BoothPackageModel copyWith({
    String? exhibitionId,
    String? name,
    String? size,
    double? price,
    List<String>? amenities,
    DateTime? createdAt,
  }) {
    return BoothPackageModel(
      id: id,
      exhibitionId: exhibitionId ?? this.exhibitionId,
      name: name ?? this.name,
      size: size ?? this.size,
      price: price ?? this.price,
      amenities: amenities ?? this.amenities,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
