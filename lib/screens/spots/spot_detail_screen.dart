import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/spots_controller.dart';
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
      error: (_, __) => Scaffold(
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
            backgroundColor: AppColors.bg,
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
                      : Container(color: AppColors.surfaceElevated),

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
                      color: AppColors.primary.withOpacity(0.12),
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
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: AppColors.textSecondary,
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
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
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
                  _ReviewSection(spotId: spot.id),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      // Write review FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showReviewSheet(context, ref, spot.id),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bg,
        icon: const Icon(Icons.star_outline),
        label: const Text(
          'Write Review',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
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
    if (mounted)
      setState(() {
        _bookmarked = !_bookmarked;
        _bookmarkLoading = false;
      });
  }

  void _showReviewSheet(BuildContext context, WidgetRef ref, String spotId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReviewSheet(spotId: spotId),
    );
  }
}

class _ReviewSection extends ConsumerWidget {
  final String spotId;
  const _ReviewSection({required this.spotId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read reviews live from Firestore 'reviews' subcollection
    final reviewsAsync = ref.watch(
      StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
        (r, id) => FirebaseFirestore.instance
            .collection('spots')
            .doc(id)
            .collection('reviews')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .snapshots()
            .map((s) => s.docs.map((d) => d.data()).toList()),
      )(spotId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        reviewsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, __) => const Text('Could not load reviews'),
          data: (reviews) => reviews.isEmpty
              ? const Text(
                  'No reviews yet. Be the first!',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              : Column(
                  children: reviews.take(10).map((r) {
                    final userName = r['userName'] as String? ?? 'Anonymous';
                    final rating = (r['rating'] as num?)?.toDouble() ?? 0;
                    final comment = r['comment'] as String? ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              StarRating(rating: rating),
                            ],
                          ),
                          if (comment.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              comment,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

class _ReviewSheet extends ConsumerStatefulWidget {
  final String spotId;
  const _ReviewSheet({required this.spotId});

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  double _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _loading = true);
    try {
      final user = ref.read(currentUserProvider);
      await FirebaseFirestore.instance
          .collection('spots')
          .doc(widget.spotId)
          .collection('reviews')
          .add({
            'userId': user?.id ?? '',
            'userName': user?.displayName ?? 'Anonymous',
            'rating': _rating,
            'comment': _commentCtrl.text.trim(),
            'timestamp': FieldValue.serverTimestamp(),
          });
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⭐ Review submitted!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Write a Review', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // Star selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starVal = (i + 1).toDouble();
              return GestureDetector(
                onTap: () => setState(() => _rating = starVal),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    _rating >= starVal
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.star,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Share your experience...',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_loading || _rating == 0) ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.bg,
                    ),
                  )
                : const Text('Submit Review (+10 XP)'),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
