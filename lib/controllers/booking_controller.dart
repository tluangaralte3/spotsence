// lib/controllers/booking_controller.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

// ── Service singleton ──────────────────────────────────────────────────────────

final bookingServiceProvider = Provider<BookingService>((_) => BookingService());

// ── User bookings stream ───────────────────────────────────────────────────────

/// Stream of all bookings for a given user ID, ordered by newest first.
final userBookingsProvider =
    StreamProvider.family<List<VentureBooking>, String>((ref, userId) {
  return ref.read(bookingServiceProvider).watchUserBookings(userId);
});

// ── Admin: all bookings stream ─────────────────────────────────────────────────

/// Stream of all venture bookings across all users, ordered by newest first.
final allBookingsProvider = StreamProvider<List<VentureBooking>>((ref) {
  return ref.read(bookingServiceProvider).watchAllBookings();
});
