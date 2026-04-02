// lib/models/visitor_guide_model.dart
//
// Model for per-state visitor guides.
// Firestore collection: `visitor_guides`
// Document ID         : the state key (e.g. 'Mizoram', 'Assam', …)
//
// Admin can:
//   • Create / edit / delete a guide per state
//   • Upload a banner image
//   • Add / remove items in dos & donts lists
//   • Add / remove quick-fact entries

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// QuickFact
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class GuideQuickFact {
  final String label;
  final String value;
  final String iconName; // stored as string — mapped to Icon on UI

  const GuideQuickFact({
    required this.label,
    required this.value,
    required this.iconName,
  });

  factory GuideQuickFact.fromMap(Map<String, dynamic> m) => GuideQuickFact(
        label: m['label'] as String? ?? '',
        value: m['value'] as String? ?? '',
        iconName: m['iconName'] as String? ?? 'info',
      );

  Map<String, dynamic> toMap() => {
        'label': label,
        'value': value,
        'iconName': iconName,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// VisitorGuideModel
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class VisitorGuideModel {
  final String id;         // == stateName key in Firestore doc ID
  final String stateName;  // display name
  final String emoji;
  final String tagline;
  final String about;
  final String bannerImageUrl;
  final List<String> dos;
  final List<String> donts;
  final List<GuideQuickFact> facts;
  final bool isPublished;
  final DateTime updatedAt;

  const VisitorGuideModel({
    required this.id,
    required this.stateName,
    required this.emoji,
    required this.tagline,
    required this.about,
    required this.bannerImageUrl,
    required this.dos,
    required this.donts,
    required this.facts,
    required this.isPublished,
    required this.updatedAt,
  });

  // ── Firestore deserialization ─────────────────────────────────────────────

  factory VisitorGuideModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return VisitorGuideModel(
      id: doc.id,
      stateName: d['stateName'] as String? ?? doc.id,
      emoji: d['emoji'] as String? ?? '🗺️',
      tagline: d['tagline'] as String? ?? '',
      about: d['about'] as String? ?? '',
      bannerImageUrl: d['bannerImageUrl'] as String? ?? '',
      dos: List<String>.from(d['dos'] as List? ?? []),
      donts: List<String>.from(d['donts'] as List? ?? []),
      facts: ((d['facts'] as List?) ?? [])
          .map((e) => GuideQuickFact.fromMap(e as Map<String, dynamic>))
          .toList(),
      isPublished: d['isPublished'] as bool? ?? false,
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── Firestore serialization ───────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'stateName': stateName,
        'emoji': emoji,
        'tagline': tagline,
        'about': about,
        'bannerImageUrl': bannerImageUrl,
        'dos': dos,
        'donts': donts,
        'facts': facts.map((f) => f.toMap()).toList(),
        'isPublished': isPublished,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  VisitorGuideModel copyWith({
    String? stateName,
    String? emoji,
    String? tagline,
    String? about,
    String? bannerImageUrl,
    List<String>? dos,
    List<String>? donts,
    List<GuideQuickFact>? facts,
    bool? isPublished,
  }) =>
      VisitorGuideModel(
        id: id,
        stateName: stateName ?? this.stateName,
        emoji: emoji ?? this.emoji,
        tagline: tagline ?? this.tagline,
        about: about ?? this.about,
        bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
        dos: dos ?? this.dos,
        donts: donts ?? this.donts,
        facts: facts ?? this.facts,
        isPublished: isPublished ?? this.isPublished,
        updatedAt: updatedAt,
      );
}
