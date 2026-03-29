// lib/services/feedback_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackService {
  final _db = FirebaseFirestore.instance;

  /// Submit user feedback for a venture.
  ///
  /// Writes a document to `ventures/{ventureId}/feedback` (picked up by the
  /// admin Feedback tab via collectionGroup query).
  /// Simultaneously marks the booking document with `hasFeedback: true` so the
  /// user's booking card switches to "Feedback Submitted" state.
  Future<void> submitFeedback({
    required String ventureId,
    required String ventureTitle,
    required String bookingId,
    required String? selectedPackageName,
    required int rating,
    required String comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User is not authenticated.');

    final batch = _db.batch();

    // ── Write feedback to ventures/{ventureId}/feedback ──────────────────────
    final feedbackRef = _db
        .collection('ventures')
        .doc(ventureId)
        .collection('feedback')
        .doc();

    batch.set(feedbackRef, {
      'userId': user.uid,
      'bookingId': bookingId,
      'ventureId': ventureId,
      'ventureName': ventureTitle,
      'userName': user.displayName?.isNotEmpty == true
          ? user.displayName
          : (user.email ?? 'Anonymous'),
      'userEmail': user.email ?? '',
      if (selectedPackageName != null && selectedPackageName.isNotEmpty)
        'tierName': selectedPackageName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ── Mark booking as reviewed (user can update only hasFeedback) ──────────
    final bookingRef = _db.collection('bookings').doc(bookingId);
    batch.update(bookingRef, {
      'hasFeedback': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
