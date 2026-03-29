// lib/services/banner_service.dart
//
// CRUD + stream service for home-screen banners.
// Firestore collection : `home_banners`
// Global config doc    : `app_config/home_banners`

import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/banner_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final bannerServiceProvider = Provider<BannerService>((ref) {
  return BannerService(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// BannerService
// ─────────────────────────────────────────────────────────────────────────────

class BannerService {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  static const _col = 'home_banners';
  static const _configCol = 'app_config';
  static const _configDocId = 'home_banners';

  BannerService(this._db, this._storage);

  // ── Streams (used by home screen) ─────────────────────────────────────────

  /// Stream of active banners ordered by `order` asc.
  Stream<List<BannerModel>> watchActiveBanners() => _db
      .collection(_col)
      .where('isActive', isEqualTo: true)
      .orderBy('order')
      .snapshots()
      .map(
        (s) => s.docs.map(BannerModel.fromDoc).toList(),
      );

  /// Stream of ALL banners (for admin list).
  Stream<List<BannerModel>> watchAllBanners() => _db
      .collection(_col)
      .orderBy('order')
      .snapshots()
      .map(
        (s) => s.docs.map(BannerModel.fromDoc).toList(),
      );

  /// Stream of global section visibility config.
  Stream<BannerSectionConfig> watchSectionConfig() => _db
      .collection(_configCol)
      .doc(_configDocId)
      .snapshots()
      .map(BannerSectionConfig.fromDoc);

  // ── Admin CRUD ─────────────────────────────────────────────────────────────

  Future<void> createBanner(BannerModel banner) async {
    await _db.collection(_col).add(banner.toJson());
  }

  Future<void> updateBanner(BannerModel banner) async {
    await _db.collection(_col).doc(banner.id).update(banner.toJson());
  }

  Future<void> deleteBanner(String id) async {
    await _db.collection(_col).doc(id).delete();
  }

  Future<void> toggleBannerActive(BannerModel banner) async {
    await _db
        .collection(_col)
        .doc(banner.id)
        .update({'isActive': !banner.isActive, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> reorderBanners(List<BannerModel> ordered) async {
    final batch = _db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update(
        _db.collection(_col).doc(ordered[i].id),
        {'order': i, 'updatedAt': FieldValue.serverTimestamp()},
      );
    }
    await batch.commit();
  }

  // ── Section visiblity toggle ──────────────────────────────────────────────

  Future<void> setSectionVisible(bool visible) async {
    await _db.collection(_configCol).doc(_configDocId).set(
      {'sectionVisible': visible},
      SetOptions(merge: true),
    );
  }

  // ── Image upload ──────────────────────────────────────────────────────────

  /// Uploads [bytes] to Storage and returns the download URL.
  Future<String> uploadBannerImage({
    required String bannerId,
    required List<int> bytes,
    required String extension,
  }) async {
    final ref = _storage.ref('banners/$bannerId.$extension');
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'image/$extension'),
    );
    return ref.getDownloadURL();
  }
}
