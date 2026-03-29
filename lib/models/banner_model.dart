// lib/models/banner_model.dart
//
// Model for home-screen promotional / informational banners.
// Firestore collection: `home_banners`
//
// Admin can:
//   • Create / edit / delete banners
//   • Toggle section visibility (global flag doc: `app_config/home_banners`)
//   • Reorder banners via `order` field
//   • Set link type: none | externalUrl | internalRoute

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BannerLinkType
// ─────────────────────────────────────────────────────────────────────────────

enum BannerLinkType {
  none,
  externalUrl,
  internalRoute;

  String get value => switch (this) {
    BannerLinkType.none => 'none',
    BannerLinkType.externalUrl => 'externalUrl',
    BannerLinkType.internalRoute => 'internalRoute',
  };

  static BannerLinkType fromString(String? s) => switch (s) {
    'externalUrl' => BannerLinkType.externalUrl,
    'internalRoute' => BannerLinkType.internalRoute,
    _ => BannerLinkType.none,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// BannerModel
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final BannerLinkType linkType;
  /// URL (for externalUrl) or GoRouter path (for internalRoute)
  final String? linkValue;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.linkType,
    this.linkValue,
    required this.isActive,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannerModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      subtitle: d['subtitle'] as String? ?? '',
      imageUrl: d['imageUrl'] as String? ?? '',
      linkType: BannerLinkType.fromString(d['linkType'] as String?),
      linkValue: d['linkValue'] as String?,
      isActive: d['isActive'] as bool? ?? true,
      order: d['order'] as int? ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
    'linkType': linkType.value,
    'linkValue': linkValue,
    'isActive': isActive,
    'order': order,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  BannerModel copyWith({
    String? title,
    String? subtitle,
    String? imageUrl,
    BannerLinkType? linkType,
    String? linkValue,
    bool? isActive,
    int? order,
  }) => BannerModel(
    id: id,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    imageUrl: imageUrl ?? this.imageUrl,
    linkType: linkType ?? this.linkType,
    linkValue: linkValue ?? this.linkValue,
    isActive: isActive ?? this.isActive,
    order: order ?? this.order,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// BannerSectionConfig — global visibility flag
// Firestore doc: app_config/home_banners
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class BannerSectionConfig {
  final bool sectionVisible;

  const BannerSectionConfig({this.sectionVisible = true});

  factory BannerSectionConfig.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return BannerSectionConfig(
      sectionVisible: d['sectionVisible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {'sectionVisible': sectionVisible};
}
