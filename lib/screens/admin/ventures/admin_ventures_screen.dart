// lib/screens/admin/ventures/admin_ventures_screen.dart
//
// Admin "Ventures" management screen.
//
// Tab 1 – Packages       : streams from `ventures` collection
// Tab 2 – Registrations  : streams from `ventures/{docId}/registrations` sub-collections
// Tab 3 – Feedback       : streams from `ventures/{docId}/feedback` sub-collections
// Tab 4 – Bookings       : streams from top-level `bookings` collection

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../controllers/booking_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/booking_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Safe data helpers
// ─────────────────────────────────────────────────────────────────────────────

String _str(Map<String, dynamic> d, List<String> keys, {String fb = ''}) {
  for (final k in keys) {
    final v = d[k];
    if (v == null) continue;
    final s = v.toString();
    if (s.isNotEmpty && s != 'null') return s;
  }
  return fb;
}

double _dbl(Map<String, dynamic> d, String key, {double fb = 0}) {
  final v = d[key];
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? fb;
}

bool _bool(Map<String, dynamic> d, String key, {bool fb = false}) {
  final v = d[key];
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v?.toString().toLowerCase();
  if (s == 'true') return true;
  if (s == 'false') return false;
  return fb;
}

int _listLen(Map<String, dynamic> d, String key) {
  final v = d[key];
  return v is List ? v.length : 0;
}

String? _imageUrl(Map<String, dynamic> d) {
  for (final k in ['images', 'imageUrls', 'imagesUrl']) {
    final v = d[k];
    if (v is List && v.isNotEmpty) {
      final s = v.first?.toString() ?? '';
      if (s.isNotEmpty && s != 'null') return s;
    }
  }
  for (final k in ['imageUrl', 'image', 'coverImage']) {
    final s = d[k]?.toString() ?? '';
    if (s.isNotEmpty && s != 'null') return s;
  }
  return null;
}

String _formatDate(dynamic ts) {
  if (ts is Timestamp) {
    final d = ts.toDate();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }
  return '';
}

Map<String, dynamic> _safeMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return {};
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

/// All venture packages, newest first.
final venturePackagesProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collection('ventures')
      .orderBy('createdAt', descending: true)
      .snapshots();
});

/// All registrations from every ventures/{docId}/registrations sub-collection.
final allVentureRegistrationsProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collectionGroup('registrations')
      .orderBy('createdAt', descending: true)
      .snapshots();
});

/// All feedback from every ventures/{docId}/feedback sub-collection.
/// Sorted client-side (newest first) to avoid requiring a composite index.
final allVentureFeedbackProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collectionGroup('feedback')
      .snapshots();
});

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminVenturesScreen extends ConsumerStatefulWidget {
  const AdminVenturesScreen({super.key});

  @override
  ConsumerState<AdminVenturesScreen> createState() =>
      _AdminVenturesScreenState();
}

class _AdminVenturesScreenState extends ConsumerState<AdminVenturesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packagesAsync = ref.watch(venturePackagesProvider);
    final fbAsync = ref.watch(allVentureFeedbackProvider);
    final bookingsAsync = ref.watch(allBookingsProvider);

    final pkgCount = packagesAsync.value?.docs.length ?? 0;
    final fbCount = fbAsync.value?.docs.length ?? 0;
    final bookingCount = bookingsAsync.value?.length ?? 0;

    final col = context.col;

    return Scaffold(
      backgroundColor: col.bg,
      body: Column(
        children: [
          _VenturesHeader(
            tabs: _tabs,
            pkgCount: pkgCount,
            fbCount: fbCount,
            bookingCount: bookingCount,
          ),
          Divider(height: 1, color: col.border),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _PackagesTab(),
                _FeedbackTab(),
                _BookingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _VenturesHeader extends StatelessWidget {
  final TabController tabs;
  final int pkgCount;
  final int fbCount;
  final int bookingCount;

  const _VenturesHeader({
    required this.tabs,
    required this.pkgCount,
    required this.fbCount,
    required this.bookingCount,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      color: col.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Iconsax.map, color: AppColors.primary, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ventures',
                        style: TextStyle(
                          color: col.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '$pkgCount package${pkgCount == 1 ? '' : 's'} · '
                        '$bookingCount booking${bookingCount == 1 ? '' : 's'} · '
                        '$fbCount review${fbCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: col.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      context.push(AppRoutes.adminAddVenturePath()),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'New',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: tabs,
            labelColor: AppColors.primary,
            unselectedLabelColor: col.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
            tabs: [
              _CountTab(label: 'Packages', count: pkgCount),
              _CountTab(label: 'Feedback', count: fbCount),
              _CountTab(label: 'Bookings', count: bookingCount),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountTab extends StatelessWidget {
  final String label;
  final int count;
  const _CountTab({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Packages
// ─────────────────────────────────────────────────────────────────────────────

class _PackagesTab extends ConsumerWidget {
  const _PackagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(venturePackagesProvider);

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => _ErrorState(message: e.toString()),
      data: (snap) {
        if (snap.docs.isEmpty) {
          return _EmptyState(
            icon: Icons.explore_off_outlined,
            title: 'No venture packages yet',
            subtitle:
                'Tap "New" above to create your first adventure venture.',
            actionLabel: 'Add First Venture',
            onAction: () => context.push(AppRoutes.adminAddVenturePath()),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          itemCount: snap.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            try {
              final doc = snap.docs[i];
              return _PackageCard(docId: doc.id, data: _safeMap(doc.data()));
            } catch (e) {
              return _ErrorCard('venture', snap.docs[i].id, e);
            }
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Package card
// ─────────────────────────────────────────────────────────────────────────────

class _PackageCard extends ConsumerWidget {
  final String docId;
  final Map<String, dynamic> data;
  const _PackageCard({required this.docId, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;

    final title = _str(data, ['title', 'name'], fb: 'Untitled Venture');
    final tagline = _str(data, ['tagline', 'subtitle']);
    final location = _str(data, ['location', 'district']);
    final category = _str(data, ['category']);
    final difficulty = _str(data, ['difficulty']);
    final startingPrice = _dbl(data, 'startingPrice');
    final isAvailable = _bool(data, 'isAvailable', fb: true);
    final isFeatured = _bool(data, 'isFeatured');
    final status = _str(data, ['status'], fb: 'active');
    final tiers = _listLen(data, 'pricingTiers');
    final addons = _listLen(data, 'addons');
    final medals = _listLen(data, 'medals');
    final challenges = _listLen(data, 'challenges');
    final slots = _listLen(data, 'scheduleSlots');
    final imgUrl = _imageUrl(data);
    final durationDays = _dbl(data, 'durationDays', fb: 1).toInt();
    final maxGroup = _dbl(data, 'maxGroupSize').toInt();

    final statusColor = switch (status) {
      'active' => const Color(0xFF22C55E),
      'draft' => const Color(0xFFF59E0B),
      'suspended' => AppColors.error,
      _ => const Color(0xFF6B7280),
    };

    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image or placeholder header
          if (imgUrl != null)
            Stack(
              children: [
                Image.network(
                  imgUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Wrap(
                    spacing: 4,
                    children: [
                      if (isFeatured) _Pill('Featured', AppColors.primary, icon: Iconsax.star5),
                      _Pill(
                        status[0].toUpperCase() + status.substring(1),
                        statusColor,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Container(
              height: 56,
              width: double.infinity,
              color: AppColors.primary.withValues(alpha: 0.07),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.explore_outlined,
                      color: AppColors.primary, size: 22),
                  const Spacer(),
                  if (isFeatured) ...[
                    _Pill('Featured', AppColors.primary, icon: Iconsax.star5),
                    const SizedBox(width: 4),
                  ],
                  _Pill(
                    status[0].toUpperCase() + status.substring(1),
                    statusColor,
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: col.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isAvailable) ...[
                      const SizedBox(width: 6),
                      _Pill('Closed', AppColors.error),
                    ],
                  ],
                ),

                if (tagline.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    tagline,
                    style: TextStyle(
                      color: col.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    if (location.isNotEmpty)
                      _MetaChip(Icons.location_on_outlined, location),
                    if (category.isNotEmpty)
                      _MetaChip(Icons.category_outlined, category),
                    if (difficulty.isNotEmpty)
                      _MetaChip(
                        Icons.trending_up_rounded,
                        difficulty,
                        color: _diffColor(difficulty),
                      ),
                    _MetaChip(
                      Icons.currency_rupee,
                      '${startingPrice.toStringAsFixed(0)}+',
                      color: AppColors.primary,
                    ),
                    if (durationDays > 0)
                      _MetaChip(
                        Icons.schedule_outlined,
                        '$durationDays day${durationDays == 1 ? '' : 's'}',
                      ),
                    if (maxGroup > 0)
                      _MetaChip(Icons.group_outlined, 'max $maxGroup'),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    _StatBadge('$tiers', 'tiers', const Color(0xFF3B82F6)),
                    const SizedBox(width: 6),
                    _StatBadge('$addons', 'add-ons', const Color(0xFF8B5CF6)),
                    const SizedBox(width: 6),
                    _StatBadge('$medals', 'medals', const Color(0xFFF59E0B)),
                    const SizedBox(width: 6),
                    _StatBadge('$challenges', 'dares', const Color(0xFFEF4444)),
                    const SizedBox(width: 6),
                    _StatBadge('$slots', 'slots', const Color(0xFF10B981)),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: col.border),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context
                            .push(AppRoutes.adminEditVenturePath(docId)),
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: BorderSide(
                            color: AppColors.secondary.withValues(alpha: 0.4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context, ref),
                        icon: const Icon(Icons.delete_outline, size: 14),
                        label: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.4),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _diffColor(String d) => switch (d.toLowerCase()) {
    'easy' => const Color(0xFF22C55E),
    'moderate' => const Color(0xFFF59E0B),
    'challenging' => const Color(0xFFEF4444),
    'extreme' => const Color(0xFF7C3AED),
    _ => const Color(0xFF6B7280),
  };

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            Text(
              'Delete Venture?',
              style: TextStyle(
                color: context.col.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'This permanently deletes the venture. Sub-collection data '
          '(registrations, feedback) will remain in Firestore.',
          style: TextStyle(
            color: context.col.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.col.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await ref
          .read(adminListingNotifierProvider.notifier)
          .deleteListing('ventures', docId);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Feedback
// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackTab extends ConsumerWidget {
  const _FeedbackTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allVentureFeedbackProvider);

    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => _ErrorState(message: e.toString()),
      data: (snap) {
        // Sort newest first client-side (no composite index needed)
        final docs = snap.docs.toList()
          ..sort((a, b) {
            final aTs = _safeMap(a.data())['createdAt'];
            final bTs = _safeMap(b.data())['createdAt'];
            if (aTs is Timestamp && bTs is Timestamp) {
              return bTs.compareTo(aTs);
            }
            return 0;
          });

        if (docs.isEmpty) {
          return const _EmptyState(
            icon: Icons.rate_review_outlined,
            title: 'No feedback yet',
            subtitle:
                'Once users complete a venture and leave a review, their feedback will appear here.',
          );
        }

        double totalRating = 0;
        int ratedCount = 0;
        for (final doc in docs) {
          final r = _dbl(_safeMap(doc.data()), 'rating');
          if (r > 0) {
            totalRating += r;
            ratedCount++;
          }
        }
        final avgRating = ratedCount > 0 ? totalRating / ratedCount : 0.0;
        final highRated = docs
            .where((d) => _dbl(_safeMap(d.data()), 'rating') >= 4.5)
            .length;
        final lowRated = docs
            .where((d) {
              final r = _dbl(_safeMap(d.data()), 'rating');
              return r > 0 && r < 3;
            })
            .length;

        return Column(
          children: [
            _SummaryBanner(
              items: [
                _SummaryItem('Total', '${docs.length}', AppColors.primary),
                _SummaryItem(
                    'Avg Rating', avgRating.toStringAsFixed(1), const Color(0xFFF59E0B)),
                _SummaryItem('5 Stars', '$highRated', const Color(0xFF22C55E)),
                _SummaryItem('Below 3', '$lowRated', AppColors.error),
              ],
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  try {
                    return _FeedbackCard(data: _safeMap(docs[i].data()));
                  } catch (e) {
                    return _ErrorCard('feedback', docs[i].id, e);
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _FeedbackCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final col = context.col;

    final userName =
        _str(data, ['userName', 'displayName', 'name'], fb: 'Anonymous');
    final ventureName =
        _str(data, ['ventureName', 'packageName', 'title'], fb: 'Venture');
    final rating = _dbl(data, 'rating');
    final comment = _str(data, ['comment', 'review', 'feedback']);
    final tierUsed = _str(data, ['tierName', 'selectedTier']);
    final createdAt = _formatDate(data['createdAt']);
    final bookingId = data['bookingId'] as String? ?? '';
    final isBookingReview = bookingId.isNotEmpty;

    final ratingColor = rating >= 4
        ? const Color(0xFF22C55E)
        : rating >= 3
            ? const Color(0xFFF59E0B)
            : AppColors.error;

    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBookingReview
              ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
              : col.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Source strip (booking reviews only) ──────────────────
          if (isBookingReview)
            Container(
              width: double.infinity,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_rounded,
                      size: 11, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 5),
                  const Text(
                    'Booking Review',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF59E0B),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Ref: ${bookingId.length > 8 ? bookingId.substring(0, 8).toUpperCase() : bookingId.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 10,
                      color: col.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ── Card body ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar + name + venture + rating badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          userName.isNotEmpty
                              ? userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: TextStyle(
                              color: col.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            ventureName,
                            style: TextStyle(
                                color: col.textSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (rating > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ratingColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: ratingColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                color: ratingColor, size: 14),
                            const SizedBox(width: 3),
                            Text(
                              rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: ratingColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Star row
                if (rating > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFF59E0B),
                        size: 16,
                      );
                    }),
                  ),
                ],

                // Comment
                if (comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    comment,
                    style: TextStyle(
                      color: col.textSecondary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 8),

                // Tier + date
                Row(
                  children: [
                    if (tierUsed.isNotEmpty) ...[
                      _MetaChip(Icons.layers_outlined, tierUsed),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    if (createdAt.isNotEmpty)
                      Text(
                        createdAt,
                        style:
                            TextStyle(color: col.textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary banner
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryItem {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem(this.label, this.value, this.color);
}

class _SummaryBanner extends StatelessWidget {
  final List<_SummaryItem> items;
  const _SummaryBanner({required this.items});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items
            .map(
              (item) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.value,
                    style: TextStyle(
                      color: item.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: col.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared UI atoms
// ─────────────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Pill(this.label, this.color, {this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, color: color, size: 10), const SizedBox(width: 3)],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MetaChip(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.col.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: c,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String count;
  final String label;
  final Color color;
  const _StatBadge(this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(6),
    ),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: count,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          TextSpan(
            text: ' $label',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty & error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: col.surface,
                shape: BoxShape.circle,
                border: Border.all(color: col.border, width: 1.5),
              ),
              child: Icon(icon, color: col.textMuted, size: 40),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: col.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 44),
          const SizedBox(height: 12),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: context.col.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(color: AppColors.error, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String type;
  final String docId;
  final Object error;
  const _ErrorCard(this.type, this.docId, this.error);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
    ),
    child: Text(
      'Invalid $type data ($docId): $error',
      style: const TextStyle(color: AppColors.error, fontSize: 11),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 4 — Bookings
// ─────────────────────────────────────────────────────────────────────────────

class _BookingsTab extends ConsumerStatefulWidget {
  const _BookingsTab();

  @override
  ConsumerState<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends ConsumerState<_BookingsTab> {
  BookingStatus? _filter; // null = show all

  static const _statuses = [
    null,
    BookingStatus.pending,
    BookingStatus.confirmed,
    BookingStatus.completed,
    BookingStatus.cancelled,
  ];

  static const _filterLabels = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(allBookingsProvider);
    final col = context.col;

    return bookingsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
      data: (all) {
        final filtered = _filter == null
            ? all
            : all.where((b) => b.status == _filter).toList();

        final pending =
            all.where((b) => b.status == BookingStatus.pending).length;
        final confirmed =
            all.where((b) => b.status == BookingStatus.confirmed).length;
        final cancelled =
            all.where((b) => b.status == BookingStatus.cancelled).length;
        final completed =
            all.where((b) => b.status == BookingStatus.completed).length;

        return Column(
          children: [
            // ─ Summary banner ─────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: col.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: col.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BStat('${all.length}', 'Total', col.textPrimary),
                  _BStat('$pending', 'Pending', const Color(0xFFF59E0B)),
                  _BStat('$confirmed', 'Confirmed', const Color(0xFF22C55E)),
                  _BStat('$completed', 'Completed', const Color(0xFF3B82F6)),
                  _BStat('$cancelled', 'Cancelled', AppColors.error),
                ],
              ),
            ),

            // ─ Filter chips ───────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: List.generate(_statuses.length, (i) {
                  final s = _statuses[i];
                  final active = _filter == s;
                  final color = _statusColor(s);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_filterLabels[i]),
                      selected: active,
                      onSelected: (_) =>
                          setState(() => _filter = s),
                      selectedColor: color.withValues(alpha: 0.18),
                      checkmarkColor: color,
                      labelStyle: TextStyle(
                        color:
                            active ? color : col.textSecondary,
                        fontWeight: active
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                      backgroundColor: col.surface,
                      side: BorderSide(
                        color: active
                            ? color.withValues(alpha: 0.5)
                            : col.border,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }),
              ),
            ),

            // ─ List ─────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No bookings${_filter != null ? ' with status “${_filter!.label}”' : ''}.',
                        style: TextStyle(
                            color: col.textMuted, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _AdminBookingCard(booking: filtered[i]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Color _statusColor(BookingStatus? s) => switch (s) {
        BookingStatus.confirmed => const Color(0xFF22C55E),
        BookingStatus.cancelled => AppColors.error,
        BookingStatus.completed => const Color(0xFF3B82F6),
        BookingStatus.pending => const Color(0xFFF59E0B),
        null => AppColors.primary,
      };
}

// ── Admin booking card ────────────────────────────────────────────────────────────

class _AdminBookingCard extends ConsumerWidget {
  final VentureBooking booking;
  const _AdminBookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final statusColor = _statusColor(booking.status);
    final dateStr = _fmtDate(booking.createdAt);

    return InkWell(
      onTap: () => _showStatusSheet(context, ref),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: col.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Status strip
            Container(height: 3, color: statusColor),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.ventureTitle,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: col.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking.userName.isNotEmpty
                                  ? booking.userName
                                  : booking.userEmail,
                              style: TextStyle(
                                  fontSize: 11, color: col.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  statusColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          booking.status.label,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, color: col.border),
                  const SizedBox(height: 8),
                  // Package + persons + total + date
                  Row(
                    children: [
                      if (booking.selectedPackageName != null) ...[
                        Icon(Iconsax.receipt_1,
                            size: 11, color: col.textMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            booking.selectedPackageName!,
                            style: TextStyle(
                                fontSize: 11,
                                color: col.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(Iconsax.people,
                          size: 11, color: col.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        '${booking.personCount} pax',
                        style: TextStyle(
                            fontSize: 11, color: col.textSecondary),
                      ),
                      const Spacer(),
                      Text(
                        '₹${_fmt(booking.grandTotal)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 11, color: col.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        dateStr,
                        style: TextStyle(
                            fontSize: 11, color: col.textMuted),
                      ),
                      const Spacer(),
                      Text(
                        'Tap to update status →',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  // Admin note
                  if (booking.adminNote != null &&
                      booking.adminNote!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                            color:
                                statusColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Iconsax.message_2,
                              size: 11, color: statusColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              booking.adminNote!,
                              style: TextStyle(
                                fontSize: 11,
                                color: col.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StatusUpdateSheet(
        booking: booking,
        onSave: (status, note) async {
          await ref
              .read(bookingServiceProvider)
              .updateStatus(booking.id, status, adminNote: note);
        },
      ),
    );
  }

  Color _statusColor(BookingStatus s) => switch (s) {
        BookingStatus.confirmed => const Color(0xFF22C55E),
        BookingStatus.cancelled => AppColors.error,
        BookingStatus.completed => const Color(0xFF3B82F6),
        BookingStatus.pending => const Color(0xFFF59E0B),
      };

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} ${_months[dt.month - 1]} ${dt.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

// ── Status update sheet ────────────────────────────────────────────────────────────

class _StatusUpdateSheet extends StatefulWidget {
  final VentureBooking booking;
  final Future<void> Function(BookingStatus, String?) onSave;
  const _StatusUpdateSheet({
    required this.booking,
    required this.onSave,
  });

  @override
  State<_StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends State<_StatusUpdateSheet> {
  late BookingStatus _selected;
  late final TextEditingController _noteCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.booking.status;
    _noteCtrl =
        TextEditingController(text: widget.booking.adminNote ?? '');
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final b = widget.booking;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: col.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Update Booking',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: col.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            b.ventureTitle,
            style: TextStyle(fontSize: 12, color: col.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),
          Text(
            '₹${b.grandTotal.toStringAsFixed(0)} · ${b.personCount} person${b.personCount > 1 ? 's' : ''} · ${b.userName}',
            style: TextStyle(fontSize: 12, color: col.textSecondary),
          ),

          const SizedBox(height: 16),
          Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: col.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Status selector
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BookingStatus.values.map((s) {
              final color = _statusColor(s);
              final active = _selected == s;
              return GestureDetector(
                onTap: () => setState(() => _selected = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active
                        ? color.withValues(alpha: 0.15)
                        : col.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? color.withValues(alpha: 0.6)
                          : col.border,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active)
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: color),
                      if (active) const SizedBox(width: 5),
                      Text(
                        s.label,
                        style: TextStyle(
                          color: active ? color : col.textSecondary,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          Text(
            'Note to user (optional)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: col.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            style: TextStyle(fontSize: 13, color: col.textPrimary),
            decoration: InputDecoration(
              hintText:
                  'e.g. “Payment received, booking confirmed for 15 Apr”',
              hintStyle:
                  TextStyle(fontSize: 12, color: col.textMuted),
              filled: true,
              fillColor: col.bg,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: col.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: col.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final note = _noteCtrl.text.trim();
      await widget.onSave(_selected, note.isEmpty ? null : note);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _statusColor(BookingStatus s) => switch (s) {
        BookingStatus.confirmed => const Color(0xFF22C55E),
        BookingStatus.cancelled => AppColors.error,
        BookingStatus.completed => const Color(0xFF3B82F6),
        BookingStatus.pending => const Color(0xFFF59E0B),
      };
}

// ── Booking summary stat ────────────────────────────────────────────────────────────

class _BStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _BStat(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: context.col.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}
