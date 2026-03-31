import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:iconsax/iconsax.dart';

/// Sentinel object used in copyWith to distinguish null from "not provided".
const Object _sentinel = Object();

// ─────────────────────────────────────────────────────────────────────────────
// Free room cap — users can host up to 5 rooms for free
// ─────────────────────────────────────────────────────────────────────────────
const int kFreeRoomCap = 5;

// ─────────────────────────────────────────────────────────────────────────────
// Time-based unlock thresholds (days in room)
// ─────────────────────────────────────────────────────────────────────────────
const int kConnectUnlockDays = 10;
const int kPokeUnlockDays = 20;

// ─────────────────────────────────────────────────────────────────────────────
// BucketCategory
// ─────────────────────────────────────────────────────────────────────────────

enum BucketCategory {
  spot,
  restaurant,
  cafe,
  hotel,
  homestay,
  adventure,
  shopping,
  event,
  other;

  String get label {
    switch (this) {
      case spot:
        return 'Tourist Spot';
      case restaurant:
        return 'Restaurant';
      case cafe:
        return 'Café';
      case hotel:
        return 'Hotel';
      case homestay:
        return 'Homestay';
      case adventure:
        return 'Adventure';
      case shopping:
        return 'Shopping';
      case event:
        return 'Event';
      case other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case spot:
        return Iconsax.location;
      case restaurant:
        return Iconsax.coffee;
      case cafe:
        return Iconsax.coffee;
      case hotel:
        return Iconsax.building;
      case homestay:
        return Iconsax.home;
      case adventure:
        return Iconsax.flash;
      case shopping:
        return Iconsax.bag;
      case event:
        return Iconsax.calendar;
      case other:
        return Iconsax.element_4;
    }
  }

  static BucketCategory fromString(String v) {
    return BucketCategory.values.firstWhere(
      (e) => e.name == v.toLowerCase(),
      orElse: () => BucketCategory.other,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BucketItem — one destination / activity on the list
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class BucketItem {
  final String id;
  final String name;
  final String? imageUrl;
  final BucketCategory category;
  final String? customCategory; // used when category == other
  final String? listingId; // Firestore doc id of the linked listing/spot
  final String? listingType; // 'spot' | 'restaurant' | 'cafe' | ...
  final String? note;
  final bool isChecked;
  final String? checkedByUserId;
  final String? checkedByUserName;
  final DateTime? checkedAt;

  const BucketItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.category,
    this.customCategory,
    this.listingId,
    this.listingType,
    this.note,
    this.isChecked = false,
    this.checkedByUserId,
    this.checkedByUserName,
    this.checkedAt,
  });

  String get displayCategory =>
      category == BucketCategory.other && customCategory != null
      ? customCategory!
      : category.label;

  BucketItem copyWith({
    bool? isChecked,
    String? checkedByUserId,
    String? checkedByUserName,
    DateTime? checkedAt,
    String? note,
  }) => BucketItem(
    id: id,
    name: name,
    imageUrl: imageUrl,
    category: category,
    customCategory: customCategory,
    listingId: listingId,
    listingType: listingType,
    note: note ?? this.note,
    isChecked: isChecked ?? this.isChecked,
    checkedByUserId: checkedByUserId ?? this.checkedByUserId,
    checkedByUserName: checkedByUserName ?? this.checkedByUserName,
    checkedAt: checkedAt ?? this.checkedAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
    'category': category.name,
    'customCategory': customCategory,
    'listingId': listingId,
    'listingType': listingType,
    'note': note,
    'isChecked': isChecked,
    'checkedByUserId': checkedByUserId,
    'checkedByUserName': checkedByUserName,
    'checkedAt': checkedAt?.toIso8601String(),
  };

  factory BucketItem.fromJson(Map<String, dynamic> j) {
    DateTime? checkedAt;
    final raw = j['checkedAt'];
    if (raw is Timestamp) {
      checkedAt = raw.toDate();
    } else if (raw is String) {
      checkedAt = DateTime.tryParse(raw);
    }
    return BucketItem(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      imageUrl: j['imageUrl']?.toString(),
      category: BucketCategory.fromString(j['category']?.toString() ?? ''),
      customCategory: j['customCategory']?.toString(),
      listingId: j['listingId']?.toString(),
      listingType: j['listingType']?.toString(),
      note: j['note']?.toString(),
      isChecked: j['isChecked'] == true,
      checkedByUserId: j['checkedByUserId']?.toString(),
      checkedByUserName: j['checkedByUserName']?.toString(),
      checkedAt: checkedAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BucketMember — one participant in the bucket list
// ─────────────────────────────────────────────────────────────────────────────

enum MemberRole { host, member }

enum MemberStatus { pending, approved, declined }

@immutable
class BucketMember {
  final String userId;
  final String userName;
  final String? userPhoto;
  final MemberRole role;
  final MemberStatus status;
  final DateTime joinedAt;

  /// When the member was approved (used for time-based feature unlocks).
  final DateTime? approvedAt;

  /// Number of strikes issued by the room creator (0–3). 3 = auto-removed.
  final int strikes;

  /// Whether member has opted to share their contact info inside this room.
  final bool contactShared;

  const BucketMember({
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.approvedAt,
    this.strikes = 0,
    this.contactShared = false,
  });

  bool get isHost => role == MemberRole.host;
  bool get isApproved => status == MemberStatus.approved;

  /// Days this member has been an approved member of the room.
  int daysInRoom(DateTime now) {
    final ref = approvedAt ?? joinedAt;
    return now.difference(ref).inDays;
  }

  /// True when the member has been in the room long enough to use Connect.
  bool canConnect(DateTime now) => daysInRoom(now) >= kConnectUnlockDays;

  /// True when the member has been in the room long enough to send pokes.
  bool canPoke(DateTime now) => daysInRoom(now) >= kPokeUnlockDays;

  BucketMember copyWith({
    MemberStatus? status,
    DateTime? approvedAt,
    int? strikes,
    bool? contactShared,
  }) => BucketMember(
    userId: userId,
    userName: userName,
    userPhoto: userPhoto,
    role: role,
    status: status ?? this.status,
    joinedAt: joinedAt,
    approvedAt: approvedAt ?? this.approvedAt,
    strikes: strikes ?? this.strikes,
    contactShared: contactShared ?? this.contactShared,
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'userPhoto': userPhoto,
    'role': role.name,
    'status': status.name,
    'joinedAt': joinedAt.toIso8601String(),
    'approvedAt': approvedAt?.toIso8601String(),
    'strikes': strikes,
    'contactShared': contactShared,
  };

  factory BucketMember.fromJson(Map<String, dynamic> j) {
    DateTime joinedAt = DateTime.now();
    final rawJoined = j['joinedAt'];
    if (rawJoined is Timestamp) {
      joinedAt = rawJoined.toDate();
    } else if (rawJoined is String) {
      joinedAt = DateTime.tryParse(rawJoined) ?? DateTime.now();
    }

    DateTime? approvedAt;
    final rawApproved = j['approvedAt'];
    if (rawApproved is Timestamp) {
      approvedAt = rawApproved.toDate();
    } else if (rawApproved is String) {
      approvedAt = DateTime.tryParse(rawApproved);
    }

    return BucketMember(
      userId: j['userId']?.toString() ?? '',
      userName: j['userName']?.toString() ?? '',
      userPhoto: j['userPhoto']?.toString(),
      role: j['role'] == 'host' ? MemberRole.host : MemberRole.member,
      status: MemberStatus.values.firstWhere(
        (s) => s.name == (j['status']?.toString() ?? 'pending'),
        orElse: () => MemberStatus.pending,
      ),
      joinedAt: joinedAt,
      approvedAt: approvedAt,
      strikes: (j['strikes'] as num?)?.toInt() ?? 0,
      contactShared: j['contactShared'] == true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RoomPokeModel — a single poke between two members (subcollection doc)
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class RoomPokeModel {
  final String id;
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final DateTime timestamp;

  const RoomPokeModel({
    required this.id,
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.timestamp,
  });

  factory RoomPokeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    DateTime ts = DateTime.now();
    if (d['timestamp'] is Timestamp) {
      ts = (d['timestamp'] as Timestamp).toDate();
    }
    return RoomPokeModel(
      id: doc.id,
      fromId: d['fromId']?.toString() ?? '',
      fromName: d['fromName']?.toString() ?? '',
      toId: d['toId']?.toString() ?? '',
      toName: d['toName']?.toString() ?? '',
      timestamp: ts,
    );
  }

  Map<String, dynamic> toJson() => {
    'fromId': fromId,
    'fromName': fromName,
    'toId': toId,
    'toName': toName,
    'timestamp': timestamp.toIso8601String(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// RoomReportModel — a member report (subcollection doc)
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class RoomReportModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String targetId;
  final String targetName;
  final String reason;
  final DateTime timestamp;

  const RoomReportModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.targetId,
    required this.targetName,
    required this.reason,
    required this.timestamp,
  });

  factory RoomReportModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    DateTime ts = DateTime.now();
    if (d['timestamp'] is Timestamp) {
      ts = (d['timestamp'] as Timestamp).toDate();
    }
    return RoomReportModel(
      id: doc.id,
      reporterId: d['reporterId']?.toString() ?? '',
      reporterName: d['reporterName']?.toString() ?? '',
      targetId: d['targetId']?.toString() ?? '',
      targetName: d['targetName']?.toString() ?? '',
      reason: d['reason']?.toString() ?? '',
      timestamp: ts,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BucketVisibility
// ─────────────────────────────────────────────────────────────────────────────

enum BucketVisibility { public, private }

// ─────────────────────────────────────────────────────────────────────────────
// BucketListModel — the main document
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class BucketListModel {
  final String id;
  final String title;
  final String description;
  final String bannerUrl;
  final BucketCategory category;
  final String? customCategory;
  final BucketVisibility visibility;
  final int maxMembers;
  final String joinCode; // 6-char alphanumeric join code
  final String hostId;
  final String hostName;
  final String? hostPhoto;
  final List<BucketItem> items;
  final List<BucketMember> members; // includes host
  final List<BucketMember> joinRequests; // pending approvals
  final DateTime createdAt;
  final DateTime? completedAt;

  // Gamification extras
  final int xpReward; // XP awarded when list is fully completed
  final List<String> badges; // badge ids unlocked on completion
  final String? challengeTitle; // optional challenge name overlay

  /// Users permanently removed/banned from this room by the creator.
  final List<String> removedUserIds;

  const BucketListModel({
    required this.id,
    required this.title,
    required this.description,
    required this.bannerUrl,
    required this.category,
    this.customCategory,
    required this.visibility,
    required this.maxMembers,
    required this.joinCode,
    required this.hostId,
    required this.hostName,
    this.hostPhoto,
    required this.items,
    required this.members,
    this.joinRequests = const [],
    required this.createdAt,
    this.completedAt,
    this.xpReward = 100,
    this.badges = const [],
    this.challengeTitle,
    this.removedUserIds = const [],
  });

  // ── Derived ────────────────────────────────────────────────────────────

  int get checkedCount => items.where((i) => i.isChecked).length;
  double get progress => items.isEmpty ? 0.0 : checkedCount / items.length;
  bool get isCompleted => items.isNotEmpty && checkedCount == items.length;
  bool get isFull {
    final approved = members.where((m) => m.isApproved).length;
    return approved >= maxMembers;
  }

  List<BucketMember> get approvedMembers =>
      members.where((m) => m.isApproved).toList();

  int get approvedCount => approvedMembers.length;

  bool isMember(String uid) =>
      members.any((m) => m.userId == uid && m.isApproved);
  bool isHost(String uid) => hostId == uid;
  bool hasPendingRequest(String uid) =>
      joinRequests.any((r) => r.userId == uid);
  bool isRemoved(String uid) => removedUserIds.contains(uid);

  String get displayCategory =>
      category == BucketCategory.other && customCategory != null
      ? customCategory!
      : category.label;

  // ── copyWith ───────────────────────────────────────────────────────────

  BucketListModel copyWith({
    String? title,
    String? description,
    String? bannerUrl,
    BucketCategory? category,
    Object? customCategory = _sentinel,
    BucketVisibility? visibility,
    int? maxMembers,
    int? xpReward,
    Object? challengeTitle = _sentinel,
    List<BucketItem>? items,
    List<BucketMember>? members,
    List<BucketMember>? joinRequests,
    DateTime? completedAt,
    List<String>? removedUserIds,
  }) {
    return BucketListModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      category: category ?? this.category,
      customCategory: customCategory == _sentinel
          ? this.customCategory
          : customCategory as String?,
      visibility: visibility ?? this.visibility,
      maxMembers: maxMembers ?? this.maxMembers,
      joinCode: joinCode,
      hostId: hostId,
      hostName: hostName,
      hostPhoto: hostPhoto,
      items: items ?? this.items,
      members: members ?? this.members,
      joinRequests: joinRequests ?? this.joinRequests,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      xpReward: xpReward ?? this.xpReward,
      badges: badges,
      challengeTitle: challengeTitle == _sentinel
          ? this.challengeTitle
          : challengeTitle as String?,
      removedUserIds: removedUserIds ?? this.removedUserIds,
    );
  }

  // ── Firestore ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'bannerUrl': bannerUrl,
    'category': category.name,
    'customCategory': customCategory,
    'visibility': visibility.name,
    'maxMembers': maxMembers,
    'joinCode': joinCode,
    'hostId': hostId,
    'hostName': hostName,
    'hostPhoto': hostPhoto,
    'items': items.map((i) => i.toJson()).toList(),
    'members': members.map((m) => m.toJson()).toList(),
    'joinRequests': joinRequests.map((r) => r.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'xpReward': xpReward,
    'badges': badges,
    'challengeTitle': challengeTitle,
    'removedUserIds': removedUserIds,
  };

  factory BucketListModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    DateTime createdAt = DateTime.now();
    DateTime? completedAt;
    if (d['createdAt'] is Timestamp) {
      createdAt = (d['createdAt'] as Timestamp).toDate();
    }
    if (d['completedAt'] is Timestamp) {
      completedAt = (d['completedAt'] as Timestamp).toDate();
    }
    return BucketListModel(
      id: doc.id,
      title: d['title']?.toString() ?? '',
      description: d['description']?.toString() ?? '',
      bannerUrl: d['bannerUrl']?.toString() ?? '',
      category: BucketCategory.fromString(d['category']?.toString() ?? 'other'),
      customCategory: d['customCategory']?.toString(),
      visibility: d['visibility'] == 'private'
          ? BucketVisibility.private
          : BucketVisibility.public,
      maxMembers: (d['maxMembers'] as num?)?.toInt() ?? 10,
      joinCode: d['joinCode']?.toString() ?? '',
      hostId: d['hostId']?.toString() ?? '',
      hostName: d['hostName']?.toString() ?? '',
      hostPhoto: d['hostPhoto']?.toString(),
      items: (d['items'] as List? ?? [])
          .map((e) => BucketItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      members: (d['members'] as List? ?? [])
          .map((e) => BucketMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      joinRequests: (d['joinRequests'] as List? ?? [])
          .map((e) => BucketMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: createdAt,
      completedAt: completedAt,
      xpReward: (d['xpReward'] as num?)?.toInt() ?? 100,
      badges: List<String>.from(d['badges'] as List? ?? []),
      challengeTitle: d['challengeTitle']?.toString(),
      removedUserIds: List<String>.from(d['removedUserIds'] as List? ?? []),
    );
  }
}
