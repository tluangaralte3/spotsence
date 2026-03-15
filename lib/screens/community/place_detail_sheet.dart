// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/gamification_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/gamification_models.dart';
import '../../models/spot_model.dart';
import '../../services/firestore_cafes_service.dart';
import '../../services/firestore_restaurants_service.dart';
import '../../services/firestore_spots_service.dart';
import 'community_map.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model for a single community photo
// ─────────────────────────────────────────────────────────────────────────────

class CommunityPhoto {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String imageUrl;
  final String caption;
  final DateTime createdAt;

  const CommunityPhoto({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.imageUrl,
    required this.caption,
    required this.createdAt,
  });

  factory CommunityPhoto.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    DateTime ts;
    try {
      final raw = d['createdAt'];
      if (raw is Timestamp) {
        ts = raw.toDate();
      } else {
        ts = DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
      }
    } catch (_) {
      ts = DateTime.now();
    }
    return CommunityPhoto(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String? ?? 'Anonymous',
      userAvatar: d['userAvatar'] as String? ?? '',
      imageUrl: d['imageUrl'] as String? ?? '',
      caption: d['caption'] as String? ?? '',
      createdAt: ts,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// Streams reviews for `{collection}/{id}/reviews`.
final _reviewsProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, ({String collection, String id})>(
      (ref, args) => FirebaseFirestore.instance
          .collection(args.collection)
          .doc(args.id)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList()),
    );

/// Streams community photos for `{collection}/{id}/communityPhotos`.
final _communityPhotosProvider = StreamProvider.autoDispose
    .family<List<CommunityPhoto>, ({String collection, String id})>(
      (ref, args) => FirebaseFirestore.instance
          .collection(args.collection)
          .doc(args.id)
          .collection('communityPhotos')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map((s) => s.docs.map(CommunityPhoto.fromDoc).toList()),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Entry points — show the modal sheet
// ─────────────────────────────────────────────────────────────────────────────

/// Opens the rich detail sheet for a restaurant / café pin.
void showPlaceDetailSheet(BuildContext context, MapPlace place) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlaceDetailSheet.fromMapPlace(place),
  );
}

/// Opens the rich detail sheet for a tourist-spot pin.
void showSpotDetailSheet(BuildContext context, SpotModel spot) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PlaceDetailSheet.fromSpot(spot),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceDetailSheet extends ConsumerStatefulWidget {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int ratingCount;
  final String location;
  final String type; // "restaurant" | "cafe" | "spot"
  final String collection; // Firestore collection name

  const _PlaceDetailSheet({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.ratingCount,
    required this.location,
    required this.type,
    required this.collection,
  });

  factory _PlaceDetailSheet.fromMapPlace(MapPlace p) => _PlaceDetailSheet(
    id: p.id,
    name: p.name,
    imageUrl: p.imageUrl,
    rating: p.rating,
    ratingCount: 0,
    location: p.location,
    type: p.type,
    collection: p.type == 'restaurant' ? 'restaurants' : 'cafes',
  );

  factory _PlaceDetailSheet.fromSpot(SpotModel s) => _PlaceDetailSheet(
    id: s.id,
    name: s.name,
    imageUrl: s.heroImage,
    rating: s.averageRating,
    ratingCount: s.ratings.length,
    location: s.locationAddress,
    type: 'spot',
    collection: 'spots',
  );

  @override
  ConsumerState<_PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends ConsumerState<_PlaceDetailSheet> {
  // ── rating state ──────────────────────────────────────────────────────────
  int _hoveredStar = 0;
  int _selectedStar = 0;
  int _submittedStar = 0; // locked after a successful submission
  bool _isSubmittingRating = false;

  // ── photo-upload state ────────────────────────────────────────────────────
  bool _isUploadingPhoto = false;
  double _uploadProgress = 0;

  // ── review text ───────────────────────────────────────────────────────────
  final _reviewCtrl = TextEditingController();
  final _captionCtrl = TextEditingController();

  @override
  void dispose() {
    _reviewCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String get _emojiForType {
    switch (widget.type) {
      case 'restaurant':
        return '🍽️';
      case 'cafe':
        return '☕';
      case 'spot':
        return '🗺️';
      default:
        return '📍';
    }
  }

  Color get _accentColor {
    switch (widget.type) {
      case 'restaurant':
        return const Color(0xFFFF7043);
      case 'cafe':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }

  // ── submit rating ─────────────────────────────────────────────────────────

  Future<void> _submitRating() async {
    if (_selectedStar == 0) return;
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showSnack('Sign in to rate this place');
      return;
    }

    setState(() => _isSubmittingRating = true);
    try {
      final comment = _reviewCtrl.text.trim();
      final rating = _selectedStar.toDouble();

      if (widget.collection == 'restaurants') {
        await ref
            .read(firestoreRestaurantsServiceProvider)
            .submitReview(
              restaurantId: widget.id,
              userId: user.id,
              userName: user.displayName,
              userAvatar: user.photoURL ?? '',
              rating: rating,
              comment: comment,
            );
      } else if (widget.collection == 'cafes') {
        await ref
            .read(firestoreCafesServiceProvider)
            .submitReview(
              cafeId: widget.id,
              userId: user.id,
              userName: user.displayName,
              userAvatar: user.photoURL ?? '',
              rating: rating,
              comment: comment,
            );
      } else {
        // spots
        await ref
            .read(firestoreSpotsServiceProvider)
            .submitReview(
              spotId: widget.id,
              userId: user.id,
              userName: user.displayName,
              userAvatar: user.photoURL ?? '',
              rating: rating,
              comment: comment,
            );
      }

      setState(() {
        _submittedStar = _selectedStar;
        _selectedStar = 0;
        _reviewCtrl.clear();
      });
      // ── Gamification ──────────────────────────────────────────────────────
      await ref
          .read(gamificationControllerProvider.notifier)
          .award(XpAction.writeReview, relatedId: widget.id);
      await ref
          .read(gamificationControllerProvider.notifier)
          .incrementCounter('ratingsCount');
      _showSnack('Rating submitted! Thanks ✨');
    } catch (e) {
      _showSnack('Failed to submit: $e');
    } finally {
      setState(() => _isSubmittingRating = false);
    }
  }

  // ── upload community photo ─────────────────────────────────────────────────

  Future<void> _pickAndUploadPhoto() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showSnack('Sign in to upload photos');
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1200,
    );
    if (picked == null) return;

    // Ask for caption
    final caption = await _showCaptionDialog();

    setState(() {
      _isUploadingPhoto = true;
      _uploadProgress = 0;
    });

    try {
      final file = File(picked.path);
      final ext = picked.path.split('.').last;
      final ts = DateTime.now().millisecondsSinceEpoch;
      final storagePath =
          'community_photos/${widget.collection}/${widget.id}/${user.id}_$ts.$ext';

      final storageRef = FirebaseStorage.instance.ref(storagePath);
      final uploadTask = storageRef.putFile(file);

      // Track progress
      uploadTask.snapshotEvents.listen((snap) {
        if (snap.totalBytes > 0) {
          setState(
            () => _uploadProgress = snap.bytesTransferred / snap.totalBytes,
          );
        }
      });

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

      // Write to Firestore
      await FirebaseFirestore.instance
          .collection(widget.collection)
          .doc(widget.id)
          .collection('communityPhotos')
          .add({
            'userId': user.id,
            'userName': user.displayName,
            'userAvatar': user.photoURL ?? '',
            'imageUrl': downloadUrl,
            'caption': caption,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // ── Gamification ──────────────────────────────────────────────────────
      await ref
          .read(gamificationControllerProvider.notifier)
          .award(XpAction.uploadPhoto, relatedId: widget.id);
      await ref
          .read(gamificationControllerProvider.notifier)
          .incrementCounter('photosCount');
      _showSnack('Photo uploaded! 📸');
    } catch (e) {
      _showSnack('Upload failed: $e');
    } finally {
      setState(() {
        _isUploadingPhoto = false;
        _uploadProgress = 0;
      });
    }
  }

  Future<String> _showCaptionDialog() async {
    _captionCtrl.clear();
    return await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.col.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Add a caption',
              style: TextStyle(color: context.col.textPrimary, fontSize: 16),
            ),
            content: TextField(
              controller: _captionCtrl,
              style: TextStyle(color: context.col.textPrimary),
              cursorColor: AppColors.primary,
              maxLength: 120,
              decoration: InputDecoration(
                hintText: 'Describe this photo…',
                hintStyle: TextStyle(color: context.col.textMuted),
                filled: true,
                fillColor: context.col.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: context.col.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, ''),
                child: Text(
                  'Skip',
                  style: TextStyle(color: context.col.textSecondary),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(ctx, _captionCtrl.text.trim()),
                child: const Text('Add'),
              ),
            ],
          ),
        ) ??
        '';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: context.col.surfaceElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final photos = ref.watch(
      _communityPhotosProvider((collection: widget.collection, id: widget.id)),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.68, 0.95],
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: context.col.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── drag handle ──────────────────────────────────────────────
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.col.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),

              // ── scrollable body ──────────────────────────────────────────
              Expanded(
                child: CustomScrollView(
                  controller: scrollCtrl,
                  slivers: [
                    // Hero image + info header
                    SliverToBoxAdapter(child: _buildHeader()),

                    // Section: Rate this place
                    SliverToBoxAdapter(child: _buildRatingSection()),

                    // Section: Reviews carousel
                    SliverToBoxAdapter(child: _buildReviewsCarousel()),

                    // Section: Community photos
                    SliverToBoxAdapter(
                      child: _buildPhotosHeader(photos.asData?.value ?? []),
                    ),

                    // Photo grid
                    photos.when(
                      data: (list) => list.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmptyPhotos())
                          : SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              sliver: SliverGrid.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 6,
                                      mainAxisSpacing: 6,
                                      childAspectRatio: 1,
                                    ),
                                itemCount: list.length,
                                itemBuilder: (_, i) =>
                                    _CommunityPhotoTile(photo: list[i]),
                              ),
                            ),
                      loading: () => SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: _accentColor,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      error: (e0, e1) =>
                          SliverToBoxAdapter(child: _buildEmptyPhotos()),
                    ),

                    // Bottom padding
                    SliverToBoxAdapter(child: SizedBox(height: bottomPad + 80)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Header: hero image + place info ─────────────────────────────────────

  Widget _buildHeader() {
    return Stack(
      children: [
        // Hero image
        widget.imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: widget.imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorWidget: (e0, e1, e2) => _imageFallback(),
                placeholder: (p0, p1) => _imageFallback(),
              )
            : _imageFallback(),

        // Dark gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, context.col.surface],
              ),
            ),
          ),
        ),

        // Type badge (top-left)
        Positioned(
          top: 14,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _accentColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_emojiForType, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(
                  widget.type[0].toUpperCase() + widget.type.substring(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Place name + location + rating (bottom overlay)
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.name,
                style: TextStyle(
                  color: context.col.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  // Star rating display
                  _StarDisplay(rating: widget.rating),
                  const SizedBox(width: 6),
                  Text(
                    widget.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.star,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.ratingCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${widget.ratingCount})',
                      style: TextStyle(
                        color: context.col.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (widget.location.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: context.col.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        widget.location,
                        style: TextStyle(
                          color: context.col.textMuted,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageFallback() => Container(
    width: double.infinity,
    height: 220,
    color: context.col.surfaceElevated,
    child: Center(
      child: Text(_emojiForType, style: const TextStyle(fontSize: 48)),
    ),
  );

  // ─── Rate this place section ──────────────────────────────────────────────

  Widget _buildRatingSection() {
    // ── Locked: already submitted ────────────────────────────────────────────
    if (_submittedStar > 0) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.col.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            // Locked stars
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final filled = i + 1 <= _submittedStar;
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? AppColors.star : context.col.border,
                    size: 26,
                  ),
                );
              }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ratingLabel(_submittedStar),
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your rating has been saved',
                    style: TextStyle(color: context.col.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ],
        ),
      );
    }

    // ── Normal: not yet submitted ────────────────────────────────────────────
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.star.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: AppColors.star,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Rate this place',
                style: TextStyle(
                  color: context.col.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Interactive star row
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              final filled =
                  star <= (_hoveredStar > 0 ? _hoveredStar : _selectedStar);
              return GestureDetector(
                onTap: () => setState(() => _selectedStar = star),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveredStar = star),
                  onExit: (_) => setState(() => _hoveredStar = 0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        key: ValueKey(filled),
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: filled ? AppColors.star : context.col.border,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),

          if (_selectedStar > 0) ...[
            const SizedBox(height: 12),
            Text(
              _ratingLabel(_selectedStar),
              style: TextStyle(
                color: _accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),

            // Optional review text
            TextField(
              controller: _reviewCtrl,
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 14,
              ),
              cursorColor: AppColors.primary,
              maxLines: 3,
              maxLength: 300,
              decoration: InputDecoration(
                hintText: 'Write a quick review… (optional)',
                hintStyle: TextStyle(
                  color: context.col.textMuted,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: context.col.surface,
                counterStyle: TextStyle(color: context.col.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.col.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.col.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmittingRating ? null : _submitRating,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSubmittingRating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isSubmittingRating ? 'Submitting…' : 'Submit Rating',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Reviews carousel ─────────────────────────────────────────────────────

  Widget _buildReviewsCarousel() {
    final reviews = ref.watch(
      _reviewsProvider((collection: widget.collection, id: widget.id)),
    );

    return reviews.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.star.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.rate_review_rounded,
                      color: AppColors.star,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reviews',
                        style: TextStyle(
                          color: context.col.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${list.length} review${list.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: context.col.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Horizontal carousel
            SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                separatorBuilder: (context, _) => const SizedBox(width: 10),
                itemCount: list.length,
                itemBuilder: (_, i) => _ReviewCard(review: list[i]),
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  String _ratingLabel(int stars) {
    switch (stars) {
      case 1:
        return '😕  Not great';
      case 2:
        return '😐  It was okay';
      case 3:
        return '🙂  Pretty good';
      case 4:
        return '😊  Really good!';
      case 5:
        return '🤩  Absolutely loved it!';
      default:
        return '';
    }
  }

  // ─── Community photos header + upload button ──────────────────────────────

  Widget _buildPhotosHeader(List<CommunityPhoto> photos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community Photos',
                style: TextStyle(
                  color: context.col.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                photos.isEmpty
                    ? 'Be the first to share!'
                    : '${photos.length} photo${photos.length == 1 ? '' : 's'}',
                style: TextStyle(
                  color: context.col.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Upload button
          _isUploadingPhoto
              ? SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                      Text(
                        _uploadProgress > 0
                            ? '${(_uploadProgress * 100).round()}%'
                            : '',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: _pickAndUploadPhoto,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          color: Colors.black,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Add Photo',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyPhotos() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.col.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              color: context.col.textMuted,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No community photos yet',
            style: TextStyle(
              color: context.col.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to share your visit!',
            style: TextStyle(color: context.col.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Community photo grid tile (tappable for full view)
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityPhotoTile extends StatelessWidget {
  final CommunityPhoto photo;
  const _CommunityPhotoTile({required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullPhoto(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: photo.imageUrl,
              fit: BoxFit.cover,
              errorWidget: (e0, e1, e2) => Container(
                color: context.col.surfaceElevated,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: context.col.textMuted,
                ),
              ),
            ),
            // Uploader avatar (bottom-left)
            Positioned(
              left: 5,
              bottom: 5,
              child: _MiniAvatar(url: photo.userAvatar, name: photo.userName),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullPhoto(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (ctx, anim, secAnim) => _FullPhotoView(photo: photo),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini user avatar for photo grid tile
// ─────────────────────────────────────────────────────────────────────────────

class _MiniAvatar extends StatelessWidget {
  final String url;
  final String name;
  const _MiniAvatar({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        color: context.col.surfaceElevated,
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                errorWidget: (e0, e1, e2) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() => Center(
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen photo viewer
// ─────────────────────────────────────────────────────────────────────────────

class _FullPhotoView extends StatelessWidget {
  final CommunityPhoto photo;
  const _FullPhotoView({required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Photo
            Center(
              child: Hero(
                tag: 'community_photo_${photo.id}',
                child: CachedNetworkImage(
                  imageUrl: photo.imageUrl,
                  fit: BoxFit.contain,
                  errorWidget: (e0, e1, e2) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),

            // Caption + user info
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (photo.caption.isNotEmpty) ...[
                      Text(
                        photo.caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Row(
                      children: [
                        _MiniAvatar(
                          url: photo.userAvatar,
                          name: photo.userName,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '@${photo.userName}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Star display widget (read-only)
// ─────────────────────────────────────────────────────────────────────────────

class _StarDisplay extends StatelessWidget {
  final double rating;
  const _StarDisplay({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        final half = !filled && rating >= i + 0.5;
        return Icon(
          half
              ? Icons.star_half_rounded
              : (filled ? Icons.star_rounded : Icons.star_outline_rounded),
          color: (filled || half) ? AppColors.star : context.col.border,
          size: 14,
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review card widget (used in carousel)
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final name = (review['userName'] as String?) ?? 'Traveller';
    final avatar = review['userAvatar'] as String?;
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final comment = (review['comment'] as String?) ?? '';
    final ts = review['timestamp'];
    final DateTime? date = ts != null
        ? (ts as dynamic).toDate() as DateTime?
        : null;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info
          Row(
            children: [
              // Avatar circle
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage: (avatar != null && avatar.isNotEmpty)
                    ? NetworkImage(avatar)
                    : null,
                child: (avatar == null || avatar.isEmpty)
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Star rating + numeric
          Row(
            children: [
              _StarDisplay(rating: rating),
              const SizedBox(width: 5),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  color: context.col.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Comment
          if (comment.isNotEmpty)
            Expanded(
              child: Text(
                comment,
                style: TextStyle(
                  color: context.col.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            )
          else
            const Spacer(),

          // Timestamp
          if (date != null)
            Text(
              _formatDate(date),
              style: TextStyle(color: context.col.textMuted, fontSize: 10),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }
}
