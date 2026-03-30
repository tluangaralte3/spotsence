// lib/models/tour_venture_models.dart
//
// Tour Venture models v2 — local activity packages (bird watching, fishing, hiking…)
// New: VentureAddon, RentalPartner, VentureChallenge, VentureAchievementMedal,
//      VentureRegistration, VentureFeedback

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

int _toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

List<String> _toStringList(dynamic v) {
  if (v == null) return [];
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}

// ─────────────────────────────────────────────────────────────────────────────
// PackageCategory
// ─────────────────────────────────────────────────────────────────────────────

enum PackageCategory {
  birdWatching,
  fishing,
  hiking,
  sunrise,
  ecoTourism,
  trekking,
  camping,
  photography,
  cultural,
  wildlifeSafari,
  rafting,
  cycling,
  running,
  wellness,
  stargazing,
  other;

  String get label => switch (this) {
    PackageCategory.birdWatching => 'Bird Watching',
    PackageCategory.fishing => 'Fishing',
    PackageCategory.hiking => 'Hiking',
    PackageCategory.sunrise => 'Sunrise Trek',
    PackageCategory.ecoTourism => 'Eco Tourism',
    PackageCategory.trekking => 'Trekking',
    PackageCategory.camping => 'Camping',
    PackageCategory.photography => 'Photography',
    PackageCategory.cultural => 'Cultural',
    PackageCategory.wildlifeSafari => 'Wildlife Safari',
    PackageCategory.rafting => 'Rafting',
    PackageCategory.cycling => 'Cycling',
    PackageCategory.running => 'Running',
    PackageCategory.wellness => 'Wellness',
    PackageCategory.stargazing => 'Stargazing',
    PackageCategory.other => 'Other',
  };

  String get emoji => switch (this) {
    PackageCategory.birdWatching => '🦜',
    PackageCategory.fishing => '🎣',
    PackageCategory.hiking => '🥾',
    PackageCategory.sunrise => '🌅',
    PackageCategory.ecoTourism => '🌿',
    PackageCategory.trekking => '⛰️',
    PackageCategory.camping => '⛺',
    PackageCategory.photography => '📸',
    PackageCategory.cultural => '🎭',
    PackageCategory.wildlifeSafari => '🦏',
    PackageCategory.rafting => '🚣',
    PackageCategory.cycling => '🚴',
    PackageCategory.running => '🏃',
    PackageCategory.wellness => '🧘',
    PackageCategory.stargazing => '🌌',
    PackageCategory.other => '🎒',
  };

  static PackageCategory fromString(String s) {
    final key = s.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    return PackageCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == key,
      orElse: () => PackageCategory.other,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DifficultyLevel
// ─────────────────────────────────────────────────────────────────────────────

enum DifficultyLevel {
  easy,
  moderate,
  challenging,
  extreme;

  String get label => switch (this) {
    DifficultyLevel.easy => 'Easy',
    DifficultyLevel.moderate => 'Moderate',
    DifficultyLevel.challenging => 'Challenging',
    DifficultyLevel.extreme => 'Extreme',
  };

  int get colorHex => switch (this) {
    DifficultyLevel.easy => 0xFF22C55E,
    DifficultyLevel.moderate => 0xFFF59E0B,
    DifficultyLevel.challenging => 0xFFEF4444,
    DifficultyLevel.extreme => 0xFF9C27B0,
  };

  static DifficultyLevel fromString(String s) {
    return DifficultyLevel.values.firstWhere(
      (d) => d.name.toLowerCase() == s.toLowerCase(),
      orElse: () => DifficultyLevel.moderate,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PackageSeason
// ─────────────────────────────────────────────────────────────────────────────

enum PackageSeason {
  allYear,
  spring,
  summer,
  autumn,
  winter,
  monsoon,
  preMonsoon,
  postMonsoon;

  String get label => switch (this) {
    PackageSeason.allYear => 'All Year',
    PackageSeason.spring => 'Spring (Mar–May)',
    PackageSeason.summer => 'Summer (Jun–Aug)',
    PackageSeason.autumn => 'Autumn (Sep–Nov)',
    PackageSeason.winter => 'Winter (Dec–Feb)',
    PackageSeason.monsoon => 'Monsoon (Jun–Sep)',
    PackageSeason.preMonsoon => 'Pre-Monsoon (Apr–May)',
    PackageSeason.postMonsoon => 'Post-Monsoon (Oct–Nov)',
  };

  String get emoji => switch (this) {
    PackageSeason.allYear => '📅',
    PackageSeason.spring => '🌸',
    PackageSeason.summer => '☀️',
    PackageSeason.autumn => '🍂',
    PackageSeason.winter => '❄️',
    PackageSeason.monsoon => '🌧️',
    PackageSeason.preMonsoon => '🌤️',
    PackageSeason.postMonsoon => '🌈',
  };

  static PackageSeason fromString(String s) {
    final key = s.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    return PackageSeason.values.firstWhere(
      (p) => p.name.toLowerCase() == key,
      orElse: () => PackageSeason.allYear,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MedalTier
// ─────────────────────────────────────────────────────────────────────────────

enum MedalTier {
  bronze,
  silver,
  gold,
  platinum,
  legendary;

  String get label => switch (this) {
    MedalTier.bronze => 'Bronze',
    MedalTier.silver => 'Silver',
    MedalTier.gold => 'Gold',
    MedalTier.platinum => 'Platinum',
    MedalTier.legendary => 'Legendary',
  };

  String get emoji => switch (this) {
    MedalTier.bronze => '🥉',
    MedalTier.silver => '🥈',
    MedalTier.gold => '🥇',
    MedalTier.platinum => '💎',
    MedalTier.legendary => '🏆',
  };

  int get colorHex => switch (this) {
    MedalTier.bronze => 0xFFCD7F32,
    MedalTier.silver => 0xFFC0C0C0,
    MedalTier.gold => 0xFFFFD700,
    MedalTier.platinum => 0xFF00CED1,
    MedalTier.legendary => 0xFF9B59B6,
  };

  static MedalTier fromString(String s) {
    return MedalTier.values.firstWhere(
      (m) => m.name.toLowerCase() == s.toLowerCase(),
      orElse: () => MedalTier.bronze,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PricingTier
// ─────────────────────────────────────────────────────────────────────────────

class PricingTier {
  final String id;
  final String name;
  final double pricePerPerson;
  final int minPersons;
  final int maxPersons;
  final String description;
  final List<String> includes;
  final List<String> excludes;
  final bool isPopular;
  final bool isAvailable;

  const PricingTier({
    required this.id,
    required this.name,
    required this.pricePerPerson,
    required this.minPersons,
    required this.maxPersons,
    this.description = '',
    this.includes = const [],
    this.excludes = const [],
    this.isPopular = false,
    this.isAvailable = true,
  });

  factory PricingTier.fromJson(Map<String, dynamic> json) => PricingTier(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    pricePerPerson: _toDouble(json['pricePerPerson']),
    minPersons: _toInt(json['minPersons'], 1),
    maxPersons: _toInt(json['maxPersons'], 1),
    description: json['description']?.toString() ?? '',
    includes: _toStringList(json['includes']),
    excludes: _toStringList(json['excludes']),
    isPopular: json['isPopular'] as bool? ?? false,
    isAvailable: json['isAvailable'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'pricePerPerson': pricePerPerson,
    'minPersons': minPersons,
    'maxPersons': maxPersons,
    'description': description,
    'includes': includes,
    'excludes': excludes,
    'isPopular': isPopular,
    'isAvailable': isAvailable,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// VentureAddon — optional gear/equipment add-on with extra pricing
// ─────────────────────────────────────────────────────────────────────────────

class VentureAddon {
  final String id;
  final String name; // e.g. "Binoculars", "Tent", "Fishing Rod"
  final String emoji;
  final double pricePerUnit; // INR
  final String unit; // "per person" | "per day" | "per set"
  final String description;
  final bool isAvailable;

  const VentureAddon({
    required this.id,
    required this.name,
    this.emoji = '🎒',
    required this.pricePerUnit,
    this.unit = 'per person',
    this.description = '',
    this.isAvailable = true,
  });

  factory VentureAddon.fromJson(Map<String, dynamic> json) => VentureAddon(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    emoji: json['emoji']?.toString() ?? '🎒',
    pricePerUnit: _toDouble(json['pricePerUnit']),
    unit: json['unit']?.toString() ?? 'per person',
    description: json['description']?.toString() ?? '',
    isAvailable: json['isAvailable'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'pricePerUnit': pricePerUnit,
    'unit': unit,
    'description': description,
    'isAvailable': isAvailable,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// RentalPartner — local rental shop / equipment partner
// ─────────────────────────────────────────────────────────────────────────────

class RentalPartner {
  final String id;
  final String name;
  final String phone;
  final String whatsapp;
  final String location;
  final String logoUrl;
  final List<String> itemsAvailable;
  final bool isVerified;

  const RentalPartner({
    required this.id,
    required this.name,
    this.phone = '',
    this.whatsapp = '',
    this.location = '',
    this.logoUrl = '',
    this.itemsAvailable = const [],
    this.isVerified = false,
  });

  factory RentalPartner.fromJson(Map<String, dynamic> json) => RentalPartner(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    whatsapp: json['whatsapp']?.toString() ?? '',
    location: json['location']?.toString() ?? '',
    logoUrl: json['logoUrl']?.toString() ?? '',
    itemsAvailable: _toStringList(json['itemsAvailable']),
    isVerified: json['isVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'whatsapp': whatsapp,
    'location': location,
    'logoUrl': logoUrl,
    'itemsAvailable': itemsAvailable,
    'isVerified': isVerified,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// VentureAchievementMedal — medal awarded on completing challenges
// ─────────────────────────────────────────────────────────────────────────────

class VentureAchievementMedal {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final MedalTier tier;
  final int pointsAwarded;
  final bool isSecret; // hidden in UI until earned

  const VentureAchievementMedal({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.tier = MedalTier.bronze,
    this.pointsAwarded = 10,
    this.isSecret = false,
  });

  factory VentureAchievementMedal.fromJson(Map<String, dynamic> json) =>
      VentureAchievementMedal(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString() ?? '',
        tier: MedalTier.fromString(json['tier']?.toString() ?? 'bronze'),
        pointsAwarded: _toInt(json['pointsAwarded'], 10),
        isSecret: json['isSecret'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'tier': tier.name,
    'pointsAwarded': pointsAwarded,
    'isSecret': isSecret,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// VentureChallenge — a dare / objective within the venture
// ─────────────────────────────────────────────────────────────────────────────

class VentureChallenge {
  final String id;
  final String title;
  final String description;
  final String instructions; // step-by-step how to complete
  final String proofRequired; // "Take a photo", "Record video", etc.
  final int pointsOnComplete;
  final String linkedMedalId; // award this medal on completion
  final DifficultyLevel difficulty;
  final bool isOptional;
  final int orderIndex;

  const VentureChallenge({
    required this.id,
    required this.title,
    this.description = '',
    this.instructions = '',
    this.proofRequired = '',
    this.pointsOnComplete = 50,
    this.linkedMedalId = '',
    this.difficulty = DifficultyLevel.moderate,
    this.isOptional = true,
    this.orderIndex = 0,
  });

  factory VentureChallenge.fromJson(Map<String, dynamic> json) =>
      VentureChallenge(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        instructions: json['instructions']?.toString() ?? '',
        proofRequired: json['proofRequired']?.toString() ?? '',
        pointsOnComplete: _toInt(json['pointsOnComplete'], 50),
        linkedMedalId: json['linkedMedalId']?.toString() ?? '',
        difficulty: DifficultyLevel.fromString(
          json['difficulty']?.toString() ?? 'moderate',
        ),
        isOptional: json['isOptional'] as bool? ?? true,
        orderIndex: _toInt(json['orderIndex'], 0),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'instructions': instructions,
    'proofRequired': proofRequired,
    'pointsOnComplete': pointsOnComplete,
    'linkedMedalId': linkedMedalId,
    'difficulty': difficulty.name,
    'isOptional': isOptional,
    'orderIndex': orderIndex,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// ScheduleSlot
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleSlot {
  final String id;
  final String label;
  final String startTime;
  final String endTime;
  final int durationHours;
  final int maxGroupSize;
  final int spotsLeft;

  const ScheduleSlot({
    required this.id,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.maxGroupSize,
    this.spotsLeft = 0,
  });

  bool get isFull => spotsLeft <= 0;

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
    id: json['id']?.toString() ?? '',
    label: json['label']?.toString() ?? '',
    startTime: json['startTime']?.toString() ?? '',
    endTime: json['endTime']?.toString() ?? '',
    durationHours: _toInt(json['durationHours'], 0),
    maxGroupSize: _toInt(json['maxGroupSize'], 10),
    spotsLeft: _toInt(json['spotsLeft'], 0),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'startTime': startTime,
    'endTime': endTime,
    'durationHours': durationHours,
    'maxGroupSize': maxGroupSize,
    'spotsLeft': spotsLeft,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// OperatorInfo
// ─────────────────────────────────────────────────────────────────────────────

class OperatorInfo {
  final String name;
  final String phone;
  final String email;
  final String whatsapp;
  final String website;
  final String logoUrl;
  final double rating;
  final int totalReviews;
  final bool isVerified;

  const OperatorInfo({
    required this.name,
    this.phone = '',
    this.email = '',
    this.whatsapp = '',
    this.website = '',
    this.logoUrl = '',
    this.rating = 0.0,
    this.totalReviews = 0,
    this.isVerified = false,
  });

  factory OperatorInfo.fromJson(Map<String, dynamic> json) => OperatorInfo(
    name: json['name']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    whatsapp: json['whatsapp']?.toString() ?? '',
    website: json['website']?.toString() ?? '',
    logoUrl: json['logoUrl']?.toString() ?? '',
    rating: _toDouble(json['rating']),
    totalReviews: _toInt(json['totalReviews'], 0),
    isVerified: json['isVerified'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'email': email,
    'whatsapp': whatsapp,
    'website': website,
    'logoUrl': logoUrl,
    'rating': rating,
    'totalReviews': totalReviews,
    'isVerified': isVerified,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// TourVentureModel — Firestore collection: adventureSpots
// ─────────────────────────────────────────────────────────────────────────────

class TourVentureModel {
  final String id;
  final String title;
  final String tagline;
  final String description;
  final List<String> images;
  final PackageCategory category;
  final List<PackageSeason> seasons;
  final DifficultyLevel difficulty;
  final String location;
  final String district;
  final double? latitude;
  final double? longitude;

  // Timing
  final int durationDays;
  final int durationNights;
  final String departurePeriod;

  // Pricing
  final List<PricingTier> pricingTiers;
  final double startingPrice;

  // Gear add-ons & rentals
  final List<VentureAddon> addons;
  final List<RentalPartner> rentalPartners;

  // Schedule
  final List<ScheduleSlot> scheduleSlots;

  // Gamification
  final List<VentureChallenge> challenges;
  final List<VentureAchievementMedal> medals;
  final int totalPointsPossible;

  // Content
  final List<String> highlights;
  final List<String> whatToExpect;
  final List<String> whatToBring;
  final List<String> languages;
  final List<String> tags;
  final String safetyNotes;
  final String meetingPoint;
  final String cancellationPolicy;

  // Operator / guide
  final OperatorInfo? operator;

  // Metadata
  final bool isFeatured;
  final bool isAvailable;
  final double averageRating;
  final int ratingsCount;
  final int bookingsCount;
  final int registrationsCount;
  final String status; // 'active' | 'draft' | 'suspended'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Booking config
  final int advanceBookingDays;
  final int maxGroupSize;
  final int minAge;
  final bool instantBooking;
  final bool requiresApproval;

  const TourVentureModel({
    required this.id,
    required this.title,
    this.tagline = '',
    required this.description,
    this.images = const [],
    this.category = PackageCategory.other,
    this.seasons = const [PackageSeason.allYear],
    this.difficulty = DifficultyLevel.moderate,
    required this.location,
    this.district = '',
    this.latitude,
    this.longitude,
    this.durationDays = 1,
    this.durationNights = 0,
    this.departurePeriod = 'Daily',
    this.pricingTiers = const [],
    this.startingPrice = 0,
    this.addons = const [],
    this.rentalPartners = const [],
    this.scheduleSlots = const [],
    this.challenges = const [],
    this.medals = const [],
    this.totalPointsPossible = 0,
    this.highlights = const [],
    this.whatToExpect = const [],
    this.whatToBring = const [],
    this.languages = const [],
    this.tags = const [],
    this.safetyNotes = '',
    this.meetingPoint = '',
    this.cancellationPolicy = '',
    this.operator,
    this.isFeatured = false,
    this.isAvailable = true,
    this.averageRating = 0.0,
    this.ratingsCount = 0,
    this.bookingsCount = 0,
    this.registrationsCount = 0,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
    this.advanceBookingDays = 1,
    this.maxGroupSize = 20,
    this.minAge = 0,
    this.instantBooking = true,
    this.requiresApproval = false,
  });

  String get heroImage => images.isNotEmpty ? images.first : '';

  String get durationLabel {
    if (durationDays == 0) return 'Half Day';
    if (durationNights == 0) {
      return '$durationDays Day${durationDays > 1 ? 's' : ''}';
    }
    return '$durationDays Day${durationDays > 1 ? 's' : ''} / '
        '$durationNights Night${durationNights > 1 ? 's' : ''}';
  }

  bool isAvailableInSeason(PackageSeason s) =>
      seasons.isEmpty ||
      seasons.contains(PackageSeason.allYear) ||
      seasons.contains(s);

  static DateTime? _parseTs(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    return null;
  }

  factory TourVentureModel.fromJson(Map<String, dynamic> json) {
    final tiersRaw = json['pricingTiers'];
    final tiers = tiersRaw is List
        ? tiersRaw
              .whereType<Map<String, dynamic>>()
              .map(PricingTier.fromJson)
              .toList()
        : <PricingTier>[];

    final addonsRaw = json['addons'];
    final addons = addonsRaw is List
        ? addonsRaw
              .whereType<Map<String, dynamic>>()
              .map(VentureAddon.fromJson)
              .toList()
        : <VentureAddon>[];

    final rentalsRaw = json['rentalPartners'];
    final rentalPartners = rentalsRaw is List
        ? rentalsRaw
              .whereType<Map<String, dynamic>>()
              .map(RentalPartner.fromJson)
              .toList()
        : <RentalPartner>[];

    final slotsRaw = json['scheduleSlots'];
    final slots = slotsRaw is List
        ? slotsRaw
              .whereType<Map<String, dynamic>>()
              .map(ScheduleSlot.fromJson)
              .toList()
        : <ScheduleSlot>[];

    final challengesRaw = json['challenges'];
    final challenges = challengesRaw is List
        ? challengesRaw
              .whereType<Map<String, dynamic>>()
              .map(VentureChallenge.fromJson)
              .toList()
        : <VentureChallenge>[];

    final medalsRaw = json['medals'];
    final medals = medalsRaw is List
        ? medalsRaw
              .whereType<Map<String, dynamic>>()
              .map(VentureAchievementMedal.fromJson)
              .toList()
        : <VentureAchievementMedal>[];

    final seasonsRaw = json['seasons'];
    final seasons = seasonsRaw is List
        ? seasonsRaw.map((s) => PackageSeason.fromString(s.toString())).toList()
        : [PackageSeason.allYear];

    final opRaw = json['operator'];
    final operator = opRaw is Map<String, dynamic>
        ? OperatorInfo.fromJson(opRaw)
        : null;

    double startingPrice = _toDouble(json['startingPrice']);
    if (startingPrice == 0 && tiers.isNotEmpty) {
      startingPrice = tiers
          .map((t) => t.pricePerPerson)
          .reduce((a, b) => a < b ? a : b);
    }

    return TourVentureModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      images: _toStringList(json['images']),
      category: PackageCategory.fromString(
        json['category']?.toString() ?? 'other',
      ),
      seasons: seasons,
      difficulty: DifficultyLevel.fromString(
        json['difficulty']?.toString() ?? 'moderate',
      ),
      location: json['location']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      latitude: json['latitude'] != null ? _toDouble(json['latitude']) : null,
      longitude: json['longitude'] != null
          ? _toDouble(json['longitude'])
          : null,
      durationDays: _toInt(json['durationDays'], 1),
      durationNights: _toInt(json['durationNights'], 0),
      departurePeriod: json['departurePeriod']?.toString() ?? 'Daily',
      pricingTiers: tiers,
      startingPrice: startingPrice,
      addons: addons,
      rentalPartners: rentalPartners,
      scheduleSlots: slots,
      challenges: challenges,
      medals: medals,
      totalPointsPossible: _toInt(json['totalPointsPossible'], 0),
      highlights: _toStringList(json['highlights']),
      whatToExpect: _toStringList(json['whatToExpect']),
      whatToBring: _toStringList(json['whatToBring']),
      languages: _toStringList(json['languages']),
      tags: _toStringList(json['tags']),
      safetyNotes: json['safetyNotes']?.toString() ?? '',
      meetingPoint: json['meetingPoint']?.toString() ?? '',
      cancellationPolicy: json['cancellationPolicy']?.toString() ?? '',
      operator: operator,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      averageRating: _toDouble(json['averageRating']),
      ratingsCount: _toInt(json['ratingsCount'], 0),
      bookingsCount: _toInt(json['bookingsCount'], 0),
      registrationsCount: _toInt(json['registrationsCount'], 0),
      status: json['status']?.toString() ?? 'active',
      createdAt: _parseTs(json['createdAt']),
      updatedAt: _parseTs(json['updatedAt']),
      advanceBookingDays: _toInt(json['advanceBookingDays'], 1),
      maxGroupSize: _toInt(json['maxGroupSize'], 20),
      minAge: _toInt(json['minAge'], 0),
      instantBooking: json['instantBooking'] as bool? ?? true,
      requiresApproval: json['requiresApproval'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'title': title,
    'tagline': tagline,
    'description': description,
    'images': images,
    'category': category.name,
    'seasons': seasons.map((s) => s.name).toList(),
    'difficulty': difficulty.name,
    'location': location,
    'district': district,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
    'durationDays': durationDays,
    'durationNights': durationNights,
    'departurePeriod': departurePeriod,
    'pricingTiers': pricingTiers.map((t) => t.toJson()).toList(),
    'startingPrice': startingPrice,
    'addons': addons.map((a) => a.toJson()).toList(),
    'rentalPartners': rentalPartners.map((r) => r.toJson()).toList(),
    'scheduleSlots': scheduleSlots.map((s) => s.toJson()).toList(),
    'challenges': challenges.map((c) => c.toJson()).toList(),
    'medals': medals.map((m) => m.toJson()).toList(),
    'totalPointsPossible': totalPointsPossible,
    'highlights': highlights,
    'whatToExpect': whatToExpect,
    'whatToBring': whatToBring,
    'languages': languages,
    'tags': tags,
    'safetyNotes': safetyNotes,
    'meetingPoint': meetingPoint,
    'cancellationPolicy': cancellationPolicy,
    if (operator != null) 'operator': operator!.toJson(),
    'isFeatured': isFeatured,
    'isAvailable': isAvailable,
    'averageRating': averageRating,
    'ratingsCount': ratingsCount,
    'bookingsCount': bookingsCount,
    'registrationsCount': registrationsCount,
    'status': status,
    'advanceBookingDays': advanceBookingDays,
    'maxGroupSize': maxGroupSize,
    'minAge': minAge,
    'instantBooking': instantBooking,
    'requiresApproval': requiresApproval,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// VentureRegistration — sub-collection: adventureSpots/{id}/registrations
// ─────────────────────────────────────────────────────────────────────────────

class VentureRegistration {
  final String id;
  final String ventureId;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String tierId;
  final String tierName;
  final List<String> selectedAddonIds;
  final int numberOfPersons;
  final DateTime? preferredDate;
  final String slotId;
  final String notes;
  final String status; // 'pending' | 'confirmed' | 'cancelled' | 'completed'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VentureRegistration({
    required this.id,
    required this.ventureId,
    required this.userId,
    required this.userName,
    this.userEmail = '',
    this.userPhone = '',
    this.tierId = '',
    this.tierName = '',
    this.selectedAddonIds = const [],
    this.numberOfPersons = 1,
    this.preferredDate,
    this.slotId = '',
    this.notes = '',
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'ventureId': ventureId,
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'userPhone': userPhone,
    'tierId': tierId,
    'tierName': tierName,
    'selectedAddonIds': selectedAddonIds,
    'numberOfPersons': numberOfPersons,
    if (preferredDate != null)
      'preferredDate': Timestamp.fromDate(preferredDate!),
    'slotId': slotId,
    'notes': notes,
    'status': status,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory VentureRegistration.fromJson(Map<String, dynamic> json) =>
      VentureRegistration(
        id: json['id']?.toString() ?? '',
        ventureId: json['ventureId']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        userEmail: json['userEmail']?.toString() ?? '',
        userPhone: json['userPhone']?.toString() ?? '',
        tierId: json['tierId']?.toString() ?? '',
        tierName: json['tierName']?.toString() ?? '',
        selectedAddonIds: _toStringList(json['selectedAddonIds']),
        numberOfPersons: _toInt(json['numberOfPersons'], 1),
        preferredDate: TourVentureModel._parseTs(json['preferredDate']),
        slotId: json['slotId']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        createdAt: TourVentureModel._parseTs(json['createdAt']),
        updatedAt: TourVentureModel._parseTs(json['updatedAt']),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// VentureFeedback — sub-collection: adventureSpots/{id}/feedback
// ─────────────────────────────────────────────────────────────────────────────

class VentureFeedback {
  final String id;
  final String ventureId;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final double rating;
  final String comment;
  final List<String> tags;
  final List<String> photoUrls;
  final List<String> completedChallengeIds;
  final List<String> earnedMedalIds;
  final DateTime? createdAt;

  const VentureFeedback({
    required this.id,
    required this.ventureId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl = '',
    required this.rating,
    this.comment = '',
    this.tags = const [],
    this.photoUrls = const [],
    this.completedChallengeIds = const [],
    this.earnedMedalIds = const [],
    this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'ventureId': ventureId,
    'userId': userId,
    'userName': userName,
    'userAvatarUrl': userAvatarUrl,
    'rating': rating,
    'comment': comment,
    'tags': tags,
    'photoUrls': photoUrls,
    'completedChallengeIds': completedChallengeIds,
    'earnedMedalIds': earnedMedalIds,
    'createdAt': FieldValue.serverTimestamp(),
  };

  factory VentureFeedback.fromJson(Map<String, dynamic> json) =>
      VentureFeedback(
        id: json['id']?.toString() ?? '',
        ventureId: json['ventureId']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        userName: json['userName']?.toString() ?? '',
        userAvatarUrl: json['userAvatarUrl']?.toString() ?? '',
        rating: _toDouble(json['rating']),
        comment: json['comment']?.toString() ?? '',
        tags: _toStringList(json['tags']),
        photoUrls: _toStringList(json['photoUrls']),
        completedChallengeIds: _toStringList(json['completedChallengeIds']),
        earnedMedalIds: _toStringList(json['earnedMedalIds']),
        createdAt: TourVentureModel._parseTs(json['createdAt']),
      );
}
