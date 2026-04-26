// lib/services/app_info_board_service.dart
//
// Firestore service for the App Information Board section config.
// Config doc : `app_config/app_info_board_section`

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_info_board_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final appInfoBoardServiceProvider = Provider<AppInfoBoardService>((ref) {
  return AppInfoBoardService(FirebaseFirestore.instance);
});

// ─────────────────────────────────────────────────────────────────────────────
// AppInfoBoardService
// ─────────────────────────────────────────────────────────────────────────────

class AppInfoBoardService {
  final FirebaseFirestore _db;

  static const _configCol = 'app_config';
  static const _docId = 'app_info_board_section';

  AppInfoBoardService(this._db);

  DocumentReference get _doc => _db.collection(_configCol).doc(_docId);

  // ── Stream (home screen + admin) ─────────────────────────────────────────

  Stream<AppInfoBoardModel> watchSection() => _doc.snapshots().map(
        (snap) => snap.exists
            ? AppInfoBoardModel.fromDoc(snap)
            : AppInfoBoardModel.defaults,
      );

  // ── Admin writes ─────────────────────────────────────────────────────────

  /// Saves the full section config (create or overwrite).
  Future<void> saveSection(AppInfoBoardModel model) async {
    await _doc.set(model.toJson(), SetOptions(merge: true));
  }

  /// Toggle only the visibility flag (quick toggle from settings list).
  Future<void> setVisible(bool visible) async {
    await _doc.set(
      {'sectionVisible': visible, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  // ── Seed ─────────────────────────────────────────────────────────────────

  /// Writes default values only if the document does not yet exist.
  Future<void> seedDefaults() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      await _doc.set(AppInfoBoardModel.defaults.toJson());
    }
  }
}
