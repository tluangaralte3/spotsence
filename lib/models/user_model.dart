import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Mirrors the Firestore `users` document + API /auth/me response.
@immutable
class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? bio;
  final String? location;
  final int role; // 0 = admin, 1 = user
  final int points;
  final int level;
  final String levelTitle;
  final List<String> badges;
  final List<String> badgesEarned;
  final int contributionsCount;
  final int ratingsCount;
  final int photosCount;
  final int dilemmasCreated;
  final int dilemmasVoted;
  final int bucketListsCreated;
  final int bucketItemsCompleted;
  final int loginStreak;
  final int longestStreak;
  final DateTime? lastLogin;
  final List<String> bookmarks;
  final String createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.bio,
    this.location,
    required this.role,
    required this.points,
    required this.level,
    required this.levelTitle,
    required this.badges,
    required this.badgesEarned,
    required this.contributionsCount,
    required this.ratingsCount,
    this.photosCount = 0,
    this.dilemmasCreated = 0,
    this.dilemmasVoted = 0,
    this.bucketListsCreated = 0,
    this.bucketItemsCompleted = 0,
    this.loginStreak = 0,
    this.longestStreak = 0,
    this.lastLogin,
    required this.bookmarks,
    required this.createdAt,
  });

  bool get isAdmin => role == 0;

  /// Whether this user's email matches the seeded super admin account.
  /// The authoritative check is the Firebase custom claim (`superAdmin: true`),
  /// but this is a quick advisory flag that works without a token refresh.
  static const _superAdminEmail = 'hillstechadmin@spotsence.com';
  bool get isSuperAdminEmail => email.trim().toLowerCase() == _superAdminEmail;

  /// Level thresholds matching the web app constants/points.ts
  static const _levelThresholds = [
    (level: 1, points: 0, title: 'Explorer'),
    (level: 2, points: 100, title: 'Wanderer'),
    (level: 3, points: 250, title: 'Adventurer'),
    (level: 4, points: 500, title: 'Pathfinder'),
    (level: 5, points: 1000, title: 'Guide'),
    (level: 6, points: 2000, title: 'Expert'),
    (level: 7, points: 3500, title: 'Master'),
    (level: 8, points: 5500, title: 'Legend'),
    (level: 9, points: 8500, title: 'Champion'),
    (level: 10, points: 12500, title: 'Guardian'),
  ];

  static int calculateLevel(int pts) {
    int lvl = 1;
    for (final t in _levelThresholds) {
      if (pts >= t.points) lvl = t.level;
    }
    return lvl;
  }

  static String getLevelTitle(int lvl) {
    return _levelThresholds
        .firstWhere(
          (t) => t.level == lvl,
          orElse: () => (level: 1, points: 0, title: 'Explorer'),
        )
        .title;
  }

  /// Points needed to reach the next level.
  int get pointsToNextLevel {
    final next = _levelThresholds.where((t) => t.level == level + 1);
    if (next.isEmpty) return 0;
    return next.first.points - points;
  }

  /// Alias for pointsToNextLevel (used in profile UI).
  int get xpToNextLevel => pointsToNextLevel;

  /// 0.0–1.0 progress toward next level.
  double get levelProgress {
    final currentThreshold = _levelThresholds.firstWhere(
      (t) => t.level == level,
    );
    final nextThresholds = _levelThresholds.where((t) => t.level == level + 1);
    if (nextThresholds.isEmpty) return 1.0;
    final nextThreshold = nextThresholds.first;
    final range = nextThreshold.points - currentThreshold.points;
    final earned = points - currentThreshold.points;
    return (earned / range).clamp(0.0, 1.0);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final pts = (json['points'] as num?)?.toInt() ?? 0;
    final lvl = (json['level'] as num?)?.toInt() ?? calculateLevel(pts);
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'User',
      photoURL: json['photoURL'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      role: (json['role'] as num?)?.toInt() ?? 1,
      points: pts,
      level: lvl,
      levelTitle: getLevelTitle(lvl),
      badges: List<String>.from(json['badges'] as List? ?? []),
      badgesEarned: List<String>.from(json['badgesEarned'] as List? ?? []),
      contributionsCount: (json['contributionsCount'] as num?)?.toInt() ?? 0,
      ratingsCount: (json['ratingsCount'] as num?)?.toInt() ?? 0,
      photosCount: (json['photosCount'] as num?)?.toInt() ?? 0,
      dilemmasCreated: (json['dilemmasCreated'] as num?)?.toInt() ?? 0,
      dilemmasVoted: (json['dilemmasVoted'] as num?)?.toInt() ?? 0,
      bucketListsCreated: (json['bucketListsCreated'] as num?)?.toInt() ?? 0,
      bucketItemsCompleted:
          (json['bucketItemsCompleted'] as num?)?.toInt() ?? 0,
      loginStreak: (json['loginStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
      bookmarks: List<String>.from(json['bookmarks'] as List? ?? []),
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  /// Parse from a Firestore [DocumentSnapshot].
  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    final pts = (d['points'] as num?)?.toInt() ?? 0;
    final lvl = (d['level'] as num?)?.toInt() ?? calculateLevel(pts);
    return UserModel(
      id: snap.id,
      email: d['email'] as String? ?? '',
      displayName: d['displayName'] as String? ?? 'User',
      photoURL: d['photoURL'] as String?,
      bio: d['bio'] as String?,
      location: d['location'] as String?,
      role: (d['role'] as num?)?.toInt() ?? 1,
      points: pts,
      level: lvl,
      levelTitle: getLevelTitle(lvl),
      badges: List<String>.from(d['badges'] as List? ?? []),
      badgesEarned: List<String>.from(d['badgesEarned'] as List? ?? []),
      contributionsCount: (d['contributionsCount'] as num?)?.toInt() ?? 0,
      ratingsCount: (d['ratingsCount'] as num?)?.toInt() ?? 0,
      photosCount: (d['photosCount'] as num?)?.toInt() ?? 0,
      dilemmasCreated: (d['dilemmasCreated'] as num?)?.toInt() ?? 0,
      dilemmasVoted: (d['dilemmasVoted'] as num?)?.toInt() ?? 0,
      bucketListsCreated: (d['bucketListsCreated'] as num?)?.toInt() ?? 0,
      bucketItemsCompleted: (d['bucketItemsCompleted'] as num?)?.toInt() ?? 0,
      loginStreak: (d['loginStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (d['longestStreak'] as num?)?.toInt() ?? 0,
      lastLogin: d['lastLogin'] is Timestamp
          ? (d['lastLogin'] as Timestamp).toDate()
          : null,
      bookmarks: List<String>.from(d['bookmarks'] as List? ?? []),
      createdAt: d['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'photoURL': photoURL,
    'bio': bio,
    'location': location,
    'role': role,
    'points': points,
    'level': level,
    'levelTitle': levelTitle,
    'badges': badges,
    'badgesEarned': badgesEarned,
    'contributionsCount': contributionsCount,
    'ratingsCount': ratingsCount,
    'photosCount': photosCount,
    'dilemmasCreated': dilemmasCreated,
    'dilemmasVoted': dilemmasVoted,
    'bucketListsCreated': bucketListsCreated,
    'bucketItemsCompleted': bucketItemsCompleted,
    'loginStreak': loginStreak,
    'longestStreak': longestStreak,
    if (lastLogin != null) 'lastLogin': Timestamp.fromDate(lastLogin!),
    'bookmarks': bookmarks,
    'createdAt': createdAt,
  };

  UserModel copyWith({
    String? displayName,
    String? photoURL,
    String? bio,
    String? location,
    int? points,
    int? level,
    String? levelTitle,
    List<String>? badges,
    List<String>? badgesEarned,
    int? contributionsCount,
    int? ratingsCount,
    int? photosCount,
    int? dilemmasCreated,
    int? dilemmasVoted,
    int? bucketListsCreated,
    int? bucketItemsCompleted,
    int? loginStreak,
    int? longestStreak,
    DateTime? lastLogin,
    List<String>? bookmarks,
  }) {
    return UserModel(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      role: role,
      points: points ?? this.points,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      badges: badges ?? this.badges,
      badgesEarned: badgesEarned ?? this.badgesEarned,
      contributionsCount: contributionsCount ?? this.contributionsCount,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      photosCount: photosCount ?? this.photosCount,
      dilemmasCreated: dilemmasCreated ?? this.dilemmasCreated,
      dilemmasVoted: dilemmasVoted ?? this.dilemmasVoted,
      bucketListsCreated: bucketListsCreated ?? this.bucketListsCreated,
      bucketItemsCompleted: bucketItemsCompleted ?? this.bucketItemsCompleted,
      loginStreak: loginStreak ?? this.loginStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLogin: lastLogin ?? this.lastLogin,
      bookmarks: bookmarks ?? this.bookmarks,
      createdAt: createdAt,
    );
  }
}
