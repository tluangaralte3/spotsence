// lib/models/tour_package_models.dart
//
// Tour Venture models — activity packages such as bird watching, fishing,
// eco-tourism etc. with pricing tiers, seasonality, and booking details.

// ─────────────────────────────────────────────────────────────────────────────
// Helpers (shared with other models)
// ─────────────────────────────────────────────────────────────────────────────

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
// PackageCategory
// ─────────────────────────────────────────────────────────────────────────────

enum PackageCategory {
  birdWatching,
  fishing,
  ecoTourism,
  trekking,
  camping,
  photography,
  cultural,
  wildlifeSafari,
  rafting,
  cycling,
  wellness,
  other;

  String get label => switch (this) {
    PackageCategory.birdWatching => 'Bird Watching',
    PackageCategory.fishing => 'Fishing',
    PackageCategory.ecoTourism => 'Eco Tourism',
    PackageCategory.trekking => 'Trekking',
    PackageCategory.camping => 'Camping',
    PackageCategory.photography => 'Photography',
    PackageCategory.cultural => 'Cultural',
    PackageCategory.wildlifeSafari => 'Wildlife Safari',
    PackageCategory.rafting => 'Rafting',
    PackageCategory.cycling => 'Cycling',
    PackageCategory.wellness => 'Wellness',
    PackageCategory.other => 'Other',
  };

  String get emoji => switch (this) {
    PackageCategory.birdWatching => '🦜',
    PackageCategory.fishing => '🎣',
    PackageCategory.ecoTourism => '🌿',
    PackageCategory.trekking => '🥾',
    PackageCategory.camping => '⛺',
    PackageCategory.photography => '📸',
    PackageCategory.cultural => '🎭',
    PackageCategory.wildlifeSafari => '🦏',
    PackageCategory.rafting => '🚣',
    PackageCategory.cycling => '🚴',
    PackageCategory.wellness => '🧘',
    PackageCategory.other => '🎒',
  };

  static PackageCategory fromString(String s) {
    return PackageCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == s.toLowerCase().replaceAll(' ', ''),
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

  // For colour coding in UI
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
    return PackageSeason.values.firstWhere(
      (p) => p.name.toLowerCase() == s.toLowerCase().replaceAll(' ', ''),
      orElse: () => PackageSeason.allYear,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PricingTier  — single tier inside a package (e.g. Solo / Couple / Group)
// ─────────────────────────────────────────────────────────────────────────────

class PricingTier {
  final String id;
  final String name; // e.g. "Solo Explorer", "Couple Package", "Group of 6"
  final double pricePerPerson; // INR
  final int minPersons;
  final int maxPersons;
  final String description; // What's included at this tier
  final List<String> includes; // ["Guide", "Meals", "Transport"]
  final List<String> excludes; // ["Accommodation", "Travel insurance"]
  final bool isPopular; // highlight "Most Popular" badge
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
    minPersons: (json['minPersons'] as num?)?.toInt() ?? 1,
    maxPersons: (json['maxPersons'] as num?)?.toInt() ?? 1,
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
// ScheduleSlot  — a single bookable time block
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleSlot {
  final String id;
  final String label; // e.g. "Morning session", "Full-day", "Overnight"
  final String startTime; // "06:00"
  final String endTime; // "12:00"
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
    durationHours: (json['durationHours'] as num?)?.toInt() ?? 0,
    maxGroupSize: (json['maxGroupSize'] as num?)?.toInt() ?? 10,
    spotsLeft: (json['spotsLeft'] as num?)?.toInt() ?? 0,
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
// OperatorInfo  — the tour/activity operator
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
    totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
    isVerified: json['isVerified'] as bool? ?? false,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// TourVentureModel  — the main document stored in Firestore: tour_packages
// ─────────────────────────────────────────────────────────────────────────────

class TourVentureModel {
  final String id;
  final String title;
  final String tagline; // Short marketing line
  final String description; // Long markdown-friendly text
  final List<String> images; // gallery
  final PackageCategory category;
  final List<PackageSeason> seasons; // months when available
  final DifficultyLevel difficulty;
  final String location; // Human-readable e.g. "Phawngpui, Lawngtlai"
  final String district;
  final double? latitude;
  final double? longitude;

  // Timing
  final int durationDays; // 0 = same day
  final int durationNights; // 0 = no overnight
  final String departurePeriod; // "Daily", "Weekends only", "On request"

  // Pricing  (tiers give different people-counts / inclusions)
  final List<PricingTier> pricingTiers;
  final double startingPrice; // lowest price across tiers for display

  // Schedule slots for the day
  final List<ScheduleSlot> scheduleSlots;

  // Content
  final List<String> highlights; // bullet points on card/detail
  final List<String> whatToExpect;
  final List<String> whatToBring; // packing list
  final List<String> languages; // Guide languages
  final List<String> tags; // search tags e.g. ['birding','wildlife']

  // Metadata
  final OperatorInfo? operator;
  final bool isFeatured;
  final bool isAvailable;
  final double averageRating;
  final int ratingsCount;
  final int bookingsCount;
  final String status; // 'active' | 'draft' | 'suspended'
  final String cancellationPolicy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Booking config
  final int advanceBookingDays; // minimum days ahead to book
  final int maxGroupSize;
  final int minAge; // minimum age in years, 0 = no restriction
  final bool instantBooking; // true = no approval needed

  const TourVentureModel({
    required this.id,
    required this.title,
    required this.tagline,
    required this.description,
    required this.images,
    required this.category,
    required this.seasons,
    required this.difficulty,
    required this.location,
    required this.district,
    this.latitude,
    this.longitude,
    this.durationDays = 1,
    this.durationNights = 0,
    this.departurePeriod = 'Daily',
    this.pricingTiers = const [],
    this.startingPrice = 0,
    this.scheduleSlots = const [],
    this.highlights = const [],
    this.whatToExpect = const [],
    this.whatToBring = const [],
    this.languages = const [],
    this.tags = const [],
    this.operator,
    this.isFeatured = false,
    this.isAvailable = true,
    this.averageRating = 0.0,
    this.ratingsCount = 0,
    this.bookingsCount = 0,
    this.status = 'active',
    this.cancellationPolicy = '',
    this.createdAt,
    this.updatedAt,
    this.advanceBookingDays = 1,
    this.maxGroupSize = 20,
    this.minAge = 0,
    this.instantBooking = true,
  });

  /// First image URL, or empty string.
  String get heroImage => images.isNotEmpty ? images.first : '';

  /// Human-readable duration string, e.g. "2 Days / 1 Night"
  String get durationLabel {
    if (durationDays == 0) return 'Half Day';
    if (durationNights == 0)
      return '$durationDays Day${durationDays > 1 ? 's' : ''}';
    return '$durationDays Day${durationDays > 1 ? 's' : ''} / '
        '$durationNights Night${durationNights > 1 ? 's' : ''}';
  }

  /// Whether any of the provided season matches the current list.
  bool isAvailableInSeason(PackageSeason s) =>
      seasons.isEmpty ||
      seasons.contains(PackageSeason.allYear) ||
      seasons.contains(s);

  factory TourVentureModel.fromJson(Map<String, dynamic> json) {
    // Parse pricingTiers
    final tiersRaw = json['pricingTiers'];
    final List<PricingTier> tiers = tiersRaw is List
        ? tiersRaw
              .whereType<Map<String, dynamic>>()
              .map(PricingTier.fromJson)
              .toList()
        : [];

    // Parse scheduleSlots
    final slotsRaw = json['scheduleSlots'];
    final List<ScheduleSlot> slots = slotsRaw is List
        ? slotsRaw
              .whereType<Map<String, dynamic>>()
              .map(ScheduleSlot.fromJson)
              .toList()
        : [];

    // Parse seasons
    final seasonsRaw = json['seasons'];
    final List<PackageSeason> seasons = seasonsRaw is List
        ? seasonsRaw.map((s) => PackageSeason.fromString(s.toString())).toList()
        : [PackageSeason.allYear];

    // Parse operator
    final opRaw = json['operator'];
    final OperatorInfo? operator = opRaw is Map<String, dynamic>
        ? OperatorInfo.fromJson(opRaw)
        : null;

    final id = json['id']?.toString() ?? json['_id']?.toString() ?? '';

    // Compute starting price from tiers if not stored
    double storedStarting = _toDouble(json['startingPrice']);
    if (storedStarting == 0 && tiers.isNotEmpty) {
      storedStarting = tiers
          .map((t) => t.pricePerPerson)
          .reduce((a, b) => a < b ? a : b);
    }

    return TourVentureModel(
      id: id,
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
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 1,
      durationNights: (json['durationNights'] as num?)?.toInt() ?? 0,
      departurePeriod: json['departurePeriod']?.toString() ?? 'Daily',
      pricingTiers: tiers,
      startingPrice: storedStarting,
      scheduleSlots: slots,
      highlights: _toStringList(json['highlights']),
      whatToExpect: _toStringList(json['whatToExpect']),
      whatToBring: _toStringList(json['whatToBring']),
      languages: _toStringList(json['languages']),
      tags: _toStringList(json['tags']),
      operator: operator,
      isFeatured: json['isFeatured'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      averageRating: _toDouble(json['averageRating']),
      ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
      bookingsCount: (json['bookingsCount'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'active',
      cancellationPolicy: json['cancellationPolicy']?.toString() ?? '',
      advanceBookingDays: (json['advanceBookingDays'] as num?)?.toInt() ?? 1,
      maxGroupSize: (json['maxGroupSize'] as num?)?.toInt() ?? 20,
      minAge: (json['minAge'] as num?)?.toInt() ?? 0,
      instantBooking: json['instantBooking'] as bool? ?? true,
    );
  }
}
