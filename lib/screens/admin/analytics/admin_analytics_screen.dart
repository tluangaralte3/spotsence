// lib/screens/admin/analytics/admin_analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/admin_model.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final snapshot = ref.watch(analyticsSnapshotProvider);
    final counts = ref.watch(collectionCountsProvider);

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.surface,
        title: Text(
          'Analytics',
          style: TextStyle(color: col.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(analyticsSnapshotProvider);
              ref.invalidate(collectionCountsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(analyticsSnapshotProvider);
          ref.invalidate(collectionCountsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            snapshot.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (snap) => _LiveStatsSection(snap: snap),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('📦 Content Breakdown'),
            const SizedBox(height: 12),
            counts.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (c) => _ContentBarChart(counts: c),
            ),
            const SizedBox(height: 24),
            const _SectionHeader('ℹ️ Analytics Note'),
            const SizedBox(height: 8),
            const _NoteCard(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Stats
// ─────────────────────────────────────────────────────────────────────────────

class _LiveStatsSection extends StatelessWidget {
  final AppAnalyticsSnapshot snap;
  const _LiveStatsSection({required this.snap});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader('🔴 Live Overview'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _LiveStatCard(
              label: 'Total Users',
              value: snap.totalUsers,
              icon: Icons.people,
              color: AppColors.secondary,
            ),
            _LiveStatCard(
              label: 'New Today',
              value: snap.newUsersToday,
              icon: Icons.person_add,
              color: AppColors.success,
            ),
            _LiveStatCard(
              label: 'Total Reviews',
              value: snap.totalReviews,
              icon: Icons.star,
              color: AppColors.accent,
            ),
            _LiveStatCard(
              label: 'Total Bookings',
              value: snap.totalBookingRequests,
              icon: Icons.book_online,
              color: AppColors.primary,
            ),
            _LiveStatCard(
              label: 'Pending Bookings',
              value: snap.pendingBookingRequests,
              icon: Icons.pending_actions,
              color: AppColors.warning,
            ),
            _LiveStatCard(
              label: 'Points Awarded',
              value: snap.totalPointsAwarded,
              icon: Icons.emoji_events,
              color: AppColors.gold,
            ),
          ],
        ),
        if (snap.updatedAt != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Last updated: ${_fmt(snap.updatedAt!)}',
              style: TextStyle(color: col.textMuted, fontSize: 11),
            ),
          ),
        ],
      ],
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}

class _LiveStatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _LiveStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value.toString(),
            style: TextStyle(
              color: col.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(label, style: TextStyle(color: col.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple horizontal bar chart for collection counts
// ─────────────────────────────────────────────────────────────────────────────

class _ContentBarChart extends StatelessWidget {
  final Map<String, int> counts;
  const _ContentBarChart({required this.counts});

  static const _order = [
    ('spots', 'Spots', AppColors.primary),
    ('restaurants', 'Restaurants', Color(0xFFFF6B6B)),
    ('hotels', 'Hotels', Color(0xFF4ECDC4)),
    ('cafes', 'Cafes', Color(0xFFFFE66D)),
    ('homestays', 'Homestays', Color(0xFFA8E6CF)),
    ('adventureSpots', 'Adventure', Color(0xFFFF8B94)),
    ('shoppingAreas', 'Shopping', Color(0xFFB8B8FF)),
    ('events', 'Events', AppColors.accent),
    ('tour_packages', 'Ventures', AppColors.secondary),
    ('users', 'Users', AppColors.info),
  ];

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final maxCount = counts.values.fold(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Column(
        children: _order.map((meta) {
          final (key, label, color) = meta;
          final count = counts[key] ?? 0;
          final ratio = maxCount == 0 ? 0.0 : count / maxCount;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    label,
                    style: TextStyle(color: col.textSecondary, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: col.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    count.toString(),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: col.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: context.col.textPrimary,
      fontSize: 17,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(message, style: const TextStyle(color: AppColors.error)),
  );
}

class _NoteCard extends StatelessWidget {
  const _NoteCard();
  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'The Live Overview section reads from the '
              '`app_analytics/daily_snapshot` Firestore document. '
              'Populate this document from a Cloud Function or '
              'scheduled job. The Content Breakdown uses live '
              'Firestore count aggregation queries.',
              style: TextStyle(
                color: col.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
