// lib/services/contribute_service.dart
//
// Handles user-contributed listing submissions:
//  - Upload images to Firebase Storage
//  - Save contribution to `contributed_listings` Firestore collection
//  - Admin: approve (writes to target collection) / reject

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/contributed_listing_model.dart';

final contributeServiceProvider = Provider<ContributeService>((ref) {
  return ContributeService();
});

class ContributeService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('contributed_listings');

  // ── User streams ──────────────────────────────────────────────────────────

  Stream<List<ContributedListing>> watchMyContributions(String userId) {
    return _col
        .where('contributorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ContributedListing.fromFirestore(d)).toList(),
        );
  }

  // ── Admin streams ─────────────────────────────────────────────────────────

  Stream<List<ContributedListing>> watchPending() {
    return _col
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) =>
              s.docs.map((d) => ContributedListing.fromFirestore(d)).toList(),
        );
  }

  Stream<List<ContributedListing>> watchAll() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (s) =>
              s.docs.map((d) => ContributedListing.fromFirestore(d)).toList(),
        );
  }

  // ── Submit new contribution ───────────────────────────────────────────────

  /// Returns null on success, error message string on failure.
  Future<String?> submit({
    required String name,
    required String description,
    required String address,
    required String district,
    required double latitude,
    required double longitude,
    required ContributionCategory category,
    required List<XFile> photos,
    required Map<String, dynamic> details,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'Not authenticated. Please sign in.';

      // 1. Upload all images to Storage
      final imageUrls = <String>[];
      for (final photo in photos) {
        final ms = DateTime.now().millisecondsSinceEpoch;
        final ref = _storage.ref(
          'contributed_listings/${user.uid}/${ms}_${photo.name}',
        );
        final bytes = await File(photo.path).readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
        imageUrls.add(await ref.getDownloadURL());
      }

      // 2. Save the contribution document
      final listing = ContributedListing(
        id: '',
        contributorId: user.uid,
        contributorName: user.displayName ?? 'Anonymous',
        contributorPhotoUrl: user.photoURL,
        category: category,
        status: ContributedListingStatus.pending,
        name: name,
        description: description,
        address: address,
        district: district,
        latitude: latitude,
        longitude: longitude,
        imageUrls: imageUrls,
        details: details,
        createdAt: DateTime.now(),
      );

      await _col.add(listing.toFirestore());
      return null; // success
    } catch (e) {
      return e.toString();
    }
  }

  // ── Admin: approve ────────────────────────────────────────────────────────

  /// Writes to the target listing collection, then marks the contribution
  /// as approved.
  Future<String?> approve(ContributedListing listing) async {
    try {
      final adminId = _auth.currentUser?.uid ?? '';

      // Write into the appropriate collection (spots/restaurants/cafes/etc.)
      await _db
          .collection(listing.category.firestoreCollection)
          .add(_buildTargetDoc(listing));

      // Update status
      await _col.doc(listing.id).update({
        'status': ContributedListingStatus.approved.value,
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Admin: reject ─────────────────────────────────────────────────────────

  Future<String?> reject(ContributedListing listing, String notes) async {
    try {
      final adminId = _auth.currentUser?.uid ?? '';
      await _col.doc(listing.id).update({
        'status': ContributedListingStatus.rejected.value,
        'adminNotes': notes,
        'reviewedBy': adminId,
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // ── Build collection-specific document ───────────────────────────────────

  Map<String, dynamic> _buildTargetDoc(ContributedListing l) {
    final d = l.details;

    // Common fields shared by all categories
    final base = <String, dynamic>{
      'name': l.name,
      'description': l.description,
      'location': l.address,
      'district': l.district,
      'latitude': l.latitude,
      'longitude': l.longitude,
      'rating': 0.0,
      'ratingsCount': 0,
      'contributedBy': l.contributorId,
      'contributorName': l.contributorName,
      'createdAt': FieldValue.serverTimestamp(),
    };

    switch (l.category) {
      case ContributionCategory.spot:
        return {
          ...base,
          // spots collection uses different field names
          'locationAddress': l.address,
          'imagesUrl': l.imageUrls,
          'category': d['spotCategory'] ?? 'other',
          'averageRating': 0.0,
          'featured': true, // featured so it appears on the map immediately
          'status': 'active',
          'placeStory': l.description,
          'views': 0,
          'popularity': 0.0,
          'alternateNames': <String>[],
          'thingsToDo': <String>[],
          'tags': <String>[],
          'entryFees': <Map<String, dynamic>>[],
          'addOns': <String>[],
          'ratings': <Map<String, dynamic>>[],
          'comments': <Map<String, dynamic>>[],
          if (d['bestSeason'] != null) 'bestSeason': d['bestSeason'],
          if (d['openingHours'] != null) 'openingHours': d['openingHours'],
          if (d['facilities'] != null) 'facilities': d['facilities'],
        };

      case ContributionCategory.restaurant:
        return {
          ...base,
          'images': l.imageUrls,
          'heroImage': l.imageUrls.isNotEmpty ? l.imageUrls.first : '',
          'cuisineTypes': d['cuisineTypes'] ?? <String>[],
          'priceRange': d['priceRange'] ?? '₹₹',
          'openingHours': d['openingHours'] ?? '',
          'hasDelivery': d['hasDelivery'] ?? false,
          'hasReservation': d['hasReservation'] ?? false,
          'contactPhone': d['contactPhone'] ?? '',
          'website': '',
        };

      case ContributionCategory.cafe:
        return {
          ...base,
          'images': l.imageUrls,
          'heroImage': l.imageUrls.isNotEmpty ? l.imageUrls.first : '',
          'specialties': d['specialties'] ?? <String>[],
          'priceRange': d['priceRange'] ?? '₹₹',
          'openingHours': d['openingHours'] ?? '',
          'hasWifi': d['hasWifi'] ?? false,
          'hasOutdoorSeating': d['hasOutdoorSeating'] ?? false,
          'contactPhone': d['contactPhone'] ?? '',
        };

      case ContributionCategory.adventure:
        return {
          ...base,
          'images': l.imageUrls,
          'heroImage': l.imageUrls.isNotEmpty ? l.imageUrls.first : '',
          'category': d['adventureCategory'] ?? 'trekking',
          'difficulty': d['difficulty'] ?? 'Moderate',
          'duration': d['duration'] ?? '',
          'bestSeason': d['bestSeason'] ?? '',
          'activities': d['activities'] ?? <String>[],
          'isPopular': false,
        };

      case ContributionCategory.homestay:
        return {
          ...base,
          'images': l.imageUrls,
          'heroImage': l.imageUrls.isNotEmpty ? l.imageUrls.first : '',
          'amenities': d['amenities'] ?? <String>[],
          'maxGuests': d['maxGuests'] ?? 2,
          'hostName': d['hostName'] ?? l.contributorName,
          'hostPhoto': l.contributorPhotoUrl ?? '',
          'hasBreakfast': d['hasBreakfast'] ?? false,
          'hasFreePickup': d['hasFreePickup'] ?? false,
          'priceRange': d['priceRange'] ?? '₹₹',
          'contactPhone': d['contactPhone'] ?? '',
        };

      case ContributionCategory.shopping:
        return {
          ...base,
          'images': l.imageUrls,
          'heroImage': l.imageUrls.isNotEmpty ? l.imageUrls.first : '',
          'type': d['shoppingType'] ?? 'market',
          'products': d['products'] ?? <String>[],
          'priceRange': d['priceRange'] ?? '₹₹',
          'openingHours': d['openingHours'] ?? '',
          'hasParking': d['hasParking'] ?? false,
          'acceptsCards': d['acceptsCards'] ?? false,
          'hasDelivery': false,
          'isPopular': false,
        };

      case ContributionCategory.event:
        return {
          ...base,
          'title': l.name,
          'imageUrl': l.imageUrls.isNotEmpty ? l.imageUrls.first : '',
          'date': d['eventDate'] ?? '',
          'time': d['eventTime'] ?? '',
          'attendees': 0,
          'category': d['eventCategory'] ?? 'cultural',
          'type': d['eventType'] ?? 'cultural',
          'status': 'upcoming',
        };
    }
  }
}
