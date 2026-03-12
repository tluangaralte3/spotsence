import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

@immutable
class EntryFee {
  final String type;
  final String amount;
  const EntryFee({required this.type, required this.amount});

  factory EntryFee.fromJson(Map<String, dynamic> json) => EntryFee(
    type: json['type'] as String? ?? '',
    amount: json['amount'] as String? ?? '',
  );
  Map<String, dynamic> toJson() => {'type': type, 'amount': amount};
}

@immutable
class SpotRating {
  final String userId;
  final String userName;
  final double rating;
  final String timestamp;
  const SpotRating({
    required this.userId,
    required this.userName,
    required this.rating,
    required this.timestamp,
  });

  factory SpotRating.fromJson(Map<String, dynamic> json) => SpotRating(
    userId: json['userId'] as String? ?? '',
    userName: json['userName'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    timestamp: json['timestamp'] as String? ?? '',
  );
}

@immutable
class SpotComment {
  final String userId;
  final String userName;
  final String comment;
  final String timestamp;
  const SpotComment({
    required this.userId,
    required this.userName,
    required this.comment,
    required this.timestamp,
  });

  factory SpotComment.fromJson(Map<String, dynamic> json) => SpotComment(
    userId: json['userId'] as String? ?? '',
    userName: json['userName'] as String? ?? '',
    comment: json['comment'] as String? ?? '',
    timestamp: json['timestamp'] as String? ?? '',
  );
}

@immutable
class SpotModel {
  final String id;
  final String name;
  final String category;
  final String locationAddress;
  final String district;
  final double averageRating;
  final double popularity; // stored as double in Firestore (9.0 / 7.5)
  final int ratingsCount;
  final List<String> imagesUrl;
  final bool featured;
  final String status;
  final int views;

  // Extra fields present in the Firestore document
  final String? distance;
  final String? bestSeason;
  final String? openingHours;
  final String? facilities;
  final String? accessibility;
  final String? safetyNotes;
  final String? officialSourceUrl;
  final List<String> alternateNames;

  // Detail fields (populated on detail page)
  final String? placeStory;
  final List<String> thingsToDo;
  final List<EntryFee> entryFees;
  final List<String> addOns;
  final List<SpotRating> ratings;
  final List<SpotComment> comments;
  final List<String> tags;
  final double? latitude;
  final double? longitude;

  const SpotModel({
    required this.id,
    required this.name,
    required this.category,
    required this.locationAddress,
    required this.district,
    required this.averageRating,
    required this.popularity,
    required this.ratingsCount,
    required this.imagesUrl,
    required this.featured,
    required this.status,
    required this.views,
    this.distance,
    this.bestSeason,
    this.openingHours,
    this.facilities,
    this.accessibility,
    this.safetyNotes,
    this.officialSourceUrl,
    this.alternateNames = const [],
    this.placeStory,
    this.thingsToDo = const [],
    this.entryFees = const [],
    this.addOns = const [],
    this.ratings = const [],
    this.comments = const [],
    this.tags = const [],
    this.latitude,
    this.longitude,
  });

  String get heroImage => imagesUrl.isNotEmpty ? imagesUrl.first : '';

  /// Parse from a plain JSON map (REST API response).
  factory SpotModel.fromJson(Map<String, dynamic> json) => SpotModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? '',
    locationAddress: json['locationAddress'] as String? ?? '',
    district: json['district'] as String? ?? '',
    averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    popularity: (json['popularity'] as num?)?.toDouble() ?? 0,
    ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
    imagesUrl: List<String>.from(json['imagesUrl'] as List? ?? []),
    featured: json['featured'] as bool? ?? false,
    status: json['status'] as String? ?? '',
    views: (json['views'] as num?)?.toInt() ?? 0,
    distance: json['distance'] as String?,
    bestSeason: json['bestSeason'] as String?,
    openingHours: json['openingHours'] as String?,
    facilities: json['facilities'] as String?,
    accessibility: json['accessibility'] as String?,
    safetyNotes: json['safetyNotes'] as String?,
    officialSourceUrl: json['officialSourceUrl'] as String?,
    alternateNames: List<String>.from(json['alternateNames'] as List? ?? []),
    placeStory: json['placeStory'] as String?,
    thingsToDo: List<String>.from(json['thingsToDo'] as List? ?? []),
    entryFees: (json['entryFees'] as List? ?? [])
        .map((e) => EntryFee.fromJson(e as Map<String, dynamic>))
        .toList(),
    addOns: List<String>.from(json['addOns'] as List? ?? []),
    ratings: (json['ratings'] as List? ?? [])
        .map((e) => SpotRating.fromJson(e as Map<String, dynamic>))
        .toList(),
    comments: (json['comments'] as List? ?? [])
        .map((e) => SpotComment.fromJson(e as Map<String, dynamic>))
        .toList(),
    tags: List<String>.from(json['tags'] as List? ?? []),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  /// Parse from a Firestore [DocumentSnapshot].
  /// Handles the exact field names written by the import script.
  factory SpotModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    // imagesUrl may be a List<dynamic> of strings
    List<String> images = [];
    final rawImages = d['imagesUrl'];
    if (rawImages is List) {
      images = rawImages.whereType<String>().toList();
    }

    // entryFees may be a List<Map> or absent
    List<EntryFee> fees = [];
    final rawFees = d['entryFees'];
    if (rawFees is List) {
      fees = rawFees
          .whereType<Map<String, dynamic>>()
          .map(EntryFee.fromJson)
          .toList();
    }

    // alternateNames: stored as List<String> or a comma-separated String
    List<String> altNames = [];
    final rawAlt = d['alternateNames'];
    if (rawAlt is List) {
      altNames = rawAlt.whereType<String>().toList();
    } else if (rawAlt is String && rawAlt.isNotEmpty) {
      altNames = rawAlt.split(',').map((s) => s.trim()).toList();
    }

    // thingsToDo: List<String> or absent
    List<String> todos = [];
    final rawTodos = d['thingsToDo'];
    if (rawTodos is List) {
      todos = rawTodos.whereType<String>().toList();
    }

    // addOns: List<String> or absent
    List<String> addOns = [];
    final rawAddOns = d['addOns'];
    if (rawAddOns is List) {
      addOns = rawAddOns.whereType<String>().toList();
    }

    // averageRating might not yet exist for new documents
    double avgRating = 0;
    final rawRating = d['averageRating'];
    if (rawRating is num) avgRating = rawRating.toDouble();

    return SpotModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      category: d['category'] as String? ?? '',
      locationAddress: d['locationAddress'] as String? ?? '',
      district: d['district'] as String? ?? '',
      averageRating: avgRating,
      popularity: (d['popularity'] as num?)?.toDouble() ?? 0,
      ratingsCount: (d['ratingsCount'] as num?)?.toInt() ?? 0,
      imagesUrl: images,
      featured: d['featured'] as bool? ?? false,
      status: d['status'] as String? ?? '',
      views: (d['views'] as num?)?.toInt() ?? 0,
      distance: d['distance'] as String?,
      bestSeason: d['bestSeason'] as String?,
      openingHours: d['openingHours'] as String?,
      facilities: d['facilities'] as String?,
      accessibility: d['accessibility'] as String?,
      safetyNotes: d['safetyNotes'] as String?,
      officialSourceUrl: d['officialSourceUrl'] as String?,
      alternateNames: altNames,
      placeStory: d['placeStory'] as String?,
      thingsToDo: todos,
      entryFees: fees,
      addOns: addOns,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
    );
  }
}
