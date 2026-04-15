// lib/controllers/contribute_controller.dart
//
// Riverpod providers for contributed listings.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contributed_listing_model.dart';
import '../services/contribute_service.dart';

/// Current user's own contribution history.
final myContributionsProvider = StreamProvider<List<ContributedListing>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(contributeServiceProvider).watchMyContributions(uid);
});

/// Admin: only pending (awaiting review) submissions.
final pendingContributionsProvider =
    StreamProvider<List<ContributedListing>>((ref) {
  return ref.read(contributeServiceProvider).watchPending();
});

/// Admin: all submissions regardless of status.
final allContributionsProvider =
    StreamProvider<List<ContributedListing>>((ref) {
  return ref.read(contributeServiceProvider).watchAll();
});
