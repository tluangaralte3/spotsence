import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// XP Action definitions — single source of truth for every earnable action
// ─────────────────────────────────────────────────────────────────────────────

enum XpAction {
  writeReview, // +15  — user submits a star rating + comment
  uploadPhoto, // +10  — user uploads a community photo on a spot
  createBucketList, // +20  — user creates a new bucket list
  completeBucketItem, // +10  — user checks off an item from their bucket list
  createDilemma, // +25  — user posts a new dilemma
  voteDilemma, // +5   — user casts a vote on any dilemma
  dailyLogin, // +5   — first app open of the day (streak seed)
  streakBonus, // +10  — awarded on top of dailyLogin when streak >= 3
  weeklyStreak, // +30  — bonus at exactly 7-day streak
  monthlyStreak, // +100 — bonus at exactly 30-day streak
}

extension XpActionX on XpAction {
  int get baseXp => const {
    XpAction.writeReview: 15,
    XpAction.uploadPhoto: 10,
    XpAction.createBucketList: 20,
    XpAction.completeBucketItem: 10,
    XpAction.createDilemma: 25,
    XpAction.voteDilemma: 5,
    XpAction.dailyLogin: 5,
    XpAction.streakBonus: 10,
    XpAction.weeklyStreak: 30,
    XpAction.monthlyStreak: 100,
  }[this]!;

  String get label => const {
    XpAction.writeReview: 'Wrote a review',
    XpAction.uploadPhoto: 'Uploaded a photo',
    XpAction.createBucketList: 'Created a bucket list',
    XpAction.completeBucketItem: 'Completed a bucket list item',
    XpAction.createDilemma: 'Posted a dilemma',
    XpAction.voteDilemma: 'Voted on a dilemma',
    XpAction.dailyLogin: 'Daily login',
    XpAction.streakBonus: 'Streak bonus!',
    XpAction.weeklyStreak: '7-day streak!',
    XpAction.monthlyStreak: '30-day streak!',
  }[this]!;

  String get emoji => const {
    XpAction.writeReview: '⭐',
    XpAction.uploadPhoto: '📸',
    XpAction.createBucketList: '📋',
    XpAction.completeBucketItem: '✅',
    XpAction.createDilemma: '🤔',
    XpAction.voteDilemma: '🗳️',
    XpAction.dailyLogin: '🌅',
    XpAction.streakBonus: '🔥',
    XpAction.weeklyStreak: '🔥',
    XpAction.monthlyStreak: '👑',
  }[this]!;
}

// ─────────────────────────────────────────────────────────────────────────────
// XP Event  — written to users/{uid}/xpEvents for the activity feed
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class XpEvent {
  final String id;
  final XpAction action;
  final int xpEarned;
  final DateTime createdAt;
  final String? relatedId; // spotId, dilemmaId, etc.

  const XpEvent({
    required this.id,
    required this.action,
    required this.xpEarned,
    required this.createdAt,
    this.relatedId,
  });

  factory XpEvent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    final ts = d['createdAt'];
    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();
    return XpEvent(
      id: snap.id,
      action: XpAction.values.firstWhere(
        (a) => a.name == (d['action'] as String?),
        orElse: () => XpAction.dailyLogin,
      ),
      xpEarned: (d['xpEarned'] as num?)?.toInt() ?? 0,
      createdAt: dt,
      relatedId: d['relatedId'] as String?,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak Info — parsed from user document
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class StreakInfo {
  final int currentStreak; // consecutive days
  final int longestStreak; // all-time best
  final DateTime? lastLogin; // date of last recorded login

  const StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    this.lastLogin,
  });

  const StreakInfo.empty()
    : currentStreak = 0,
      longestStreak = 0,
      lastLogin = null;

  factory StreakInfo.fromMap(Map<String, dynamic> d) {
    final ts = d['lastLogin'];
    return StreakInfo(
      currentStreak: (d['loginStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (d['longestStreak'] as num?)?.toInt() ?? 0,
      lastLogin: ts is Timestamp ? ts.toDate() : null,
    );
  }

  /// Streak fire emoji display string, e.g. "🔥 5"
  String get display => '🔥 $currentStreak';

  /// Multiplier for XP: every 5 consecutive days adds +10 %, capped at ×2.0
  double get xpMultiplier =>
      (1.0 + (currentStreak ~/ 5) * 0.10).clamp(1.0, 2.0);
}

// ─────────────────────────────────────────────────────────────────────────────
// GamificationResult — returned from GamificationService.award()
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class GamificationResult {
  final int xpAwarded;
  final List<String> newBadgeIds; // badge IDs just unlocked this action
  final bool leveledUp;
  final int newLevel;
  final int totalPoints;
  final StreakInfo streak;

  const GamificationResult({
    required this.xpAwarded,
    required this.newBadgeIds,
    required this.leveledUp,
    required this.newLevel,
    required this.totalPoints,
    required this.streak,
  });

  bool get hasReward => xpAwarded > 0 || newBadgeIds.isNotEmpty || leveledUp;
}

// ─────────────────────────────────────────────────────────────────────────────
// Level Info
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class LevelInfo {
  final int level;
  final String title;
  final int minPoints;
  final int maxPoints;

  const LevelInfo({
    required this.level,
    required this.title,
    required this.minPoints,
    required this.maxPoints,
  });

  static const List<LevelInfo> levels = [
    LevelInfo(level: 1, title: 'Explorer', minPoints: 0, maxPoints: 99),
    LevelInfo(level: 2, title: 'Wanderer', minPoints: 100, maxPoints: 249),
    LevelInfo(level: 3, title: 'Adventurer', minPoints: 250, maxPoints: 499),
    LevelInfo(level: 4, title: 'Pathfinder', minPoints: 500, maxPoints: 999),
    LevelInfo(level: 5, title: 'Guide', minPoints: 1000, maxPoints: 1999),
    LevelInfo(level: 6, title: 'Expert', minPoints: 2000, maxPoints: 3999),
    LevelInfo(level: 7, title: 'Master', minPoints: 4000, maxPoints: 6999),
    LevelInfo(level: 8, title: 'Legend', minPoints: 7000, maxPoints: 9999),
    LevelInfo(level: 9, title: 'Champion', minPoints: 10000, maxPoints: 14999),
    LevelInfo(
      level: 10,
      title: 'Guardian',
      minPoints: 15000,
      maxPoints: 999999,
    ),
  ];

  static LevelInfo forPoints(int points) {
    for (final l in levels.reversed) {
      if (points >= l.minPoints) return l;
    }
    return levels.first;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

@immutable
class ReviewModel {
  final String userId;
  final String userName;
  final String? userPhoto;
  final double rating;
  final String comment;
  final String timestamp;

  const ReviewModel({
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
    userId: json['userId'] as String? ?? '',
    userName: json['userName'] as String? ?? '',
    userPhoto: json['userPhoto'] as String?,
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    comment: json['comment'] as String? ?? '',
    timestamp: json['timestamp'] as String? ?? '',
  );
}

@immutable
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String userName;
  final String? userPhoto;
  final int points;
  final int level;
  final String levelTitle;
  final int badgesCount;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.points,
    required this.level,
    required this.levelTitle,
    required this.badgesCount,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final badges =
        json['badges'] as List? ?? json['badgesEarned'] as List? ?? [];
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['id'] as String? ?? json['userId'] as String? ?? '',
      userName:
          json['displayName'] as String? ?? json['userName'] as String? ?? '',
      userPhoto: json['photoURL'] as String? ?? json['userPhoto'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      levelTitle: json['levelTitle'] as String? ?? 'Explorer',
      badgesCount: badges.length,
    );
  }
}

@immutable
class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String rarity; // common, rare, epic, legendary
  final String category;
  final int pointsReward;
  final bool earned;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.category,
    required this.pointsReward,
    required this.earned,
  });

  factory BadgeModel.fromJson(
    Map<String, dynamic> json, {
    bool earned = false,
  }) => BadgeModel(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    icon: json['icon'] as String? ?? '',
    rarity: json['rarity'] as String? ?? 'common',
    category: json['category'] as String? ?? '',
    pointsReward: (json['pointsReward'] as num?)?.toInt() ?? 0,
    earned: earned,
  );

  /// Badge rarity color mapping
  static const rarityColors = {
    'common': 0xFF9E9E9E,
    'rare': 0xFF42A5F5,
    'epic': 0xFFAB47BC,
    'legendary': 0xFFFFB300,
  };

  int get rarityColor => rarityColors[rarity] ?? 0xFF9E9E9E;

  // ── Pre-defined badge catalogue (mirrors web constants/badges.ts) ──────────
  static const List<BadgeModel> allBadges = [
    BadgeModel(
      id: 'first_review',
      name: 'First Review',
      description: 'Wrote your first review',
      icon: '⭐',
      rarity: 'common',
      category: 'reviews',
      pointsReward: 10,
      earned: false,
    ),
    BadgeModel(
      id: 'five_reviews',
      name: 'Reviewer',
      description: 'Wrote 5 reviews',
      icon: '📝',
      rarity: 'common',
      category: 'reviews',
      pointsReward: 20,
      earned: false,
    ),
    BadgeModel(
      id: 'twenty_reviews',
      name: 'Critic',
      description: 'Wrote 20 reviews',
      icon: '🏆',
      rarity: 'rare',
      category: 'reviews',
      pointsReward: 50,
      earned: false,
    ),
    BadgeModel(
      id: 'first_contribution',
      name: 'Contributor',
      description: 'Submitted your first spot',
      icon: '📍',
      rarity: 'common',
      category: 'contributions',
      pointsReward: 15,
      earned: false,
    ),
    BadgeModel(
      id: 'five_contributions',
      name: 'Explorer',
      description: 'Contributed 5 spots',
      icon: '🗺️',
      rarity: 'rare',
      category: 'contributions',
      pointsReward: 75,
      earned: false,
    ),
    BadgeModel(
      id: 'first_bookmark',
      name: 'Collector',
      description: 'Bookmarked your first spot',
      icon: '🔖',
      rarity: 'common',
      category: 'bookmarks',
      pointsReward: 5,
      earned: false,
    ),
    BadgeModel(
      id: 'level_5',
      name: 'Guide',
      description: 'Reached Level 5',
      icon: '🧭',
      rarity: 'rare',
      category: 'levels',
      pointsReward: 100,
      earned: false,
    ),
    BadgeModel(
      id: 'level_10',
      name: 'Guardian',
      description: 'Reached Level 10',
      icon: '👑',
      rarity: 'legendary',
      category: 'levels',
      pointsReward: 500,
      earned: false,
    ),
    BadgeModel(
      id: 'community_post',
      name: 'Social',
      description: 'Created your first community post',
      icon: '💬',
      rarity: 'common',
      category: 'community',
      pointsReward: 10,
      earned: false,
    ),
    BadgeModel(
      id: 'bucket_list',
      name: 'Planner',
      description: 'Created a bucket list',
      icon: '📋',
      rarity: 'common',
      category: 'community',
      pointsReward: 10,
      earned: false,
    ),
    BadgeModel(
      id: 'photo_explorer',
      name: 'Photographer',
      description: 'Uploaded 10 spot photos',
      icon: '📸',
      rarity: 'rare',
      category: 'media',
      pointsReward: 50,
      earned: false,
    ),
    BadgeModel(
      id: 'top_10',
      name: 'Top Explorer',
      description: 'Reached top 10 on leaderboard',
      icon: '🥇',
      rarity: 'epic',
      category: 'leaderboard',
      pointsReward: 200,
      earned: false,
    ),
    // ── Streak badges ─────────────────────────────────────────────────────────
    BadgeModel(
      id: 'streak_3',
      name: 'On a Roll',
      description: 'Logged in 3 days in a row',
      icon: '🔥',
      rarity: 'common',
      category: 'streaks',
      pointsReward: 15,
      earned: false,
    ),
    BadgeModel(
      id: 'streak_7',
      name: 'Week Warrior',
      description: 'Logged in 7 days in a row',
      icon: '🔥',
      rarity: 'rare',
      category: 'streaks',
      pointsReward: 50,
      earned: false,
    ),
    BadgeModel(
      id: 'streak_30',
      name: 'Unstoppable',
      description: 'Logged in 30 days in a row',
      icon: '💎',
      rarity: 'legendary',
      category: 'streaks',
      pointsReward: 300,
      earned: false,
    ),
    // ── Dilemma badges ────────────────────────────────────────────────────────
    BadgeModel(
      id: 'first_dilemma',
      name: 'Torn',
      description: 'Posted your first dilemma',
      icon: '🤔',
      rarity: 'common',
      category: 'dilemmas',
      pointsReward: 10,
      earned: false,
    ),
    BadgeModel(
      id: 'dilemma_voter',
      name: 'Poll Master',
      description: 'Voted on 10 dilemmas',
      icon: '🗳️',
      rarity: 'rare',
      category: 'dilemmas',
      pointsReward: 40,
      earned: false,
    ),
    // ── Bucket list badges ────────────────────────────────────────────────────
    BadgeModel(
      id: 'bucket_complete_1',
      name: 'Ticked Off',
      description: 'Completed your first bucket list item',
      icon: '✅',
      rarity: 'common',
      category: 'bucket_lists',
      pointsReward: 10,
      earned: false,
    ),
    BadgeModel(
      id: 'bucket_complete_10',
      name: 'Go-Getter',
      description: 'Completed 10 bucket list items',
      icon: '🏁',
      rarity: 'rare',
      category: 'bucket_lists',
      pointsReward: 75,
      earned: false,
    ),
    // ── Social badges ─────────────────────────────────────────────────────────
    BadgeModel(
      id: 'early_adopter',
      name: 'Early Adopter',
      description: 'One of the first 100 users of SpotMizoram',
      icon: '🚀',
      rarity: 'legendary',
      category: 'special',
      pointsReward: 100,
      earned: false,
    ),
    BadgeModel(
      id: 'fifty_reviews',
      name: 'Authority',
      description: 'Wrote 50 reviews',
      icon: '🎖️',
      rarity: 'epic',
      category: 'reviews',
      pointsReward: 150,
      earned: false,
    ),
    BadgeModel(
      id: 'ten_contributions',
      name: 'Cartographer',
      description: 'Contributed 10 spots to the map',
      icon: '🗺️',
      rarity: 'epic',
      category: 'contributions',
      pointsReward: 150,
      earned: false,
    ),
    BadgeModel(
      id: 'photo_master',
      name: 'Lens Master',
      description: 'Uploaded 25 spot photos',
      icon: '📷',
      rarity: 'epic',
      category: 'media',
      pointsReward: 120,
      earned: false,
    ),
  ];

  // ── Badge evaluation ── called after every XP action ─────────────────────

  /// Returns badge IDs that [userId] should be newly awarded given the
  /// updated counters. The caller is responsible for de-duplicating against
  /// already-earned badges.
  static List<String> evaluate({
    required List<String> alreadyEarned,
    required int ratingsCount,
    required int contributionsCount,
    required int photosCount,
    required int dilemmasCreated,
    required int dilemmasVoted,
    required int bucketListsCreated,
    required int bucketItemsCompleted,
    required int loginStreak,
    required int level,
    required int rank, // current leaderboard rank, 0 = unknown
  }) {
    final newBadges = <String>[];

    void check(String id, bool condition) {
      if (condition && !alreadyEarned.contains(id)) newBadges.add(id);
    }

    // Reviews
    check('first_review', ratingsCount >= 1);
    check('five_reviews', ratingsCount >= 5);
    check('twenty_reviews', ratingsCount >= 20);
    check('fifty_reviews', ratingsCount >= 50);

    // Contributions
    check('first_contribution', contributionsCount >= 1);
    check('five_contributions', contributionsCount >= 5);
    check('ten_contributions', contributionsCount >= 10);

    // Photos
    check('photo_explorer', photosCount >= 10);
    check('photo_master', photosCount >= 25);

    // Dilemmas
    check('first_dilemma', dilemmasCreated >= 1);
    check('dilemma_voter', dilemmasVoted >= 10);

    // Bucket lists
    check('bucket_list', bucketListsCreated >= 1);
    check('bucket_complete_1', bucketItemsCompleted >= 1);
    check('bucket_complete_10', bucketItemsCompleted >= 10);

    // Streaks
    check('streak_3', loginStreak >= 3);
    check('streak_7', loginStreak >= 7);
    check('streak_30', loginStreak >= 30);

    // Levels
    check('level_5', level >= 5);
    check('level_10', level >= 10);

    // Leaderboard
    check('top_10', rank > 0 && rank <= 10);

    return newBadges;
  }
}
