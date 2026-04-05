import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/listing_models.dart';
import '../../services/firestore_cafes_service.dart';
import '../../widgets/shared_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CafeDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class CafeDetailScreen extends ConsumerWidget {
  final String id;
  const CafeDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cafeDetailProvider(id));

    return async.when(
      loading: () => Scaffold(
        backgroundColor: context.col.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) => Scaffold(
        backgroundColor: context.col.bg,
        appBar: AppBar(backgroundColor: context.col.bg),
        body: const EmptyState(emoji: '😕', title: 'Could not load cafe'),
      ),
      data: (c) => c == null
          ? Scaffold(
              backgroundColor: context.col.bg,
              appBar: AppBar(backgroundColor: context.col.bg),
              body: const EmptyState(emoji: '🔍', title: 'Cafe not found'),
            )
          : _CafeBody(cafe: c),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _CafeBody extends ConsumerStatefulWidget {
  final CafeModel cafe;
  const _CafeBody({required this.cafe});

  @override
  ConsumerState<_CafeBody> createState() => _CafeBodyState();
}

class _CafeBodyState extends ConsumerState<_CafeBody> {
  int _imageIndex = 0;
  bool _showAllDesc = false;

  CafeModel get c => widget.cafe;

  @override
  Widget build(BuildContext context) {
    final images = c.images.isNotEmpty ? c.images : [c.heroImage];

    return Scaffold(
      backgroundColor: context.col.bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero image ─────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: context.col.bg,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.col.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: context.col.textPrimary,
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  images[_imageIndex].isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: images[_imageIndex],
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              Container(color: context.col.surfaceElevated),
                          errorWidget: (_, _, _) => Container(
                            color: context.col.surfaceElevated,
                            child: Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: context.col.textMuted,
                                size: 48,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: context.col.surfaceElevated,
                          child: Center(
                            child: Icon(
                              Icons.coffee,
                              color: context.col.textMuted,
                              size: 64,
                            ),
                          ),
                        ),
                  // Bottom fade
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            context.col.bg.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Image dots
                  if (images.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length > 5 ? 5 : images.length,
                          (i) => GestureDetector(
                            onTap: () => setState(() => _imageIndex = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: _imageIndex == i ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _imageIndex == i
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: TextStyle(
                            color: context.col.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _RatingBadge(rating: c.rating),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          c.location.isNotEmpty ? c.location : c.district,
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (c.priceRange.isNotEmpty)
                        _Badge(
                          label: c.priceRange,
                          color: AppColors.primary,
                          bgColor: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      if (c.district.isNotEmpty)
                        _Badge(
                          label: c.district,
                          color: context.col.textSecondary,
                          bgColor: context.col.surfaceElevated,
                          hasBorder: true,
                        ),
                      for (final s in c.specialties.take(3))
                        _Badge(
                          label: s,
                          color: AppColors.secondary,
                          bgColor: AppColors.secondary.withValues(alpha: 0.1),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Info panel
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.col.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.col.border),
                    ),
                    child: Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        if (c.openingHours.isNotEmpty)
                          _InfoDot(
                            icon: Icons.schedule_outlined,
                            label: c.openingHours,
                          ),
                        if (c.hasWifi)
                          const _InfoDot(
                            icon: Icons.wifi_rounded,
                            label: 'Free WiFi',
                          ),
                        if (c.hasOutdoorSeating)
                          const _InfoDot(
                            icon: Icons.deck_rounded,
                            label: 'Outdoor Seating',
                          ),
                        if (c.contactPhone.isNotEmpty)
                          _InfoDot(
                            icon: Icons.phone_outlined,
                            label: c.contactPhone,
                          ),
                      ],
                    ),
                  ),

                  // Description
                  if (c.description.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'About',
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      c.description,
                      maxLines: _showAllDesc ? null : 4,
                      overflow: _showAllDesc
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    if (c.description.length > 200)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showAllDesc = !_showAllDesc),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _showAllDesc ? 'Show less' : 'Read more',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],

                  // Gallery
                  if (images.length > 1) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Gallery',
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => setState(() => _imageIndex = i),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: images[i],
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                width: 90,
                                color: context.col.surfaceElevated,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Reviews
                  const SizedBox(height: 32),
                  Divider(height: 1, color: context.col.border),
                  const SizedBox(height: 24),
                  _ReviewSection(
                    cafeId: c.id,
                    entityName: c.name,
                    averageRating: c.rating,
                    totalRatings: c.ratingsCount,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reviews Section
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewSection extends ConsumerStatefulWidget {
  final String cafeId;
  final String entityName;
  final double averageRating;
  final int totalRatings;
  const _ReviewSection({
    required this.cafeId,
    required this.entityName,
    required this.averageRating,
    required this.totalRatings,
  });

  @override
  ConsumerState<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<_ReviewSection> {
  bool _showForm = false;
  double _myRating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to leave a review')),
      );
      return;
    }
    final comment = _commentCtrl.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please write a comment')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(firestoreCafesServiceProvider)
          .submitReview(
            cafeId: widget.cafeId,
            userId: user.id,
            userName: user.displayName,
            userAvatar: user.photoURL ?? '',
            rating: _myRating,
            comment: comment,
          );
      _commentCtrl.clear();
      setState(() {
        _showForm = false;
        _submitting = false;
        _myRating = 5;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(cafeReviewsProvider(widget.cafeId));
    final user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (user != null)
              GestureDetector(
                onTap: () => setState(() => _showForm = !_showForm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showForm ? Icons.close : Icons.rate_review_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showForm ? 'Cancel' : 'Write Review',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // Form
        if (_showForm) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.col.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.col.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Rating',
                  style: TextStyle(
                    color: context.col.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    final star = (i + 1).toDouble();
                    return GestureDetector(
                      onTap: () => setState(() => _myRating = star),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.star_rounded,
                          size: 32,
                          color: star <= _myRating
                              ? AppColors.star
                              : context.col.border,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Share your experience…',
                    hintStyle: TextStyle(
                      color: context.col.textMuted,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: context.col.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.col.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.col.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Submit Review',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // List (latest 5)
        reviewsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (_, _) => Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Could not load reviews',
              style: TextStyle(color: context.col.textMuted),
            ),
          ),
          data: (allReviews) {
            final reviews = allReviews.take(5).toList();
            return reviews.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.col.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.col.border),
                    ),
                    child: Center(
                      child: Text(
                        'No reviews yet — be the first!',
                        style: TextStyle(color: context.col.textMuted),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => context.push(
                          AppRoutes.allReviewsPath(
                            collection: 'cafes',
                            id: widget.cafeId,
                            name: widget.entityName,
                            avg: widget.averageRating,
                            total: widget.totalRatings,
                          ),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.rate_review_outlined,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'View All Reviews',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review Card
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
    final comment = review['comment']?.toString() ?? '';
    final userName = review['userName']?.toString() ?? 'Anonymous';
    final userAvatar = review['userAvatar']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.col.surfaceElevated,
                backgroundImage: userAvatar.isNotEmpty
                    ? NetworkImage(userAvatar)
                    : null,
                child: userAvatar.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: context.col.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          size: 13,
                          color: (i + 1) <= rating
                              ? AppColors.star
                              : context.col.border,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: TextStyle(
                color: context.col.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge({required this.rating});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.star.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.star.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.star,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  final bool hasBorder;
  const _Badge({
    required this.label,
    required this.color,
    required this.bgColor,
    this.hasBorder = false,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      border: hasBorder ? Border.all(color: context.col.border) : null,
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

class _InfoDot extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoDot({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.primary),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(color: context.col.textSecondary, fontSize: 12),
      ),
    ],
  );
}
