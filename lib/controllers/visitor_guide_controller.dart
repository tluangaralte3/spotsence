// lib/controllers/visitor_guide_controller.dart
//
// Riverpod providers for visitor guide feature.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visitor_guide_model.dart';
import '../services/visitor_guide_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// User-facing providers
// ─────────────────────────────────────────────────────────────────────────────

/// Stream of a single published guide for [stateKey].
/// Returns null if the guide doesn't exist or is unpublished — callers
/// should fall back to the built-in static content.
final visitorGuideProvider =
    StreamProvider.family<VisitorGuideModel?, String>((ref, stateKey) {
  return ref.read(visitorGuideServiceProvider).watchGuide(stateKey);
});

// ─────────────────────────────────────────────────────────────────────────────
// Admin providers
// ─────────────────────────────────────────────────────────────────────────────

/// Stream of ALL guides (for admin list screen).
final allVisitorGuidesProvider =
    StreamProvider<List<VisitorGuideModel>>((ref) {
  return ref.read(visitorGuideServiceProvider).watchAllGuides();
});

/// Stream of a single guide for admin editing (regardless of publish status).
final adminVisitorGuideProvider =
    StreamProvider.family<VisitorGuideModel?, String>((ref, stateKey) {
  return ref.read(visitorGuideServiceProvider).watchGuideAdmin(stateKey);
});
