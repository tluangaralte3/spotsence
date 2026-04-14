// lib/controllers/rental_controller.dart
//
// Riverpod providers for Equipment Rentals.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rental_models.dart';
import '../services/rental_service.dart';

// ── Service singleton ──────────────────────────────────────────────────────

final rentalServiceProvider = Provider<RentalService>((_) => RentalService());

// ── Featured rentals (home screen slider) ─────────────────────────────────

final featuredRentalsProvider = StreamProvider<List<RentalItem>>((ref) {
  return ref.watch(rentalServiceProvider).watchFeatured(limit: 10);
});

// ── All rentals (rentals screen) ──────────────────────────────────────────

final allRentalsProvider = StreamProvider<List<RentalItem>>((ref) {
  return ref.watch(rentalServiceProvider).watchAll();
});

// ── Rentals by category ───────────────────────────────────────────────────

final rentalsByCategoryProvider =
    StreamProvider.family<List<RentalItem>, RentalCategory>((ref, category) {
  return ref.watch(rentalServiceProvider).watchByCategory(category);
});

// ── Selected category filter ──────────────────────────────────────────────

class _RentalCategoryNotifier extends Notifier<RentalCategory?> {
  @override
  RentalCategory? build() => null;
  void select(RentalCategory? cat) => state = cat;
}

final selectedRentalCategoryProvider =
    NotifierProvider<_RentalCategoryNotifier, RentalCategory?>(
  _RentalCategoryNotifier.new,
);
