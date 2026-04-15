// lib/services/rental_service.dart
//
// Firestore CRUD for `equipment_rentals` and `rental_bookings` collections.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rental_models.dart';

class RentalService {
  final FirebaseFirestore _db;

  RentalService([FirebaseFirestore? db])
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('equipment_rentals');

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('rental_bookings');

  // ── Equipment Streams ──────────────────────────────────────────────────────

  Stream<List<RentalItem>> watchFeatured({int limit = 10}) {
    return _col
        .where('isAvailable', isEqualTo: true)
        .limit(limit * 2)
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((d) => RentalItem.fromFirestore(d))
              .toList();
          items.sort((a, b) {
            if (a.isFeatured && !b.isFeatured) return -1;
            if (!a.isFeatured && b.isFeatured) return 1;
            final at = a.createdAt;
            final bt = b.createdAt;
            if (at == null && bt == null) return 0;
            if (at == null) return 1;
            if (bt == null) return -1;
            return bt.compareTo(at);
          });
          return items.take(limit).toList();
        });
  }

  Stream<List<RentalItem>> watchAll() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
      (snap) => snap.docs.map((d) => RentalItem.fromFirestore(d)).toList(),
    );
  }

  Stream<List<RentalItem>> watchByCategory(RentalCategory category) {
    return _col
        .where('category', isEqualTo: category.value)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => RentalItem.fromFirestore(d)).toList(),
        );
  }

  // ── Single doc ─────────────────────────────────────────────────────────────

  Future<RentalItem?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return RentalItem.fromFirestore(doc);
  }

  // ── Write ──────────────────────────────────────────────────────────────────

  Future<String> create(RentalItem item) async {
    final ref = await _col.add(item.toFirestore());
    return ref.id;
  }

  Future<void> update(String id, RentalItem item) async {
    final data = item.toFirestore();
    // Don't overwrite createdAt on update
    data.remove('createdAt');
    await _col.doc(id).update(data);
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> setAvailability(String id, {required bool available}) async {
    await _col.doc(id).update({'isAvailable': available});
  }

  Future<void> setFeatured(String id, {required bool featured}) async {
    await _col.doc(id).update({'isFeatured': featured});
  }

  // ── Booking Streams ────────────────────────────────────────────────────────

  Stream<List<RentalBooking>> watchAllBookings() {
    return _bookings
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => RentalBooking.fromFirestore(d)).toList());
  }

  Stream<List<RentalBooking>> watchActiveBookings() {
    return _bookings
        .where('status', isEqualTo: RentalBookingStatus.active.value)
        .orderBy('endDate')
        .snapshots()
        .map((s) => s.docs.map((d) => RentalBooking.fromFirestore(d)).toList());
  }

  Stream<List<RentalBooking>> watchBookingsByItem(String itemId) {
    return _bookings
        .where('itemId', isEqualTo: itemId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => RentalBooking.fromFirestore(d)).toList());
  }

  // ── Booking Writes ─────────────────────────────────────────────────────────

  Future<String> createBooking(RentalBooking booking) async {
    final ref = await _bookings.add(booking.toFirestore());
    return ref.id;
  }

  Future<void> updateBookingStatus(
    String id,
    RentalBookingStatus status,
  ) async {
    await _bookings.doc(id).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markReturned(String id) =>
      updateBookingStatus(id, RentalBookingStatus.returned);

  Future<void> cancelBooking(String id) =>
      updateBookingStatus(id, RentalBookingStatus.cancelled);

  Future<void> markOverdue(String id) =>
      updateBookingStatus(id, RentalBookingStatus.overdue);

  Future<void> updateBookingNotes(String id, String notes) async {
    await _bookings.doc(id).update({
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> extendBooking(String id, DateTime newEndDate) async {
    await _bookings.doc(id).update({
      'endDate': Timestamp.fromDate(newEndDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
