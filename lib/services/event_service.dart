import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/event_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EventService
//
// Reads and writes to the `events` Firestore collection.
// ─────────────────────────────────────────────────────────────────────────────

class EventService {
  final FirebaseFirestore _db;

  EventService([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('events');

  // ── Fetch list ────────────────────────────────────────────────────────────

  /// Returns [limit] published events.
  /// [upcomingOnly] filters out past events client-side (Firestore free tier
  /// doesn't support composite inequalities without an index).
  Future<List<EventModel>> getEvents({
    int limit = 100,
    bool upcomingOnly = false,
    String? type,
    String? category,
  }) async {
    Query<Map<String, dynamic>> q = _col;
    if (type != null && type.isNotEmpty) q = q.where('type', isEqualTo: type);
    if (category != null && category.isNotEmpty) {
      q = q.where('category', isEqualTo: category);
    }

    final snap = await q.limit(limit * 2).get();

    final now = DateTime.now().subtract(const Duration(days: 1));
    return snap.docs
        .where((d) {
          final status = d.data()['status']?.toString().toLowerCase() ?? '';
          final statusOk =
              status.isEmpty ||
              status == 'published' ||
              status == 'approved' ||
              status == 'active';
          if (!statusOk) return false;
          if (!upcomingOnly) return true;
          final rawDate =
              d.data()['date'] ??
              d.data()['eventDate'] ??
              d.data()['startDate'];
          if (rawDate == null) return true;
          try {
            DateTime? dt;
            if (rawDate is Timestamp)
              dt = rawDate.toDate();
            else if (rawDate is int) {
              dt = DateTime.fromMillisecondsSinceEpoch(rawDate);
            } else {
              dt = DateTime.parse(rawDate.toString());
            }
            return dt.isAfter(now);
          } catch (_) {
            return true;
          }
        })
        .map(EventModel.fromFirestore)
        .take(limit)
        .toList()
      // Sort by date ascending (upcoming first)
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return a.date!.compareTo(b.date!);
      });
  }

  /// Returns events whose date falls inside a month.
  Future<List<EventModel>> getEventsForMonth(int year, int month) async {
    final start = Timestamp.fromDate(DateTime(year, month, 1));
    final end = Timestamp.fromDate(DateTime(year, month + 1, 1));

    final snap = await _col
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThan: end)
        .get();

    return snap.docs.map(EventModel.fromFirestore).toList()..sort((a, b) {
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return a.date!.compareTo(b.date!);
    });
  }

  /// Returns featured events.
  Future<List<EventModel>> getFeaturedEvents({int limit = 10}) async {
    final snap = await _col
        .where('featured', isEqualTo: true)
        .limit(limit)
        .get();
    return snap.docs.map(EventModel.fromFirestore).toList();
  }

  // ── Single document ───────────────────────────────────────────────────────

  Future<EventModel?> getEventById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return EventModel.fromFirestore(doc);
  }

  // ── Real-time stream ──────────────────────────────────────────────────────

  /// Live stream of all published events (sorted client-side).
  Stream<List<EventModel>> watchEvents({int limit = 100}) {
    return _col
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map(EventModel.fromFirestore).toList()..sort((a, b) {
                if (a.date == null) return 1;
                if (b.date == null) return -1;
                return a.date!.compareTo(b.date!);
              }),
        );
  }

  // ── Ticketing helpers (phase 2) ───────────────────────────────────────────

  /// Atomically increments [ticketsBooked] by 1.
  Future<void> bookTicket(String eventId) async {
    await _col.doc(eventId).update({'ticketsBooked': FieldValue.increment(1)});
  }

  /// Atomically decrements [ticketsBooked] by 1 (cancellation).
  Future<void> cancelTicket(String eventId) async {
    await _col.doc(eventId).update({'ticketsBooked': FieldValue.increment(-1)});
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Riverpod provider
// ─────────────────────────────────────────────────────────────────────────────

final eventServiceProvider = Provider<EventService>((_) => EventService());

/// FutureProvider for a single event detail page.
final eventDetailProvider = FutureProvider.family<EventModel?, String>(
  (ref, id) => ref.read(eventServiceProvider).getEventById(id),
);
