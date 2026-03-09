import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  String get emoji {
    switch (this) {
      case spot:
        return '🗺️';
      case restaurant:
        return '🍽️';
      case cafe:
        return '☕';
      case hotel:
        return '🏨';
      case homestay:
        return '🏡';
      case adventure:
        return '🧗';
      case shopping:
        return '🛍️';
      case event:
        return '📅';
      case other:
        return '✨';
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

  const BucketMember({
    required this.userId,
    required this.userName,
    this.userPhoto,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  bool get isHost => role == MemberRole.host;
  bool get isApproved => status == MemberStatus.approved;

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'userPhoto': userPhoto,
    'role': role.name,
    'status': status.name,
    'joinedAt': joinedAt.toIso8601String(),
  };

  factory BucketMember.fromJson(Map<String, dynamic> j) {
    DateTime joinedAt = DateTime.now();
    final raw = j['joinedAt'];
    if (raw is Timestamp) {
      joinedAt = raw.toDate();
    } else if (raw is String) {
      joinedAt = DateTime.tryParse(raw) ?? DateTime.now();
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

  String get displayCategory =>
      category == BucketCategory.other && customCategory != null
      ? customCategory!
      : category.label;

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
    );
  }
}
