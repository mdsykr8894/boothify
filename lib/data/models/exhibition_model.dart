import 'package:cloud_firestore/cloud_firestore.dart';

class ExhibitionModel {
  final String id;
  final String organizerId;
  final String name;
  final String location;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final bool isPublished;
  final bool isBookingOpen;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String category;
  final String eventType;
  final String contactEmail;
  final String contactPhone;
  final String openingHours;
  final String expectedVisitors;
  final List<String> imageUrls;
  
  // Custom floor plan grid dimensions (nullable for backward compatibility)
  final int? layoutRows;
  final int? layoutColumns;

  ExhibitionModel({
    required this.id,
    required this.organizerId,
    required this.name,
    required this.location,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.isPublished = false,
    this.isBookingOpen = true,
    this.createdAt,
    this.updatedAt,
    this.category = 'General',
    this.eventType = '',
    this.contactEmail = '',
    this.contactPhone = '',
    this.openingHours = '',
    this.expectedVisitors = '',
    this.imageUrls = const [],
    this.layoutRows,
    this.layoutColumns,
  });

  /// Computed getters for event status
  String get eventStatus {
    if (isUpcoming) return 'Upcoming';
    if (isOngoing) return 'Ongoing';
    return 'Completed';
  }

  bool get isUpcoming => DateTime.now().isBefore(startDate);

  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  bool get isCompleted => DateTime.now().isAfter(endDate);

  bool get shouldShowInExplore => isPublished && !isCompleted;

  /// Parse Firestore document data to ExhibitionModel.
  factory ExhibitionModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ExhibitionModel(
      id: documentId,
      organizerId: data['organizerId'] ?? '',
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      isPublished: data['isPublished'] ?? false,
      isBookingOpen: data['isBookingOpen'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      category: data['category'] ?? 'General',
      eventType: data['eventType'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      openingHours: data['openingHours'] ?? '',
      expectedVisitors: data['expectedVisitors'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      layoutRows: data['layoutRows'] as int?,
      layoutColumns: data['layoutColumns'] as int?,
    );
  }

  /// Convert ExhibitionModel to Firestore-friendly map.
  Map<String, dynamic> toMap() {
    return {
      'organizerId': organizerId,
      'name': name,
      'location': location,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isPublished': isPublished,
      'isBookingOpen': isBookingOpen,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      'category': category,
      'eventType': eventType,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'openingHours': openingHours,
      'expectedVisitors': expectedVisitors,
      'imageUrls': imageUrls,
      'layoutRows': layoutRows,
      'layoutColumns': layoutColumns,
    };
  }

  /// Create a copy of ExhibitionModel with updated fields.
  ExhibitionModel copyWith({
    String? id,
    String? organizerId,
    String? name,
    String? location,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    bool? isPublished,
    bool? isBookingOpen,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    String? eventType,
    String? contactEmail,
    String? contactPhone,
    String? openingHours,
    String? expectedVisitors,
    List<String>? imageUrls,
    int? layoutRows,
    int? layoutColumns,
  }) {
    return ExhibitionModel(
      id: id ?? this.id,
      organizerId: organizerId ?? this.organizerId,
      name: name ?? this.name,
      location: location ?? this.location,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isPublished: isPublished ?? this.isPublished,
      isBookingOpen: isBookingOpen ?? this.isBookingOpen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      eventType: eventType ?? this.eventType,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      openingHours: openingHours ?? this.openingHours,
      expectedVisitors: expectedVisitors ?? this.expectedVisitors,
      imageUrls: imageUrls ?? this.imageUrls,
      layoutRows: layoutRows ?? this.layoutRows,
      layoutColumns: layoutColumns ?? this.layoutColumns,
    );
  }
}
