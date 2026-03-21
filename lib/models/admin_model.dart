// lib/models/admin_model.dart
//
// Models for the Super Admin system.
// Firestore collection: `app_admins`
// Firebase custom claim key: `superAdmin` (bool)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AdminRole
// ─────────────────────────────────────────────────────────────────────────────

enum AdminRole {
  superAdmin, // Full access — hillstechadmin@spotsence.com
  moderator, // Can review / approve content
  analyst; // Read-only analytics

  String get label => switch (this) {
    AdminRole.superAdmin => 'Super Admin',
    AdminRole.moderator => 'Moderator',
    AdminRole.analyst => 'Analyst',
  };

  String get emoji => switch (this) {
    AdminRole.superAdmin => '👑',
    AdminRole.moderator => '🛡️',
    AdminRole.analyst => '📊',
  };

  static AdminRole fromString(String? s) => switch (s) {
    'superAdmin' => AdminRole.superAdmin,
    'moderator' => AdminRole.moderator,
    'analyst' => AdminRole.analyst,
    _ => AdminRole.moderator,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminPermissions — granular feature flags per admin account
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class AdminPermissions {
  final bool canManageSpots;
  final bool canManageListings;
  final bool canManageEvents;
  final bool canManageVentures; // Dare & Venture packages
  final bool canManageUsers;
  final bool canViewAnalytics;
  final bool canManageCommunity;
  final bool canManageAdmins; // Only superAdmin should have this true

  const AdminPermissions({
    this.canManageSpots = false,
    this.canManageListings = false,
    this.canManageEvents = false,
    this.canManageVentures = false,
    this.canManageUsers = false,
    this.canViewAnalytics = false,
    this.canManageCommunity = false,
    this.canManageAdmins = false,
  });

  /// All permissions on — used for superAdmin
  const AdminPermissions.all()
    : canManageSpots = true,
      canManageListings = true,
      canManageEvents = true,
      canManageVentures = true,
      canManageUsers = true,
      canViewAnalytics = true,
      canManageCommunity = true,
      canManageAdmins = true;

  factory AdminPermissions.fromJson(Map<String, dynamic> j) => AdminPermissions(
    canManageSpots: j['canManageSpots'] as bool? ?? false,
    canManageListings: j['canManageListings'] as bool? ?? false,
    canManageEvents: j['canManageEvents'] as bool? ?? false,
    canManageVentures: j['canManageVentures'] as bool? ?? false,
    canManageUsers: j['canManageUsers'] as bool? ?? false,
    canViewAnalytics: j['canViewAnalytics'] as bool? ?? false,
    canManageCommunity: j['canManageCommunity'] as bool? ?? false,
    canManageAdmins: j['canManageAdmins'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'canManageSpots': canManageSpots,
    'canManageListings': canManageListings,
    'canManageEvents': canManageEvents,
    'canManageVentures': canManageVentures,
    'canManageUsers': canManageUsers,
    'canViewAnalytics': canViewAnalytics,
    'canManageCommunity': canManageCommunity,
    'canManageAdmins': canManageAdmins,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// AdminModel — stored in `app_admins/{uid}`
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class AdminModel {
  final String uid;
  final String email;
  final String displayName;
  final AdminRole role;
  final AdminPermissions permissions;
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  final String createdBy; // uid of whoever granted access

  const AdminModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.permissions,
    this.isActive = true,
    this.lastLogin,
    this.createdAt,
    this.createdBy = 'system',
  });

  bool get isSuperAdmin => role == AdminRole.superAdmin;

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AdminModel(
      uid: doc.id,
      email: d['email']?.toString() ?? '',
      displayName: d['displayName']?.toString() ?? '',
      role: AdminRole.fromString(d['role']?.toString()),
      permissions: d['permissions'] is Map
          ? AdminPermissions.fromJson(
              Map<String, dynamic>.from(d['permissions'] as Map),
            )
          : const AdminPermissions(),
      isActive: d['isActive'] as bool? ?? true,
      lastLogin: _ts(d['lastLogin']),
      createdAt: _ts(d['createdAt']),
      createdBy: d['createdBy']?.toString() ?? 'system',
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'role': role.name,
    'permissions': permissions.toJson(),
    'isActive': isActive,
    'lastLogin': lastLogin?.toIso8601String(),
    'createdAt': createdAt?.toIso8601String(),
    'createdBy': createdBy,
  };

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppAnalyticsSnapshot — read from `app_analytics/daily_snapshot`
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class AppAnalyticsSnapshot {
  final int totalUsers;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int totalSpots;
  final int totalListings;
  final int totalEvents;
  final int totalVentures;
  final int totalCommunityPosts;
  final int totalReviews;
  final int totalBookingRequests;
  final int pendingBookingRequests;
  final int totalPointsAwarded;
  final DateTime? updatedAt;

  const AppAnalyticsSnapshot({
    this.totalUsers = 0,
    this.newUsersToday = 0,
    this.newUsersThisWeek = 0,
    this.totalSpots = 0,
    this.totalListings = 0,
    this.totalEvents = 0,
    this.totalVentures = 0,
    this.totalCommunityPosts = 0,
    this.totalReviews = 0,
    this.totalBookingRequests = 0,
    this.pendingBookingRequests = 0,
    this.totalPointsAwarded = 0,
    this.updatedAt,
  });

  factory AppAnalyticsSnapshot.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AppAnalyticsSnapshot(
      totalUsers: (d['totalUsers'] as num?)?.toInt() ?? 0,
      newUsersToday: (d['newUsersToday'] as num?)?.toInt() ?? 0,
      newUsersThisWeek: (d['newUsersThisWeek'] as num?)?.toInt() ?? 0,
      totalSpots: (d['totalSpots'] as num?)?.toInt() ?? 0,
      totalListings: (d['totalListings'] as num?)?.toInt() ?? 0,
      totalEvents: (d['totalEvents'] as num?)?.toInt() ?? 0,
      totalVentures: (d['totalVentures'] as num?)?.toInt() ?? 0,
      totalCommunityPosts: (d['totalCommunityPosts'] as num?)?.toInt() ?? 0,
      totalReviews: (d['totalReviews'] as num?)?.toInt() ?? 0,
      totalBookingRequests: (d['totalBookingRequests'] as num?)?.toInt() ?? 0,
      pendingBookingRequests:
          (d['pendingBookingRequests'] as num?)?.toInt() ?? 0,
      totalPointsAwarded: (d['totalPointsAwarded'] as num?)?.toInt() ?? 0,
      updatedAt: AdminModel._ts(d['updatedAt']),
    );
  }
}
