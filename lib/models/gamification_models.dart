import 'package:flutter/foundation.dart';

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
  ];
}
