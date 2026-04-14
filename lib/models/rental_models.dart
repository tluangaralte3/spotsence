// lib/models/rental_models.dart
//
// Data models for Equipment Rentals.
// Firestore collection: `equipment_rentals`

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// RentalCategory
// ─────────────────────────────────────────────────────────────────────────────

enum RentalCategory {
  campingGear,
  waterSports,
  bicycles,
  outdoor,
  photography,
  vehicles,
  winterSports,
  climbing,
  fishing,
  other;

  String get label => switch (this) {
    RentalCategory.campingGear => 'Camping Gear',
    RentalCategory.waterSports => 'Water Sports',
    RentalCategory.bicycles => 'Bicycles',
    RentalCategory.outdoor => 'Outdoor',
    RentalCategory.photography => 'Photography',
    RentalCategory.vehicles => 'Vehicles',
    RentalCategory.winterSports => 'Winter Sports',
    RentalCategory.climbing => 'Climbing',
    RentalCategory.fishing => 'Fishing',
    RentalCategory.other => 'Other',
  };

  String get value => switch (this) {
    RentalCategory.campingGear => 'campingGear',
    RentalCategory.waterSports => 'waterSports',
    RentalCategory.bicycles => 'bicycles',
    RentalCategory.outdoor => 'outdoor',
    RentalCategory.photography => 'photography',
    RentalCategory.vehicles => 'vehicles',
    RentalCategory.winterSports => 'winterSports',
    RentalCategory.climbing => 'climbing',
    RentalCategory.fishing => 'fishing',
    RentalCategory.other => 'other',
  };

  static RentalCategory fromString(String? s) {
    return RentalCategory.values.firstWhere(
      (e) => e.value == s,
      orElse: () => RentalCategory.other,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RentalItem
// ─────────────────────────────────────────────────────────────────────────────

class RentalItem {
  final String id;
  final String name;
  final String description;
  final RentalCategory category;
  final double pricePerDay;
  final double? pricePerHour;
  final List<String> imageUrls;
  final String location;
  final String district;
  final String contactPhone;
  final String contactName;
  final Map<String, String> specifications;
  final bool isAvailable;
  final bool isFeatured;
  final int quantityAvailable;
  final DateTime? createdAt;

  const RentalItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.pricePerDay,
    this.pricePerHour,
    required this.imageUrls,
    required this.location,
    required this.district,
    required this.contactPhone,
    required this.contactName,
    required this.specifications,
    required this.isAvailable,
    required this.isFeatured,
    required this.quantityAvailable,
    this.createdAt,
  });

  String? get firstImageUrl => imageUrls.isNotEmpty ? imageUrls.first : null;

  factory RentalItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return RentalItem(
      id: doc.id,
      name: d['name']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      category: RentalCategory.fromString(d['category']?.toString()),
      pricePerDay: _toDouble(d['pricePerDay']),
      pricePerHour: d['pricePerHour'] != null
          ? _toDouble(d['pricePerHour'])
          : null,
      imageUrls: _toStringList(d['imageUrls']),
      location: d['location']?.toString() ?? '',
      district: d['district']?.toString() ?? '',
      contactPhone: d['contactPhone']?.toString() ?? '',
      contactName: d['contactName']?.toString() ?? '',
      specifications: _toStringMap(d['specifications']),
      isAvailable: d['isAvailable'] != false,
      isFeatured: d['isFeatured'] == true,
      quantityAvailable: d['quantityAvailable'] is int
          ? d['quantityAvailable'] as int
          : int.tryParse(d['quantityAvailable']?.toString() ?? '') ?? 1,
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'category': category.value,
    'pricePerDay': pricePerDay,
    if (pricePerHour != null) 'pricePerHour': pricePerHour,
    'imageUrls': imageUrls,
    'location': location,
    'district': district,
    'contactPhone': contactPhone,
    'contactName': contactName,
    'specifications': specifications,
    'isAvailable': isAvailable,
    'isFeatured': isFeatured,
    'quantityAvailable': quantityAvailable,
    'createdAt': FieldValue.serverTimestamp(),
  };

  RentalItem copyWith({
    String? name,
    String? description,
    RentalCategory? category,
    double? pricePerDay,
    double? pricePerHour,
    List<String>? imageUrls,
    String? location,
    String? district,
    String? contactPhone,
    String? contactName,
    Map<String, String>? specifications,
    bool? isAvailable,
    bool? isFeatured,
    int? quantityAvailable,
  }) => RentalItem(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    pricePerDay: pricePerDay ?? this.pricePerDay,
    pricePerHour: pricePerHour ?? this.pricePerHour,
    imageUrls: imageUrls ?? this.imageUrls,
    location: location ?? this.location,
    district: district ?? this.district,
    contactPhone: contactPhone ?? this.contactPhone,
    contactName: contactName ?? this.contactName,
    specifications: specifications ?? this.specifications,
    isAvailable: isAvailable ?? this.isAvailable,
    isFeatured: isFeatured ?? this.isFeatured,
    quantityAvailable: quantityAvailable ?? this.quantityAvailable,
    createdAt: createdAt,
  );
}

List<String> _toStringList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}

Map<String, String> _toStringMap(dynamic v) {
  if (v == null) return {};
  if (v is Map) {
    return v.map((k, val) => MapEntry(k.toString(), val?.toString() ?? ''));
  }
  return {};
}
