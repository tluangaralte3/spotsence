// lib/models/app_info_board_model.dart
//
// Model for the App Information Board section on the home screen.
// Stored in Firestore: `app_config/app_info_board_section`
//
// Admin can:
//   • Toggle section visibility (sectionVisible)
//   • Edit all text fields (sectionTitle, title, subtitle, description, ctaText)
//   • Toggle the "Locked" badge (isLocked)
//   • Manage feature chips (features list)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppInfoBoardFeatureItem — one chip in the feature row
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class AppInfoBoardFeatureItem {
  final String iconKey; // e.g. 'map', 'star', 'location'
  final String label;

  const AppInfoBoardFeatureItem({required this.iconKey, required this.label});

  factory AppInfoBoardFeatureItem.fromMap(Map<String, dynamic> m) =>
      AppInfoBoardFeatureItem(
        iconKey: m['iconKey'] as String? ?? 'star',
        label: m['label'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {'iconKey': iconKey, 'label': label};

  AppInfoBoardFeatureItem copyWith({String? iconKey, String? label}) =>
      AppInfoBoardFeatureItem(
        iconKey: iconKey ?? this.iconKey,
        label: label ?? this.label,
      );

  /// Resolve the iconKey string to a Flutter [IconData].
  static IconData iconDataFromKey(String key) {
    switch (key) {
      case 'map':
        return Iconsax.map;
      case 'map_1':
        return Iconsax.map_1;
      case 'message_text':
        return Iconsax.message_text;
      case 'star':
        return Iconsax.star;
      case 'location':
        return Iconsax.location;
      case 'routing':
        return Iconsax.routing;
      case 'cpu':
        return Iconsax.cpu;
      case 'compass':
        return Iconsax.discover;
      case 'activity':
        return Iconsax.activity;
      case 'timer':
        return Iconsax.timer;
      case 'calendar':
        return Iconsax.calendar;
      case 'search':
        return Iconsax.search_normal;
      case 'bulb':
        return Iconsax.lamp_on;
      case 'heart':
        return Iconsax.heart;
      case 'camera':
        return Iconsax.camera;
      case 'discover':
        return Iconsax.discover;
      default:
        return Iconsax.star;
    }
  }

  IconData get iconData => iconDataFromKey(iconKey);

  /// All selectable icon options shown in the admin feature editor.
  static const List<({String key, String label})> availableIcons = [
    (key: 'map', label: 'Map'),
    (key: 'map_1', label: 'Map 2'),
    (key: 'routing', label: 'Route'),
    (key: 'location', label: 'Location'),
    (key: 'star', label: 'Star'),
    (key: 'message_text', label: 'Chat'),
    (key: 'cpu', label: 'AI/CPU'),
    (key: 'compass', label: 'Compass'),
    (key: 'activity', label: 'Activity'),
    (key: 'timer', label: 'Timer'),
    (key: 'calendar', label: 'Calendar'),
    (key: 'search', label: 'Search'),
    (key: 'bulb', label: 'Idea'),
    (key: 'heart', label: 'Favourite'),
    (key: 'camera', label: 'Camera'),
    (key: 'discover', label: 'Discover'),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// AppInfoBoardModel — entire section config
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class AppInfoBoardModel {
  final bool sectionVisible;
  final String sectionTitle; // header row text, e.g. "AI Travel Assistant"
  final String title; // card title,    e.g. "AI Travelling Planner"
  final String subtitle; // card subtitle, e.g. "& Travelling Companion"
  final String description; // long body text
  final List<AppInfoBoardFeatureItem> features; // chip list
  final String ctaText; // bottom button text
  final bool isLocked; // whether to show the "Locked" badge
  final DateTime? updatedAt;

  const AppInfoBoardModel({
    required this.sectionVisible,
    required this.sectionTitle,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.ctaText,
    required this.isLocked,
    this.updatedAt,
  });

  // ── Firestore ──────────────────────────────────────────────────────────────

  factory AppInfoBoardModel.fromDoc(DocumentSnapshot doc) {
    final d = (doc.exists ? doc.data() as Map<String, dynamic>? : null) ?? {};
    return AppInfoBoardModel.fromMap(d);
  }

  factory AppInfoBoardModel.fromMap(Map<String, dynamic> d) {
    final rawFeatures = d['features'];
    final features = rawFeatures is List
        ? rawFeatures
              .whereType<Map<String, dynamic>>()
              .map(AppInfoBoardFeatureItem.fromMap)
              .toList()
        : _defaultFeatures;

    return AppInfoBoardModel(
      sectionVisible: d['sectionVisible'] as bool? ?? true,
      sectionTitle: d['sectionTitle'] as String? ?? 'AI Travel Assistant',
      title: d['title'] as String? ?? 'AI Travelling Planner',
      subtitle: d['subtitle'] as String? ?? '& Travelling Companion',
      description:
          d['description'] as String? ??
          'Your intelligent travel companion powered by AI — plan personalised '
              'itineraries, discover hidden gems, get real-time recommendations, '
              'and travel smarter across Northeast India.',
      features: features,
      ctaText: d['ctaText'] as String? ?? 'Coming Soon — Stay Tuned!',
      isLocked: d['isLocked'] as bool? ?? true,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'sectionVisible': sectionVisible,
    'sectionTitle': sectionTitle,
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'features': features.map((f) => f.toMap()).toList(),
    'ctaText': ctaText,
    'isLocked': isLocked,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  // ── Defaults ───────────────────────────────────────────────────────────────

  static const List<AppInfoBoardFeatureItem> _defaultFeatures = [
    AppInfoBoardFeatureItem(iconKey: 'map', label: 'Smart Itineraries'),
    AppInfoBoardFeatureItem(
      iconKey: 'message_text',
      label: 'AI Companion Chat',
    ),
    AppInfoBoardFeatureItem(iconKey: 'star', label: 'Personalised Tips'),
    AppInfoBoardFeatureItem(iconKey: 'location', label: 'Live Suggestions'),
  ];

  static AppInfoBoardModel get defaults => AppInfoBoardModel.fromMap({});

  // ── copyWith ───────────────────────────────────────────────────────────────

  AppInfoBoardModel copyWith({
    bool? sectionVisible,
    String? sectionTitle,
    String? title,
    String? subtitle,
    String? description,
    List<AppInfoBoardFeatureItem>? features,
    String? ctaText,
    bool? isLocked,
  }) => AppInfoBoardModel(
    sectionVisible: sectionVisible ?? this.sectionVisible,
    sectionTitle: sectionTitle ?? this.sectionTitle,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    description: description ?? this.description,
    features: features ?? this.features,
    ctaText: ctaText ?? this.ctaText,
    isLocked: isLocked ?? this.isLocked,
    updatedAt: updatedAt,
  );
}
