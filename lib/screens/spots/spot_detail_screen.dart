import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/spots_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/spot_model.dart';
import '../../widgets/shared_widgets.dart';

class SpotDetailScreen extends ConsumerWidget {
  final String id;
  const SpotDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotAsync = ref.watch(spotDetailProvider(id));

    return spotAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        body: const EmptyState(emoji: '😕', title: 'Could not load spot'),
        appBar: AppBar(),
      ),
      data: (spot) => spot == null ? _notFound() : _SpotDetailBody(spot: spot),
    );
  }

  Widget _notFound() => Scaffold(
    appBar: AppBar(),
    body: const EmptyState(emoji: '🔍', title: 'Spot not found'),
  );
}

class _SpotDetailBody extends ConsumerStatefulWidget {
  final SpotModel spot;
  const _SpotDetailBody({required this.spot});

  @override
  ConsumerState<_SpotDetailBody> createState() => _SpotDetailBodyState();
}

class _SpotDetailBodyState extends ConsumerState<_SpotDetailBody> {
  bool _bookmarked = false;
  bool _bookmarkLoading = false;
  int _imageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final spot = widget.spot;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Image hero ───────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: context.col.bg,
            actions: [
              if (user != null)
                IconButton(
                  icon: Icon(
                    _bookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline,
                    color: _bookmarked ? AppColors.primary : Colors.white,
                  ),
                  onPressed: _bookmarkLoading
                      ? null
                      : () => _toggleBookmark(spot.id),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  spot.imagesUrl.isNotEmpty
                      ? PageView.builder(
                          itemCount: spot.imagesUrl.length,
                          onPageChanged: (i) => setState(() => _imageIndex = i),
                          itemBuilder: (_, i) => CachedNetworkImage(
                            imageUrl: spot.imagesUrl[i],
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(color: context.col.surfaceElevated),

                  // Page dots
                  if (spot.imagesUrl.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          spot.imagesUrl.length,
                          (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _imageIndex == i ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _imageIndex == i
                                  ? AppColors.primary
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      spot.category,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Name + rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          spot.name,
                          style: Theme.of(
                            context,
                          ).textTheme.displayLarge?.copyWith(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      StarRating(rating: spot.averageRating, size: 18),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: context.col.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          spot.locationAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Stats row
                  Row(
                    children: [
                      Flexible(
                        child: _InfoPill(
                          icon: Icons.visibility_outlined,
                          label: '${spot.views} views',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _InfoPill(
                          icon: Icons.trending_up,
                          label: '${spot.popularity} popularity',
                        ),
                      ),
                    ],
                  ),

                  // ── Story ──────────────────────────────────────────
                  if (spot.placeStory != null &&
                      spot.placeStory!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      spot.placeStory!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.6),
                    ),
                  ],

                  // ── Things to do ───────────────────────────────────
                  if (spot.thingsToDo.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Things To Do',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: spot.thingsToDo
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: context.col.surfaceElevated,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: context.col.border),
                              ),
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.col.textSecondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  // ── Entry fees ─────────────────────────────────────
                  if (spot.entryFees.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Entry Fees',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ...spot.entryFees.map(
                      (fee) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Text(
                              fee.type,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const Spacer(),
                            Text(
                              '₹${fee.amount}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ── Reviews ────────────────────────────────────────
                  const SizedBox(height: 28),
                  _ReviewSection(
                    spotId: spot.id,
                    entityName: spot.name,
                    averageRating: spot.averageRating,
                    totalRatings: spot.ratingsCount,
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

  Future<void> _toggleBookmark(String spotId) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _bookmarkLoading = true);
    try {
      final ref2 = FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .collection('bookmarks')
          .doc(spotId);
      if (_bookmarked) {
        await ref2.delete();
      } else {
        await ref2.set({
          'spotId': spotId,
          'savedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _bookmarked = !_bookmarked;
        _bookmarkLoading = false;
      });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reviews Section
// ─────────────────────────────────────────────────────────────────────────────

final _spotReviewsProvider = StreamProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>(
      (ref, spotId) => FirebaseFirestore.instance
          .collection('spots')
          .doc(spotId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots()
          .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList()),
    );

class _ReviewSection extends ConsumerStatefulWidget {
  final String spotId;
  final String entityName;
  final double averageRating;
  final int totalRatings;
  const _ReviewSection({
    required this.spotId,
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
      await FirebaseFirestore.instance
          .collection('spots')
          .doc(widget.spotId)
          .collection('reviews')
          .add({
            'userId': user.id,
            'userName': user.displayName,
            'userAvatar': user.photoURL ?? '',
            'rating': _myRating,
            'comment': comment,
            'timestamp': FieldValue.serverTimestamp(),
          });
      _commentCtrl.clear();
      setState(() {
        _showForm = false;
        _submitting = false;
        _myRating = 5;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted! ✨'),
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
    final reviewsAsync = ref.watch(_spotReviewsProvider(widget.spotId));
    final user = ref.watch(currentUserProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
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
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _showForm
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : context.col.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _showForm ? AppColors.primary : context.col.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showForm
                            ? Icons.close_rounded
                            : Icons.rate_review_rounded,
                        size: 14,
                        color: _showForm
                            ? AppColors.primary
                            : context.col.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _showForm ? 'Cancel' : 'Write Review',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _showForm
                              ? AppColors.primary
                              : context.col.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        // Write-review form
        if (_showForm) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.col.surfaceElevated,
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) {
                    final starVal = (i + 1).toDouble();
                    return GestureDetector(
                      onTap: () => setState(() => _myRating = starVal),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          _myRating >= starVal
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppColors.star,
                          size: 32,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _commentCtrl,
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontSize: 14,
                  ),
                  cursorColor: AppColors.primary,
                  maxLines: 3,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: 'Share your experience…',
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
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _submitting
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
                      _submitting ? 'Submitting…' : 'Submit Review',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Reviews list (latest 5)
        reviewsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Could not load reviews',
              style: TextStyle(color: context.col.textMuted),
            ),
          ),
          data: (reviews) => reviews.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.col.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.col.border),
                  ),
                  child: Center(
                    child: Text(
                      'No reviews yet — be the first! ✨',
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
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
                    ),
                    const SizedBox(height: 14),
                    // View All button
                    GestureDetector(
                      onTap: () => context.push(
                        AppRoutes.allReviewsPath(
                          collection: 'spots',
                          id: widget.spotId,
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
                ),
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
    final ts = review['timestamp'];
    final DateTime? date = ts != null
        ? (ts as dynamic).toDate() as DateTime?
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
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
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                backgroundImage: userAvatar.isNotEmpty
                    ? NetworkImage(userAvatar)
                    : null,
                child: userAvatar.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
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
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (date != null)
                      Text(
                        _formatDate(date),
                        style: TextStyle(
                          color: context.col.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              // Star badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.star.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: AppColors.star,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.star,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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

// ─────────────────────────────────────────────────────────────────────────────
// Info Pill
// ─────────────────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: context.col.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: context.col.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
