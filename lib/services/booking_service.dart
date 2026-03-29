// lib/services/booking_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/booking_model.dart';

class BookingService {
  final _col = FirebaseFirestore.instance.collection('bookings');

  /// Create a new booking. Returns the new document ID.
  /// Always stamps `userId` with the live Firebase Auth UID so the
  /// Firestore security rule (`request.auth.uid == resource.data.userId`)
  /// is guaranteed to pass for authenticated users.
  Future<String> createBooking(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User is not authenticated.');
    final ref = await _col.add({
      ...data,
      'userId': uid, // always override with the real auth UID
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Stream of bookings for a specific user, newest first.
  /// Sorted client-side to avoid requiring a composite Firestore index.
  Stream<List<VentureBooking>> watchUserBookings(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) {
                try {
                  return VentureBooking.fromFirestore(doc);
                } catch (_) {
                  return null;
                }
              })
              .whereType<VentureBooking>()
              .toList();
          // Sort newest first client-side (no composite index needed)
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Stream of all bookings across all users, newest first.
  Stream<List<VentureBooking>> watchAllBookings() {
    return _col
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) {
              try {
                return VentureBooking.fromFirestore(doc);
              } catch (_) {
                return null;
              }
            })
            .whereType<VentureBooking>()
            .toList());
  }

  /// Update booking status (and optionally add an admin note).
  Future<void> updateStatus(
    String bookingId,
    BookingStatus status, {
    String? adminNote,
  }) async {
    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (adminNote != null) data['adminNote'] = adminNote;
    await _col.doc(bookingId).update(data);
  }
}
