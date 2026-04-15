// lib/models/contributed_listing_model.dart
//
// Model for user-submitted listings that require admin approval before
// being published to the main collections and appearing on the map.

import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

enum ContributedListingStatus {
  pending,
  approved,
  rejected;

  String get label => switch (this) {
        pending => 'Pending Review',
        approved => 'Approved',
        rejected => 'Rejected',
      };

  String get value => name;

  static ContributedListingStatus fromString(String? s) => switch (s) {
        'approved' => approved,
        'rejected' => rejected,
        _ => pending,
      };
}

enum ContributionCategory {
  spot,
  restaurant,
  cafe,
  adventure,
  homestay,
  shopping,
  event;

  String get label => switch (this) {
        spot => 'Tourist Spot',
        restaurant => 'Restaurant',
        cafe => 'Café',
        adventure => 'Adventure',
        homestay => 'Homestay',
        shopping => 'Shopping',
        event => 'Event',
      };

  String get value => name;

  /// The Firestore collection this category writes into on approval.
  String get firestoreCollection => switch (this) {
        spot => 'spots',
        restaurant => 'restaurants',
        cafe => 'cafes',
        adventure => 'adventureSpots',
        homestay => 'homestays',
        shopping => 'shoppingAreas',
        event => 'events',
      };

  String get emoji => switch (this) {
        spot => '🏔️',
        restaurant => '🍽️',
        cafe => '☕',
        adventure => '🏕️',
        homestay => '🏡',
        shopping => '🛍️',
        event => '🎉',
      };

  static ContributionCategory fromString(String? s) => switch (s) {
        'restaurant' => restaurant,
        'cafe' => cafe,
        'adventure' => adventure,
        'homestay' => homestay,
        'shopping' => shopping,
        'event' => event,
        _ => spot,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class ContributedListing {
  final String id;
  final String contributorId;
  final String contributorName;
  final String? contributorPhotoUrl;
  final ContributionCategory category;
  final ContributedListingStatus status;
  final String name;
  final String description;
  final String address;
  final String district;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;

  /// Category-specific extra fields (e.g. cuisine types, difficulty, etc.).
  final Map<String, dynamic> details;

  final String? adminNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ContributedListing({
    required this.id,
    required this.contributorId,
    required this.contributorName,
    this.contributorPhotoUrl,
    required this.category,
    required this.status,
    required this.name,
    required this.description,
    required this.address,
    required this.district,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.details,
    this.adminNotes,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory ContributedListing.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};

    DateTime ts(String key) {
      final v = d[key];
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    DateTime? tsOpt(String key) {
      final v = d[key];
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return ContributedListing(
      id: doc.id,
      contributorId: d['contributorId']?.toString() ?? '',
      contributorName: d['contributorName']?.toString() ?? 'Anonymous',
      contributorPhotoUrl: d['contributorPhotoUrl']?.toString(),
      category: ContributionCategory.fromString(d['category']?.toString()),
      status: ContributedListingStatus.fromString(d['status']?.toString()),
      name: d['name']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      address: d['address']?.toString() ?? '',
      district: d['district']?.toString() ?? '',
      latitude: (d['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (d['longitude'] as num?)?.toDouble() ?? 0,
      imageUrls: List<String>.from(d['imageUrls'] as List? ?? []),
      details: Map<String, dynamic>.from(d['details'] as Map? ?? {}),
      adminNotes: d['adminNotes']?.toString(),
      reviewedBy: d['reviewedBy']?.toString(),
      reviewedAt: tsOpt('reviewedAt'),
      createdAt: ts('createdAt'),
      updatedAt: tsOpt('updatedAt'),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'contributorId': contributorId,
        'contributorName': contributorName,
        if (contributorPhotoUrl != null)
          'contributorPhotoUrl': contributorPhotoUrl,
        'category': category.value,
        'status': status.value,
        'name': name,
        'description': description,
        'address': address,
        'district': district,
        'latitude': latitude,
        'longitude': longitude,
        'imageUrls': imageUrls,
        'details': details,
        if (adminNotes != null) 'adminNotes': adminNotes,
        if (reviewedBy != null) 'reviewedBy': reviewedBy,
        if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
