// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider — paginated reviews (20 per page), ordered latest-first
// Uses a simple StateProvider-like approach: holds accumulated pages in state.
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewPageState {
  final List<Map<String, dynamic>> items;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDoc;
  final String? error;

  const _ReviewPageState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDoc,
    this.error,
  });

  _ReviewPageState copyWith({
    List<Map<String, dynamic>>? items,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDoc,
    String? error,
  }) => _ReviewPageState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    lastDoc: lastDoc ?? this.lastDoc,
    error: error,
  );
}

// Args passed as a record: (collection, id)
typedef _ReviewArgs = ({String collection, String id});

// Notifier class — Riverpod 3 family: arg passed via constructor
class _ReviewPagerNotifier extends Notifier<_ReviewPageState> {
  final _ReviewArgs _arg;
  _ReviewPagerNotifier(this._arg);

  static const _pageSize = 20;

  @override
  _ReviewPageState build() {
    Future.microtask(loadMore);
    return const _ReviewPageState(isLoading: false);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      Query q = FirebaseFirestore.instance
          .collection(_arg.collection)
          .doc(_arg.id)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .limit(_pageSize);

      if (state.lastDoc != null) {
        q = q.startAfterDocument(state.lastDoc!);
      }

      final snap = await q.get();
      final newItems = snap.docs
          .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
          .toList();

      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoading: false,
        hasMore: snap.docs.length == _pageSize,
        lastDoc: snap.docs.isNotEmpty ? snap.docs.last : state.lastDoc,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    state = const _ReviewPageState(isLoading: false);
    await loadMore();
  }
}

// Provider factory function keyed by args
final _reviewPagerProvider = NotifierProvider.autoDispose
    .family<_ReviewPagerNotifier, _ReviewPageState, _ReviewArgs>(
      (arg) => _ReviewPagerNotifier(arg),
    );

// ─────────────────────────────────────────────────────────────────────────────
// AllReviewsScreen
// ─────────────────────────────────────────────────────────────────────────────

class AllReviewsScreen extends ConsumerStatefulWidget {
  /// Firestore root collection: 'spots' | 'restaurants' | 'cafes' | 'hotels' | 'homestays' | 'adventureSpots' | 'shoppingAreas'
  final String collection;
  final String entityId;
  final String entityName;
  final double averageRating;
  final int totalRatings;

  const AllReviewsScreen({
    super.key,
    required this.collection,
    required this.entityId,
    required this.entityName,
    required this.averageRating,
    required this.totalRatings,
  });

  @override
  ConsumerState<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends ConsumerState<AllReviewsScreen> {
  int? _filterStar; // null = all
  final _scrollCtrl = ScrollController();

  _ReviewArgs get _args => (collection: widget.collection, id: widget.entityId);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(_reviewPagerProvider(_args).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_reviewPagerProvider(_args));

    // Client-side star filter
    final allItems = state.items;
    final filtered = _filterStar == null
        ? allItems
        : allItems
              .where(
                (r) => ((r['rating'] as num?)?.round() ?? 0) == _filterStar,
              )
              .toList();

    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.col.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reviews',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.entityName,
              style: TextStyle(color: context.col.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () =>
            ref.read(_reviewPagerProvider(_args).notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            // ── Rating summary card ───────────────────────────────────
            SliverToBoxAdapter(
              child: _RatingSummaryCard(
                averageRating: widget.averageRating,
                totalRatings: widget.totalRatings,
                reviews: allItems,
              ),
            ),

            // ── Star filter chips ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _StarFilterBar(
                selected: _filterStar,
                reviews: allItems,
                onSelect: (s) =>
                    setState(() => _filterStar = (_filterStar == s) ? null : s),
              ),
            ),

            // ── Count label ───────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  _filterStar == null
                      ? '${allItems.length} review${allItems.length != 1 ? 's' : ''}'
                            '${state.hasMore ? '+' : ''}'
                      : '${filtered.length} with $_filterStar ★',
                  style: TextStyle(
                    color: context.col.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // ── Reviews list ──────────────────────────────────────────
            if (filtered.isEmpty && !state.isLoading)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 48,
                        color: context.col.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _filterStar != null
                            ? 'No $_filterStar-star reviews yet'
                            : 'No reviews yet — be the first! ✨',
                        style: TextStyle(color: context.col.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _ReviewCard(review: filtered[i]),
                ),
              ),

            // ── Load-more indicator ───────────────────────────────────
            if (state.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),

            if (!state.hasMore && filtered.isNotEmpty && _filterStar == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32, top: 8),
                  child: Center(
                    child: Text(
                      '— End of reviews —',
                      style: TextStyle(
                        color: context.col.textMuted,
                        fontSize: 12,
                      ),
                    ),
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
// Rating summary card  (big score + linear star breakdown bars)
// ─────────────────────────────────────────────────────────────────────────────

class _RatingSummaryCard extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final List<Map<String, dynamic>> reviews;

  const _RatingSummaryCard({
    required this.averageRating,
    required this.totalRatings,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    // Count per star from loaded reviews
    final counts = List.filled(6, 0); // index 1-5
    for (final r in reviews) {
      final s = ((r['rating'] as num?)?.round() ?? 0).clamp(1, 5);
      counts[s]++;
    }
    final total = reviews.isEmpty ? 1 : reviews.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big score
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  color: context.col.textPrimary,
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < averageRating.floor()
                        ? Icons.star_rounded
                        : (i < averageRating
                              ? Icons.star_half_rounded
                              : Icons.star_outline_rounded),
                    size: 14,
                    color: AppColors.star,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalRatings rating${totalRatings != 1 ? 's' : ''}',
                style: TextStyle(color: context.col.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Bar breakdown
          Expanded(
            child: Column(
              children: List.generate(5, (idx) {
                final star = 5 - idx; // 5 down to 1
                final count = counts[star];
                final pct = count / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: TextStyle(
                          color: context.col.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.star_rounded, size: 11, color: AppColors.star),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 7,
                            backgroundColor: context.col.border,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _barColor(star),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 22,
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: context.col.textMuted,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Color _barColor(int star) {
    switch (star) {
      case 5:
        return const Color(0xFF22C55E);
      case 4:
        return const Color(0xFF84CC16);
      case 3:
        return const Color(0xFFFACC15);
      case 2:
        return const Color(0xFFF97316);
      default:
        return const Color(0xFFEF4444);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Star filter chip bar
// ─────────────────────────────────────────────────────────────────────────────

class _StarFilterBar extends StatelessWidget {
  final int? selected;
  final List<Map<String, dynamic>> reviews;
  final ValueChanged<int> onSelect;

  const _StarFilterBar({
    required this.selected,
    required this.reviews,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // Count per star
    final counts = List.filled(6, 0);
    for (final r in reviews) {
      final s = ((r['rating'] as num?)?.round() ?? 0).clamp(1, 5);
      counts[s]++;
    }

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final star = 5 - idx;
          final isSelected = selected == star;
          return GestureDetector(
            onTap: () => onSelect(star),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.star.withValues(alpha: 0.15)
                    : context.col.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.star : context.col.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: isSelected ? AppColors.star : context.col.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$star  (${counts[star]})',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.star
                          : context.col.textSecondary,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review card (full width)
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
      padding: const EdgeInsets.all(16),
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
              // Avatar
              CircleAvatar(
                radius: 20,
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
                          fontSize: 15,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.star.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.star.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: AppColors.star,
                    ),
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
              ),
            ],
          ),
          // Inline star row
          const SizedBox(height: 10),
          Row(
            children: List.generate(5, (i) {
              final filled = i < rating.floor();
              final half = !filled && i < rating;
              return Icon(
                filled
                    ? Icons.star_rounded
                    : (half
                          ? Icons.star_half_rounded
                          : Icons.star_outline_rounded),
                size: 15,
                color: AppColors.star,
              );
            }),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: TextStyle(
                color: context.col.textSecondary,
                fontSize: 14,
                height: 1.55,
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
