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
  final int popularity;
  final List<String> imagesUrl;
  final bool featured;
  final String status;
  final int views;

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
    required this.imagesUrl,
    required this.featured,
    required this.status,
    required this.views,
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

  factory SpotModel.fromJson(Map<String, dynamic> json) => SpotModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    category: json['category'] as String? ?? '',
    locationAddress: json['locationAddress'] as String? ?? '',
    district: json['district'] as String? ?? '',
    averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    popularity: (json['popularity'] as num?)?.toInt() ?? 0,
    imagesUrl: List<String>.from(json['imagesUrl'] as List? ?? []),
    featured: json['featured'] as bool? ?? false,
    status: json['status'] as String? ?? '',
    views: (json['views'] as num?)?.toInt() ?? 0,
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
}
