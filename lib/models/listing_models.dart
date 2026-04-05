// Listing models mirroring the Firestore collections used by the web app.
// Collections: restaurants, hotels, cafes, homestays, adventureSpots,
//              shoppingAreas, events

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the first non-empty string from [images], or '' if the list is empty.
String _heroImage(List<String> images) => images.isNotEmpty ? images.first : '';

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

List<String> _toStringList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}

// ─────────────────────────────────────────────────────────────────────────────
// RestaurantModel
// ─────────────────────────────────────────────────────────────────────────────

class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final List<String> images;
  final double rating;
  final String priceRange; // '$' | '$$' | '$$$' | '$$$$'
  final List<String> cuisineTypes;
  final String openingHours;
  final bool hasDelivery;
  final bool hasReservation;
  final String district;

  final String contactPhone;
  final String website;
  final int ratingsCount;
  final double? latitude;
  final double? longitude;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.images,
    required this.rating,
    required this.priceRange,
    required this.cuisineTypes,
    required this.openingHours,
    required this.hasDelivery,
    required this.hasReservation,
    required this.district,
    this.contactPhone = '',
    this.website = '',
    this.ratingsCount = 0,
    this.latitude,
    this.longitude,
  });

  String get heroImage => _heroImage(images);

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      RestaurantModel(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        location: json['location']?.toString() ?? '',
        images: _toStringList(json['images']),
        rating: _toDouble(json['rating']),
        priceRange: json['priceRange']?.toString() ?? '\$',
        cuisineTypes: _toStringList(json['cuisineTypes']),
        openingHours: json['openingHours']?.toString() ?? '',
        hasDelivery: json['hasDelivery'] == true,
        hasReservation: json['hasReservation'] == true,
        district: json['district']?.toString() ?? '',
        contactPhone: json['contactPhone']?.toString() ?? '',
        website: json['website']?.toString() ?? '',
        ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  factory RestaurantModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return RestaurantModel(
      id: doc.id,
      name: d['name']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      location: d['location']?.toString() ?? d['address']?.toString() ?? '',
      images: _toStringList(d['images']),
      rating: _toDouble(d['rating'] ?? d['averageRating']),
      priceRange: d['priceRange']?.toString() ?? '\$',
      cuisineTypes: _toStringList(d['cuisineTypes'] ?? d['cuisine']),
      openingHours: d['openingHours']?.toString() ?? '',
      hasDelivery: d['hasDelivery'] == true,
      hasReservation: d['hasReservation'] == true,
      district: d['district']?.toString() ?? '',
      contactPhone:
          d['contactPhone']?.toString() ?? d['phone']?.toString() ?? '',
      website: d['website']?.toString() ?? '',
      ratingsCount:
          (d['ratingsCount'] as num?)?.toInt() ??
          (d['reviewCount'] as num?)?.toInt() ??
          0,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'location': location,
    'images': images,
    'rating': rating,
    'priceRange': priceRange,
    'cuisineTypes': cuisineTypes,
    'openingHours': openingHours,
    'hasDelivery': hasDelivery,
    'hasReservation': hasReservation,
    'district': district,
    'contactPhone': contactPhone,
    'website': website,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// HotelModel
// ─────────────────────────────────────────────────────────────────────────────

class HotelModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final List<String> images;
  final double rating;
  final String priceRange;
  final List<String> amenities;
  final List<String> roomTypes;
  final bool hasRestaurant;
  final bool hasWifi;
  final bool hasParking;
  final bool hasPool;
  final String district;
  final String contactPhone;
  final String website;

  final int ratingsCount;

  const HotelModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.images,
    required this.rating,
    required this.priceRange,
    required this.amenities,
    required this.roomTypes,
    required this.hasRestaurant,
    required this.hasWifi,
    required this.hasParking,
    required this.hasPool,
    required this.district,
    required this.contactPhone,
    required this.website,
    this.ratingsCount = 0,
  });

  String get heroImage => _heroImage(images);

  factory HotelModel.fromJson(Map<String, dynamic> json) => HotelModel(
    id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    location: json['location']?.toString() ?? '',
    images: _toStringList(json['images']),
    rating: _toDouble(json['rating']),
    priceRange: json['priceRange']?.toString() ?? '\$\$',
    amenities: _toStringList(json['amenities']),
    roomTypes: _toStringList(json['roomTypes']),
    hasRestaurant: json['hasRestaurant'] == true,
    hasWifi: json['hasWifi'] == true,
    hasParking: json['hasParking'] == true,
    hasPool: json['hasPool'] == true,
    district: json['district']?.toString() ?? '',
    contactPhone: json['contactPhone']?.toString() ?? '',
    website: json['website']?.toString() ?? '',
    ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
  );

  factory HotelModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return HotelModel(
      id: doc.id,
      name: d['name']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      location: d['location']?.toString() ?? d['address']?.toString() ?? '',
      images: _toStringList(d['images']),
      rating: _toDouble(d['rating'] ?? d['averageRating']),
      priceRange: d['priceRange']?.toString() ?? '\$\$',
      amenities: _toStringList(d['amenities']),
      roomTypes: _toStringList(d['roomTypes']),
      hasRestaurant: d['hasRestaurant'] == true,
      hasWifi: d['hasWifi'] == true,
      hasParking: d['hasParking'] == true,
      hasPool: d['hasPool'] == true,
      district: d['district']?.toString() ?? '',
      contactPhone:
          d['contactPhone']?.toString() ?? d['phone']?.toString() ?? '',
      website: d['website']?.toString() ?? '',
      ratingsCount:
          (d['ratingsCount'] as num?)?.toInt() ??
          (d['reviewCount'] as num?)?.toInt() ??
          0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CafeModel
// ─────────────────────────────────────────────────────────────────────────────

class CafeModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final List<String> images;
  final double rating;
  final String priceRange;
  final List<String> specialties;
  final String openingHours;
  final bool hasWifi;
  final bool hasOutdoorSeating;
  final String district;
  final String contactPhone;
  final int ratingsCount;
  final double? latitude;
  final double? longitude;

  const CafeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.images,
    required this.rating,
    required this.priceRange,
    required this.specialties,
    required this.openingHours,
    required this.hasWifi,
    required this.hasOutdoorSeating,
    required this.district,
    this.contactPhone = '',
    this.ratingsCount = 0,
    this.latitude,
    this.longitude,
  });

  String get heroImage => _heroImage(images);

  factory CafeModel.fromJson(Map<String, dynamic> json) => CafeModel(
    id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    location: json['location']?.toString() ?? '',
    images: _toStringList(json['images']),
    rating: _toDouble(json['rating']),
    priceRange: json['priceRange']?.toString() ?? '\$',
    specialties: _toStringList(json['specialties']),
    openingHours: json['openingHours']?.toString() ?? '',
    hasWifi: json['hasWifi'] == true,
    hasOutdoorSeating: json['hasOutdoorSeating'] == true,
    district: json['district']?.toString() ?? '',
    contactPhone: json['contactPhone']?.toString() ?? '',
    ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );

  factory CafeModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return CafeModel(
      id: doc.id,
      name: d['name']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      location: d['location']?.toString() ?? d['address']?.toString() ?? '',
      images: _toStringList(d['images']),
      rating: _toDouble(d['rating'] ?? d['averageRating']),
      priceRange: d['priceRange']?.toString() ?? '\$',
      specialties: _toStringList(d['specialties'] ?? d['menu']),
      openingHours: d['openingHours']?.toString() ?? '',
      hasWifi: d['hasWifi'] == true,
      hasOutdoorSeating: d['hasOutdoorSeating'] == true,
      district: d['district']?.toString() ?? '',
      contactPhone:
          d['contactPhone']?.toString() ?? d['phone']?.toString() ?? '',
      ratingsCount:
          (d['ratingsCount'] as num?)?.toInt() ??
          (d['reviewCount'] as num?)?.toInt() ??
          0,
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HomestayModel
// ─────────────────────────────────────────────────────────────────────────────

class HomestayModel {
  final String id;
  final String name;
  final String description;
  final String location;
  final List<String> images;
  final double rating;
  final String priceRange;
  final List<String> amenities;
  final int maxGuests;
  final String hostName;
  final String hostPhoto;
  final bool hasBreakfast;
  final bool hasFreePickup;
  final String district;
  final String contactPhone;

  const HomestayModel({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.images,
    required this.rating,
    required this.priceRange,
    required this.amenities,
    required this.maxGuests,
    required this.hostName,
    required this.hostPhoto,
    required this.hasBreakfast,
    required this.hasFreePickup,
    required this.district,
    required this.contactPhone,
  });

  String get heroImage => _heroImage(images);

  factory HomestayModel.fromJson(Map<String, dynamic> json) => HomestayModel(
    id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    location: json['location']?.toString() ?? '',
    images: _toStringList(json['images']),
    rating: _toDouble(json['rating']),
    priceRange: json['priceRange']?.toString() ?? '\$\$',
    amenities: _toStringList(json['amenities']),
    maxGuests: (json['maxGuests'] as num?)?.toInt() ?? 2,
    hostName: json['hostName']?.toString() ?? '',
    hostPhoto: json['hostPhoto']?.toString() ?? '',
    hasBreakfast: json['hasBreakfast'] == true,
    hasFreePickup: json['hasFreePickup'] == true,
    district: json['district']?.toString() ?? '',
    contactPhone: json['contactPhone']?.toString() ?? '',
  );

  factory HomestayModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return HomestayModel(
      id: doc.id,
      name: d['name']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      location: d['location']?.toString() ?? d['address']?.toString() ?? '',
      images: _toStringList(d['images']),
      rating: _toDouble(d['rating'] ?? d['averageRating']),
      priceRange: d['priceRange']?.toString() ?? '\$\$',
      amenities: _toStringList(d['amenities']),
      maxGuests: (d['maxGuests'] as num?)?.toInt() ?? 2,
      hostName: d['hostName']?.toString() ?? d['ownerName']?.toString() ?? '',
      hostPhoto:
          d['hostPhoto']?.toString() ?? d['ownerPhoto']?.toString() ?? '',
      hasBreakfast: d['hasBreakfast'] == true,
      hasFreePickup: d['hasFreePickup'] == true,
      district: d['district']?.toString() ?? '',
      contactPhone:
          d['contactPhone']?.toString() ?? d['phone']?.toString() ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AdventureSpotModel  (collection: adventureSpots)
// ─────────────────────────────────────────────────────────────────────────────

class AdventureSpotModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String location;
  final List<String> images;
  final double rating;
  final String difficulty; // 'Easy' | 'Moderate' | 'Challenging' | 'Extreme'
  final String duration; // e.g. '2-3 hours'
  final String bestSeason;
  final List<String> activities;
  final bool isPopular;
  final String district;

  const AdventureSpotModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.location,
    required this.images,
    required this.rating,
    required this.difficulty,
    required this.duration,
    required this.bestSeason,
    required this.activities,
    required this.isPopular,
    required this.district,
  });

  String get heroImage => _heroImage(images);

  /// Colour hint for the difficulty badge.
  static String difficultyEmoji(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return '🟢';
      case 'moderate':
        return '🟡';
      case 'challenging':
        return '🔴';
      case 'extreme':
        return '⚫';
      default:
        return '⚪';
    }
  }

  factory AdventureSpotModel.fromJson(Map<String, dynamic> json) =>
      AdventureSpotModel(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        category: json['category']?.toString() ?? 'adventure',
        location: json['location']?.toString() ?? '',
        images: _toStringList(json['images']),
        rating: _toDouble(json['rating']),
        difficulty: json['difficulty']?.toString() ?? 'Moderate',
        duration: json['duration']?.toString() ?? '',
        bestSeason: json['bestSeason']?.toString() ?? '',
        activities: _toStringList(json['activities']),
        isPopular: json['isPopular'] == true,
        district: json['district']?.toString() ?? '',
      );

  factory AdventureSpotModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return AdventureSpotModel(
      id: doc.id,
      name: d['name']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      category: d['category']?.toString() ?? 'adventure',
      location: d['location']?.toString() ?? d['address']?.toString() ?? '',
      images: _toStringList(d['images']),
      rating: _toDouble(d['rating'] ?? d['averageRating']),
      difficulty: d['difficulty']?.toString() ?? 'Moderate',
      duration: d['duration']?.toString() ?? '',
      bestSeason: d['bestSeason']?.toString() ?? '',
      activities: _toStringList(d['activities']),
      isPopular: d['isPopular'] == true || d['featured'] == true,
      district: d['district']?.toString() ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ShoppingAreaModel  (collection: shoppingAreas)
// ─────────────────────────────────────────────────────────────────────────────

class ShoppingAreaModel {
  final String id;
  final String name;
  final String description;
  final String type; // 'market' | 'mall' | 'street' | 'boutique'
  final String location;
  final List<String> images;
  final double rating;
  final String openingHours;
  final List<String> products;
  final String priceRange;
  final bool hasParking;
  final bool acceptsCards;
  final bool hasDelivery;
  final bool isPopular;
  final String district;

  const ShoppingAreaModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.location,
    required this.images,
    required this.rating,
    required this.openingHours,
    required this.products,
    required this.priceRange,
    required this.hasParking,
    required this.acceptsCards,
    required this.hasDelivery,
    required this.isPopular,
    required this.district,
  });

  String get heroImage => _heroImage(images);

  factory ShoppingAreaModel.fromJson(Map<String, dynamic> json) =>
      ShoppingAreaModel(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        type: json['type']?.toString() ?? 'market',
        location: json['location']?.toString() ?? '',
        images: _toStringList(json['images']),
        rating: _toDouble(json['rating']),
        openingHours: json['openingHours']?.toString() ?? '',
        products: _toStringList(json['products']),
        priceRange: json['priceRange']?.toString() ?? '\$',
        hasParking: json['hasParking'] == true,
        acceptsCards: json['acceptsCards'] == true,
        hasDelivery: json['hasDelivery'] == true,
        isPopular: json['isPopular'] == true,
        district: json['district']?.toString() ?? '',
      );

  factory ShoppingAreaModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return ShoppingAreaModel(
      id: doc.id,
      name: d['name']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      type: d['type']?.toString() ?? 'market',
      location: d['location']?.toString() ?? d['address']?.toString() ?? '',
      images: _toStringList(d['images']),
      rating: _toDouble(d['rating'] ?? d['averageRating']),
      openingHours: d['openingHours']?.toString() ?? '',
      products: _toStringList(d['products'] ?? d['items']),
      priceRange: d['priceRange']?.toString() ?? '\$',
      hasParking: d['hasParking'] == true,
      acceptsCards:
          d['acceptsCards'] == true || d['acceptsCreditCards'] == true,
      hasDelivery: d['hasDelivery'] == true,
      isPopular: d['isPopular'] == true || d['featured'] == true,
      district: d['district']?.toString() ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EventModel  (collection: events)
// ─────────────────────────────────────────────────────────────────────────────

class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime? date;
  final String time;
  final int attendees;
  final String category;
  final String imageUrl;
  final String type; // 'festival' | 'cultural' | 'adventure' | 'personal'
  final String status; // 'Published' | 'Draft'
  final String district;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.time,
    required this.attendees,
    required this.category,
    required this.imageUrl,
    required this.type,
    required this.status,
    required this.district,
  });

  bool get isUpcoming {
    if (date == null) return false;
    return date!.isAfter(DateTime.now().subtract(const Duration(days: 1)));
  }

  /// Matches web's event-type colour coding.
  static String typeEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'festival':
        return '🎉';
      case 'cultural':
        return '🎭';
      case 'adventure':
        return '🧗';
      case 'personal':
        return '👤';
      default:
        return '📅';
    }
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['date'] ?? json['rawDate'];
    if (rawDate != null) {
      try {
        if (rawDate is int) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
        } else {
          parsedDate = DateTime.parse(rawDate.toString());
        }
      } catch (_) {}
    }

    return EventModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      date: parsedDate,
      time: json['time']?.toString() ?? '',
      attendees: (json['attendees'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      type: json['type']?.toString() ?? 'cultural',
      status: json['status']?.toString() ?? 'Published',
      district: json['district']?.toString() ?? '',
    );
  }

  factory EventModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? parsedDate;
    final rawDate = d['date'] ?? d['eventDate'] ?? d['startDate'];
    if (rawDate != null) {
      try {
        if (rawDate is Timestamp) {
          parsedDate = rawDate.toDate();
        } else if (rawDate is int) {
          parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
        } else {
          parsedDate = DateTime.parse(rawDate.toString());
        }
      } catch (_) {}
    }
    final images = _toStringList(d['images']);
    final imageUrl =
        d['imageUrl']?.toString() ??
        d['image']?.toString() ??
        (images.isNotEmpty ? images.first : '');
    return EventModel(
      id: doc.id,
      title: d['title']?.toString() ?? d['name']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      location: d['location']?.toString() ?? d['venue']?.toString() ?? '',
      date: parsedDate,
      time: d['time']?.toString() ?? d['startTime']?.toString() ?? '',
      attendees:
          (d['attendees'] as num?)?.toInt() ??
          (d['attendeeCount'] as num?)?.toInt() ??
          0,
      category: d['category']?.toString() ?? '',
      imageUrl: imageUrl,
      type: d['type']?.toString() ?? 'cultural',
      status: d['status']?.toString() ?? 'Published',
      district: d['district']?.toString() ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ListingCategory  — enum used by the tabbed listings screen
// ─────────────────────────────────────────────────────────────────────────────

enum ListingCategory {
  touristSpots,
  restaurants,
  accommodation,
  cafes,
  adventure,
  shopping,
  events;

  String get label {
    switch (this) {
      case touristSpots:
        return 'Tourist Spots';
      case restaurants:
        return 'Restaurants';
      case accommodation:
        return 'Stay';
      case cafes:
        return 'Cafes';
      case adventure:
        return 'Adventure';
      case shopping:
        return 'Shopping';
      case events:
        return 'Events';
    }
  }

  IconData get icon {
    switch (this) {
      case touristSpots:
        return Iconsax.map_1;
      case restaurants:
        return Iconsax.cup;
      case accommodation:
        return Iconsax.buildings;
      case cafes:
        return Iconsax.coffee;
      case adventure:
        return Iconsax.activity;
      case shopping:
        return Iconsax.bag_2;
      case events:
        return Iconsax.calendar;
    }
  }

  String get emoji {
    switch (this) {
      case touristSpots:    return '📍';
      case restaurants:     return '🍽️';
      case accommodation:   return '🏨';
      case cafes:           return '☕';
      case adventure:       return '🧗';
      case shopping:        return '🛍️';
      case events:          return '🎉';
    }
  }
}
