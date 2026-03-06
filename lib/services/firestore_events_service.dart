import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/listing_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FirestoreEventsService
// Reads from the `events` Firestore collection.
// ─────────────────────────────────────────────────────────────────────────────

class FirestoreEventsService {
  final FirebaseFirestore _db;

  FirestoreEventsService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('events');

  // ── List ──────────────────────────────────────────────────────────────────

  /// Fetches up to [limit] events. Client-side status filter.
  /// If [upcomingOnly] is true, filters to events on or after today.
  Future<List<EventModel>> getEvents({
    int limit = 100,
    bool upcomingOnly = true,
  }) async {
    final snap = await _col.limit(limit * 2).get();
    final now = DateTime.now().subtract(const Duration(days: 1));
    return snap.docs
        .where((d) {
          final status = d.data()['status']?.toString();
          final statusOk =
              status == null ||
              status.isEmpty ||
              status.toLowerCase() == 'published' ||
              status.toLowerCase() == 'approved' ||
              status.toLowerCase() == 'active';
          if (!statusOk) return false;
          if (!upcomingOnly) return true;
          // Parse the event date for filtering
          final rawDate =
              d.data()['date'] ??
              d.data()['eventDate'] ??
              d.data()['startDate'];
          if (rawDate == null) return true; // include undated events
          try {
            DateTime? eventDate;
            if (rawDate is Timestamp) {
              eventDate = rawDate.toDate();
            } else if (rawDate is int) {
              eventDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
            } else {
              eventDate = DateTime.parse(rawDate.toString());
            }
            return eventDate.isAfter(now);
          } catch (_) {
            return true;
          }
        })
        .map((d) => EventModel.fromFirestore(d))
        .take(limit)
        .toList();
  }

  /// Fetches events filtered by [type] (festival / cultural / adventure / personal).
  Future<List<EventModel>> getByType({
    required String type,
    int limit = 100,
  }) async {
    final snap = await _col.where('type', isEqualTo: type).limit(limit).get();
    return snap.docs.map((d) => EventModel.fromFirestore(d)).toList();
  }

  // ── Single document ───────────────────────────────────────────────────────

  Future<EventModel?> getEventById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  // ── Stream (live) ─────────────────────────────────────────────────────────

  Stream<List<EventModel>> watchEvents({int limit = 100}) {
    return _col
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => EventModel.fromFirestore(d)).toList(),
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

final firestoreEventsServiceProvider = Provider<FirestoreEventsService>(
  (_) => FirestoreEventsService(),
);
