// lib/services/visitor_guide_service.dart
//
// CRUD + stream service for per-state visitor guides.
// Firestore collection : `visitor_guides`
// Storage path         : `visitor_guides/{stateKey}.{ext}`

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/visitor_guide_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final visitorGuideServiceProvider = Provider<VisitorGuideService>((ref) {
  return VisitorGuideService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// VisitorGuideService
// ─────────────────────────────────────────────────────────────────────────────

class VisitorGuideService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  static const _col = 'visitor_guides';

  VisitorGuideService(this._db, this._storage);

  // ── Streams (user-facing) ─────────────────────────────────────────────────

  /// Stream of a single published guide by state key.
  /// Returns null if guide doesn't exist or is not published.
  Stream<VisitorGuideModel?> watchGuide(String stateKey) => _db
      .collection(_col)
      .doc(stateKey)
      .snapshots()
      .map((snap) {
        if (!snap.exists) return null;
        final guide = VisitorGuideModel.fromDoc(snap);
        return guide.isPublished ? guide : null;
      });

  // ── Streams (admin-facing) ────────────────────────────────────────────────

  /// Stream of all guides (published and unpublished) for admin list.
  Stream<List<VisitorGuideModel>> watchAllGuides() => _db
      .collection(_col)
      .orderBy('stateName')
      .snapshots()
      .map((s) => s.docs.map(VisitorGuideModel.fromDoc).toList());

  /// Stream of a single guide doc for admin editing (regardless of publish status).
  Stream<VisitorGuideModel?> watchGuideAdmin(String stateKey) => _db
      .collection(_col)
      .doc(stateKey)
      .snapshots()
      .map((snap) => snap.exists ? VisitorGuideModel.fromDoc(snap) : null);

  // ── Admin CRUD ────────────────────────────────────────────────────────────

  /// Creates or fully replaces a guide. Document ID == stateKey.
  Future<void> saveGuide(String stateKey, VisitorGuideModel guide) async {
    await _db.collection(_col).doc(stateKey).set(guide.toJson());
  }

  /// Partially update specific fields.
  Future<void> updateFields(
      String stateKey, Map<String, dynamic> fields) async {
    await _db.collection(_col).doc(stateKey).update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle publish status.
  Future<void> togglePublished(VisitorGuideModel guide) async {
    await _db.collection(_col).doc(guide.id).update({
      'isPublished': !guide.isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete the guide document and its banner image.
  Future<void> deleteGuide(String stateKey) async {
    await _db.collection(_col).doc(stateKey).delete();
    try {
      await _storage.ref('visitor_guides/$stateKey').delete();
    } catch (_) {
      // Image may not exist — ignore
    }
  }

  // ── Image upload ──────────────────────────────────────────────────────────

  /// Uploads [bytes] to Storage and returns the download URL.
  Future<String> uploadBannerImage({
    required String stateKey,
    required List<int> bytes,
    required String extension,
  }) async {
    final ref = _storage.ref('visitor_guides/$stateKey.$extension');
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'image/$extension'),
    );
    return await ref.getDownloadURL();
  }
}
