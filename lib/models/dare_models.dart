import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Sentinel object used in copyWith to distinguish null from "not provided".
const Object _dareSentinel = Object();

// ─────────────────────────────────────────────────────────────────────────────
// Free dare cap — users can host up to 5 dares for free
// ─────────────────────────────────────────────────────────────────────────────
const int kFreeDareCap = 5;

// ─────────────────────────────────────────────────────────────────────────────
// DareCategory — challenge categories
// ─────────────────────────────────────────────────────────────────────────────
enum DareCategory {
  adventure,
  foodRating,
  photography,
  wildlife,
  nightCamp,
  exploration,
  fitness,
  social,
  creative,
  travel,
  other;

  String get label {
    switch (this) {
      case adventure:
        return 'Adventure';
      case foodRating:
        return 'Food Rating';
      case photography:
        return 'Photography';
      case wildlife:
        return 'Wildlife';
      case nightCamp:
        return 'Night Camp';
      case exploration:
        return 'Exploration';
      case fitness:
        return 'Fitness';
      case social:
        return 'Social';
      case creative:
        return 'Creative';
      case travel:
        return 'Travel';
      case other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case adventure:
        return Iconsax.flash;
      case foodRating:
        return Iconsax.coffee;
      case photography:
        return Iconsax.camera;
      case wildlife:
        return Iconsax.tree;
      case nightCamp:
        return Iconsax.moon;
      case exploration:
        return Iconsax.map_1;
      case fitness:
        return Iconsax.activity;
      case social:
        return Iconsax.people;
      case creative:
        return Iconsax.brush_1;
      case travel:
        return Iconsax.global;
      case other:
        return Iconsax.element_4;
    }
  }

  Color get color {
    switch (this) {
      case adventure:
        return const Color(0xFFFF6B35);
      case foodRating:
        return const Color(0xFFFF9F1C);
      case photography:
        return const Color(0xFF6C63FF);
      case wildlife:
        return const Color(0xFF2EC4B6);
      case nightCamp:
        return const Color(0xFF5C6BC0);
      case exploration:
        return const Color(0xFF00E5A0);
      case fitness:
        return const Color(0xFFE71D36);
      case social:
        return const Color(0xFFEC407A);
      case creative:
        return const Color(0xFF9B5DE5);
      case travel:
        return const Color(0xFF0077B6);
      case other:
        return const Color(0xFF8892A4);
    }
  }

  static DareCategory fromString(String v) => DareCategory.values.firstWhere(
    (e) => e.name == v.toLowerCase(),
    orElse: () => DareCategory.other,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DareVisibility
// ─────────────────────────────────────────────────────────────────────────────
enum DareVisibility { public, private }

// ─────────────────────────────────────────────────────────────────────────────
// DareChallengeType — from app listing or custom
// ─────────────────────────────────────────────────────────────────────────────
enum DareChallengeType { appListing, custom }

// ─────────────────────────────────────────────────────────────────────────────
// MedalType — types of medals awarded on completion
// ─────────────────────────────────────────────────────────────────────────────
enum MedalType {
  bronze,
  silver,
  gold,
  platinum,
  special;

  String get label {
    switch (this) {
      case bronze:
        return 'Bronze';
      case silver:
        return 'Silver';
      case gold:
        return 'Gold';
      case platinum:
        return 'Platinum';
      case special:
        return 'Special';
    }
  }

  Color get color {
    switch (this) {
      case bronze:
        return const Color(0xFFCD7F32);
      case silver:
        return const Color(0xFFC0C0C0);
      case gold:
        return const Color(0xFFFFB300);
      case platinum:
        return const Color(0xFFE5E4E2);
      case special:
        return const Color(0xFF6C63FF);
    }
  }

  Color get bgColor {
    switch (this) {
      case bronze:
        return const Color(0xFF3D2510);
      case silver:
        return const Color(0xFF2A2A2A);
      case gold:
        return const Color(0xFF3D2E00);
      case platinum:
        return const Color(0xFF1A2030);
      case special:
        return const Color(0xFF1A0A3D);
    }
  }

  IconData get icon => Iconsax.medal_star5;

  static MedalType fromString(String v) => MedalType.values.firstWhere(
    (e) => e.name == v,
    orElse: () => MedalType.bronze,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ScratchRewardType
// ─────────────────────────────────────────────────────────────────────────────
enum ScratchRewardType {
  xp,
  medal,
  badge,
  multiplier,
  nothing;

  static ScratchRewardType fromString(String v) =>
      ScratchRewardType.values.firstWhere(
        (e) => e.name == v,
        orElse: () => ScratchRewardType.xp,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ProofStatus
// ─────────────────────────────────────────────────────────────────────────────
enum ProofStatus {
  pending,
  approved,
  rejected;

  static ProofStatus fromString(String v) => ProofStatus.values.firstWhere(
    (e) => e.name == v,
    orElse: () => ProofStatus.pending,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DareItemStatus — status of a challenge for a specific participant
// ─────────────────────────────────────────────────────────────────────────────
enum DareItemStatus {
  notStarted,
  inProgress,
  submitted,
  completed,
  rejected;

  static DareItemStatus fromString(String v) =>
      DareItemStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => DareItemStatus.notStarted,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// DareMemberRole + DareMemberStatus
// ─────────────────────────────────────────────────────────────────────────────
enum DareMemberRole { creator, participant }
enum DareMemberStatus { pending, approved, declined, suspended }

// ─────────────────────────────────────────────────────────────────────────────
// DareMilestone — sub-checkpoint within a challenge
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class DareMilestone {
  final String id;
  final String title;
  final String? description;
  final int xpReward;
  final MedalType medalType;
  final int order;

  const DareMilestone({
    required this.id,
    required this.title,
    this.description,
    this.xpReward = 50,
    this.medalType = MedalType.bronze,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'xpReward': xpReward,
    'medalType': medalType.name,
    'order': order,
  };

  factory DareMilestone.fromJson(Map<String, dynamic> j) => DareMilestone(
    id: j['id']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    description: j['description']?.toString(),
    xpReward: (j['xpReward'] as num?)?.toInt() ?? 50,
    medalType: MedalType.fromString(j['medalType']?.toString() ?? 'bronze'),
    order: (j['order'] as num?)?.toInt() ?? 0,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DareChallenge — one individual challenge/activity within a Dare
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class DareChallenge {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final DareCategory category;
  final DareChallengeType type;

  // App listing fields (type == appListing)
  final String? listingId;
  final String? listingCollection; // 'spots' | 'restaurants' | 'cafes' | etc.
  final String? listingLocation;

  // Custom challenge fields (type == custom)
  final String? customInstructions;

  final int xpReward;
  final MedalType medalType;
  final int order;
  final bool requiresProof;
  final List<DareMilestone> milestones;

  const DareChallenge({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    required this.category,
    required this.type,
    this.listingId,
    this.listingCollection,
    this.listingLocation,
    this.customInstructions,
    this.xpReward = 100,
    this.medalType = MedalType.bronze,
    this.order = 0,
    this.requiresProof = true,
    this.milestones = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'category': category.name,
    'type': type.name,
    'listingId': listingId,
    'listingCollection': listingCollection,
    'listingLocation': listingLocation,
    'customInstructions': customInstructions,
    'xpReward': xpReward,
    'medalType': medalType.name,
    'order': order,
    'requiresProof': requiresProof,
    'milestones': milestones.map((m) => m.toJson()).toList(),
  };

  factory DareChallenge.fromJson(Map<String, dynamic> j) => DareChallenge(
    id: j['id']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    description: j['description']?.toString(),
    imageUrl: j['imageUrl']?.toString(),
    category: DareCategory.fromString(j['category']?.toString() ?? 'other'),
    type:
        j['type'] == 'appListing'
            ? DareChallengeType.appListing
            : DareChallengeType.custom,
    listingId: j['listingId']?.toString(),
    listingCollection: j['listingCollection']?.toString(),
    listingLocation: j['listingLocation']?.toString(),
    customInstructions: j['customInstructions']?.toString(),
    xpReward: (j['xpReward'] as num?)?.toInt() ?? 100,
    medalType: MedalType.fromString(j['medalType']?.toString() ?? 'bronze'),
    order: (j['order'] as num?)?.toInt() ?? 0,
    requiresProof: j['requiresProof'] != false,
    milestones: (j['milestones'] as List? ?? [])
        .map((e) => DareMilestone.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DareMember — a participant in a Dare
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class DareMember {
  final String userId;
  final String userName;
  final String? userPhoto;
  final DareMemberRole role;
  final DareMemberStatus status;
  final DateTime joinedAt;
  final DateTime? approvedAt;
  final int completedChallenges;
  final int totalXpEarned;

  const DareMember({
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.approvedAt,
    this.completedChallenges = 0,
    this.totalXpEarned = 0,
  });

  bool get isCreator => role == DareMemberRole.creator;
  bool get isApproved => status == DareMemberStatus.approved;

  DareMember copyWith({
    DareMemberStatus? status,
    DateTime? approvedAt,
    int? completedChallenges,
    int? totalXpEarned,
  }) => DareMember(
    userId: userId,
    userName: userName,
    userPhoto: userPhoto,
    role: role,
    status: status ?? this.status,
    joinedAt: joinedAt,
    approvedAt: approvedAt ?? this.approvedAt,
    completedChallenges: completedChallenges ?? this.completedChallenges,
    totalXpEarned: totalXpEarned ?? this.totalXpEarned,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'userPhoto': userPhoto,
    'role': role.name,
    'status': status.name,
    'joinedAt': joinedAt.toIso8601String(),
    'approvedAt': approvedAt?.toIso8601String(),
    'completedChallenges': completedChallenges,
    'totalXpEarned': totalXpEarned,
  };

  factory DareMember.fromJson(Map<String, dynamic> j) {
    DateTime joinedAt = DateTime.now();
    final rawJoined = j['joinedAt'];
    if (rawJoined is Timestamp) {
      joinedAt = rawJoined.toDate();
    } else if (rawJoined is String) {
      joinedAt = DateTime.tryParse(rawJoined) ?? joinedAt;
    }

    DateTime? approvedAt;
    final rawApproved = j['approvedAt'];
    if (rawApproved is Timestamp) {
      approvedAt = rawApproved.toDate();
    } else if (rawApproved is String) {
      approvedAt = DateTime.tryParse(rawApproved);
    }

    return DareMember(
      userId: j['userId']?.toString() ?? '',
      userName: j['userName']?.toString() ?? '',
      userPhoto: j['userPhoto']?.toString(),
      role:
          j['role'] == 'creator'
              ? DareMemberRole.creator
              : DareMemberRole.participant,
      status: DareMemberStatus.values.firstWhere(
        (s) => s.name == (j['status']?.toString() ?? 'pending'),
        orElse: () => DareMemberStatus.pending,
      ),
      joinedAt: joinedAt,
      approvedAt: approvedAt,
      completedChallenges: (j['completedChallenges'] as num?)?.toInt() ?? 0,
      totalXpEarned: (j['totalXpEarned'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProofSubmission — challenge completion proof
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class ProofSubmission {
  final String id;
  final String userId;
  final String userName;
  final String? userPhoto;
  final String challengeId;
  final String dareId;
  final List<String> imageUrls;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? note; // planned for future version
  final DateTime submittedAt;
  final ProofStatus status;
  final String? reviewNote;

  const ProofSubmission({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.challengeId,
    required this.dareId,
    required this.imageUrls,
    this.latitude,
    this.longitude,
    this.locationName,
    this.note,
    required this.submittedAt,
    this.status = ProofStatus.pending,
    this.reviewNote,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'userPhoto': userPhoto,
    'challengeId': challengeId,
    'dareId': dareId,
    'imageUrls': imageUrls,
    'latitude': latitude,
    'longitude': longitude,
    'locationName': locationName,
    'note': note,
    'submittedAt': submittedAt.toIso8601String(),
    'status': status.name,
    'reviewNote': reviewNote,
  };

  factory ProofSubmission.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    DateTime ts = DateTime.now();
    if (d['submittedAt'] is Timestamp) {
      ts = (d['submittedAt'] as Timestamp).toDate();
    }
    return ProofSubmission(
      id: doc.id,
      userId: d['userId']?.toString() ?? '',
      userName: d['userName']?.toString() ?? '',
      userPhoto: d['userPhoto']?.toString(),
      challengeId: d['challengeId']?.toString() ?? '',
      dareId: d['dareId']?.toString() ?? '',
      imageUrls: List<String>.from(d['imageUrls'] as List? ?? []),
      latitude: (d['latitude'] as num?)?.toDouble(),
      longitude: (d['longitude'] as num?)?.toDouble(),
      locationName: d['locationName']?.toString(),
      note: d['note']?.toString(),
      submittedAt: ts,
      status: ProofStatus.fromString(d['status']?.toString() ?? 'pending'),
      reviewNote: d['reviewNote']?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ScratchCard — reward card earned on challenge completion
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class ScratchCard {
  final String id;
  final String userId;
  final String dareId;
  final String dareTitle;
  final String challengeId;
  final String challengeTitle;
  final ScratchRewardType rewardType;
  final int xpAmount;
  final MedalType? medal;
  final String? badgeTitle;
  final double? multiplier;
  final bool isScratched;
  final DateTime earnedAt;
  final DateTime? scratchedAt;

  const ScratchCard({
    required this.id,
    required this.userId,
    required this.dareId,
    required this.dareTitle,
    required this.challengeId,
    required this.challengeTitle,
    required this.rewardType,
    required this.xpAmount,
    this.medal,
    this.badgeTitle,
    this.multiplier,
    this.isScratched = false,
    required this.earnedAt,
    this.scratchedAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'dareId': dareId,
    'dareTitle': dareTitle,
    'challengeId': challengeId,
    'challengeTitle': challengeTitle,
    'rewardType': rewardType.name,
    'xpAmount': xpAmount,
    'medal': medal?.name,
    'badgeTitle': badgeTitle,
    'multiplier': multiplier,
    'isScratched': isScratched,
    'earnedAt': earnedAt.toIso8601String(),
    'scratchedAt': scratchedAt?.toIso8601String(),
  };

  factory ScratchCard.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    DateTime earned = DateTime.now();
    if (d['earnedAt'] is Timestamp) {
      earned = (d['earnedAt'] as Timestamp).toDate();
    }
    DateTime? scratched;
    if (d['scratchedAt'] is Timestamp) {
      scratched = (d['scratchedAt'] as Timestamp).toDate();
    }
    return ScratchCard(
      id: doc.id,
      userId: d['userId']?.toString() ?? '',
      dareId: d['dareId']?.toString() ?? '',
      dareTitle: d['dareTitle']?.toString() ?? '',
      challengeId: d['challengeId']?.toString() ?? '',
      challengeTitle: d['challengeTitle']?.toString() ?? '',
      rewardType: ScratchRewardType.fromString(
        d['rewardType']?.toString() ?? 'xp',
      ),
      xpAmount: (d['xpAmount'] as num?)?.toInt() ?? 0,
      medal:
          d['medal'] != null
              ? MedalType.fromString(d['medal'].toString())
              : null,
      badgeTitle: d['badgeTitle']?.toString(),
      multiplier: (d['multiplier'] as num?)?.toDouble(),
      isScratched: d['isScratched'] == true,
      earnedAt: earned,
      scratchedAt: scratched,
    );
  }

  ScratchCard copyWith({bool? isScratched, DateTime? scratchedAt}) =>
      ScratchCard(
        id: id,
        userId: userId,
        dareId: dareId,
        dareTitle: dareTitle,
        challengeId: challengeId,
        challengeTitle: challengeTitle,
        rewardType: rewardType,
        xpAmount: xpAmount,
        medal: medal,
        badgeTitle: badgeTitle,
        multiplier: multiplier,
        isScratched: isScratched ?? this.isScratched,
        earnedAt: earnedAt,
        scratchedAt: scratchedAt ?? this.scratchedAt,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// DareMedalRecord — medal saved to user profile
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class DareMedalRecord {
  final String id;
  final MedalType medalType;
  final String dareId;
  final String dareTitle;
  final String challengeTitle;
  final String? bannerUrl;
  final DateTime earnedAt;

  const DareMedalRecord({
    required this.id,
    required this.medalType,
    required this.dareId,
    required this.dareTitle,
    required this.challengeTitle,
    this.bannerUrl,
    required this.earnedAt,
  });

  Map<String, dynamic> toJson() => {
    'medalType': medalType.name,
    'dareId': dareId,
    'dareTitle': dareTitle,
    'challengeTitle': challengeTitle,
    'bannerUrl': bannerUrl,
    'earnedAt': earnedAt.toIso8601String(),
  };

  factory DareMedalRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    DateTime earned = DateTime.now();
    if (d['earnedAt'] is Timestamp) {
      earned = (d['earnedAt'] as Timestamp).toDate();
    }
    return DareMedalRecord(
      id: doc.id,
      medalType: MedalType.fromString(d['medalType']?.toString() ?? 'bronze'),
      dareId: d['dareId']?.toString() ?? '',
      dareTitle: d['dareTitle']?.toString() ?? '',
      challengeTitle: d['challengeTitle']?.toString() ?? '',
      bannerUrl: d['bannerUrl']?.toString(),
      earnedAt: earned,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DareModel — main document (Firestore collection: dares)
// ─────────────────────────────────────────────────────────────────────────────
@immutable
class DareModel {
  final String id;
  final String title;
  final String description;
  final String? bannerUrl;
  final DareCategory category;
  final String? customCategory;
  final DareVisibility visibility;
  final int maxParticipants;
  final String joinCode;
  final String creatorId;
  final String creatorName;
  final String? creatorPhoto;
  final List<DareChallenge> challenges;
  final List<DareMember> members;
  final List<DareMember> joinRequests;
  final DateTime createdAt;
  final DateTime? deadline;
  final DateTime? completedAt;
  final int xpReward; // bonus XP for completing all challenges
  final List<String> tags;
  final bool requiresProof;
  final List<String> removedUserIds;
  final int likeCount;
  final bool adminRestricted;
  final String? adminRestrictReason;

  const DareModel({
    required this.id,
    required this.title,
    required this.description,
    this.bannerUrl,
    required this.category,
    this.customCategory,
    required this.visibility,
    required this.maxParticipants,
    required this.joinCode,
    required this.creatorId,
    required this.creatorName,
    this.creatorPhoto,
    required this.challenges,
    required this.members,
    this.joinRequests = const [],
    required this.createdAt,
    this.deadline,
    this.completedAt,
    this.xpReward = 100,
    this.tags = const [],
    this.requiresProof = true,
    this.removedUserIds = const [],
    this.likeCount = 0,
    this.adminRestricted = false,
    this.adminRestrictReason,
  });

  // ── Derived ────────────────────────────────────────────────────────────

  List<DareMember> get approvedMembers =>
      members.where((m) => m.isApproved).toList();
  int get participantCount => approvedMembers.length;
  bool get isFull => participantCount >= maxParticipants;
  bool get isExpired =>
      deadline != null && DateTime.now().isAfter(deadline!);

  bool isParticipant(String uid) =>
      members.any((m) => m.userId == uid && m.isApproved);
  bool isCreator(String uid) => creatorId == uid;
  bool hasPendingRequest(String uid) =>
      joinRequests.any((r) => r.userId == uid);
  bool isRemoved(String uid) => removedUserIds.contains(uid);

  String get displayCategory =>
      category == DareCategory.other && customCategory != null
          ? customCategory!
          : category.label;

  DareMember? memberInfo(String uid) =>
      members.where((m) => m.userId == uid).firstOrNull;

  // ── copyWith ───────────────────────────────────────────────────────────

  DareModel copyWith({
    String? title,
    String? description,
    String? bannerUrl,
    DareCategory? category,
    Object? customCategory = _dareSentinel,
    DareVisibility? visibility,
    int? maxParticipants,
    int? xpReward,
    Object? deadline = _dareSentinel,
    List<DareChallenge>? challenges,
    List<DareMember>? members,
    List<DareMember>? joinRequests,
    DateTime? completedAt,
    List<String>? removedUserIds,
    List<String>? tags,
    bool? requiresProof,
    int? likeCount,
    bool? adminRestricted,
    Object? adminRestrictReason = _dareSentinel,
  }) => DareModel(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    bannerUrl: bannerUrl ?? this.bannerUrl,
    category: category ?? this.category,
    customCategory:
        customCategory == _dareSentinel
            ? this.customCategory
            : customCategory as String?,
    visibility: visibility ?? this.visibility,
    maxParticipants: maxParticipants ?? this.maxParticipants,
    joinCode: joinCode,
    creatorId: creatorId,
    creatorName: creatorName,
    creatorPhoto: creatorPhoto,
    challenges: challenges ?? this.challenges,
    members: members ?? this.members,
    joinRequests: joinRequests ?? this.joinRequests,
    createdAt: createdAt,
    deadline:
        deadline == _dareSentinel ? this.deadline : deadline as DateTime?,
    completedAt: completedAt ?? this.completedAt,
    xpReward: xpReward ?? this.xpReward,
    tags: tags ?? this.tags,
    requiresProof: requiresProof ?? this.requiresProof,
    removedUserIds: removedUserIds ?? this.removedUserIds,
    likeCount: likeCount ?? this.likeCount,
    adminRestricted: adminRestricted ?? this.adminRestricted,
    adminRestrictReason: adminRestrictReason == _dareSentinel
        ? this.adminRestrictReason
        : adminRestrictReason as String?,
  );

  // ── Firestore ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'bannerUrl': bannerUrl,
    'category': category.name,
    'customCategory': customCategory,
    'visibility': visibility.name,
    'maxParticipants': maxParticipants,
    'joinCode': joinCode,
    'creatorId': creatorId,
    'creatorName': creatorName,
    'creatorPhoto': creatorPhoto,
    'challenges': challenges.map((c) => c.toJson()).toList(),
    'members': members.map((m) => m.toJson()).toList(),
    'joinRequests': joinRequests.map((r) => r.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'deadline': deadline?.toIso8601String(),
    'xpReward': xpReward,
    'tags': tags,
    'requiresProof': requiresProof,
    'removedUserIds': removedUserIds,
    'likeCount': likeCount,
    'adminRestricted': adminRestricted,
    'adminRestrictReason': adminRestrictReason,
    // Denormalized for Firestore queries
    'memberIds':
        members
            .where((m) => m.isApproved)
            .map((m) => m.userId)
            .toList(),
    'pendingMemberIds':
        joinRequests
            .map((r) => r.userId)
            .toList(),
  };

  factory DareModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    DateTime createdAt = DateTime.now();
    DateTime? deadline;
    DateTime? completedAt;
    if (d['createdAt'] is Timestamp) {
      createdAt = (d['createdAt'] as Timestamp).toDate();
    }
    if (d['deadline'] is Timestamp) {
      deadline = (d['deadline'] as Timestamp).toDate();
    }
    if (d['completedAt'] is Timestamp) {
      completedAt = (d['completedAt'] as Timestamp).toDate();
    }
    return DareModel(
      id: doc.id,
      title: d['title']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      bannerUrl: d['bannerUrl']?.toString(),
      category: DareCategory.fromString(
        d['category']?.toString() ?? 'other',
      ),
      customCategory: d['customCategory']?.toString(),
      visibility:
          d['visibility'] == 'private'
              ? DareVisibility.private
              : DareVisibility.public,
      maxParticipants: (d['maxParticipants'] as num?)?.toInt() ?? 10,
      joinCode: d['joinCode']?.toString() ?? '',
      creatorId: d['creatorId']?.toString() ?? '',
      creatorName: d['creatorName']?.toString() ?? '',
      creatorPhoto: d['creatorPhoto']?.toString(),
      challenges: (d['challenges'] as List? ?? [])
          .map((e) => DareChallenge.fromJson(e as Map<String, dynamic>))
          .toList(),
      members: (d['members'] as List? ?? [])
          .map((e) => DareMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      joinRequests: (d['joinRequests'] as List? ?? [])
          .map((e) => DareMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: createdAt,
      deadline: deadline,
      completedAt: completedAt,
      xpReward: (d['xpReward'] as num?)?.toInt() ?? 100,
      tags: List<String>.from(d['tags'] as List? ?? []),
      requiresProof: d['requiresProof'] != false,
      removedUserIds: List<String>.from(d['removedUserIds'] as List? ?? []),
      likeCount: (d['likeCount'] as num?)?.toInt() ?? 0,
      adminRestricted: d['adminRestricted'] as bool? ?? false,
      adminRestrictReason: d['adminRestrictReason']?.toString(),
    );
  }
}
