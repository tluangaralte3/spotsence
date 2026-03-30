// lib/screens/admin/analytics/admin_analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
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
      body: Column(
        children: [
          Material(
            color: col.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Analytics',
                    style: TextStyle(
                      color: col.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ref.invalidate(analyticsSnapshotProvider);
                      ref.invalidate(collectionCountsProvider);
                    },
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: col.border),
          Expanded(
            child: RefreshIndicator(
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
                  const _SectionHeader('Content Breakdown', icon: Iconsax.box),
                  const SizedBox(height: 12),
                  counts.when(
                    loading: () => const _LoadingCard(),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                    data: (c) => _InteractiveBarChart(counts: c),
                  ),
                  const SizedBox(height: 16),
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
// Live stats
// ─────────────────────────────────────────────────────────────────────────────

class _LiveStatsSection extends StatelessWidget {
  final AppAnalyticsSnapshot snap;
  const _LiveStatsSection({required this.snap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('Live Overview', icon: Iconsax.activity),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
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
              label: 'Last Updated',
              value: null,
              icon: Icons.schedule,
              color: AppColors.info,
              subtitle: snap.updatedAt != null ? _fmt(snap.updatedAt!) : '—',
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}

class _LiveStatCard extends StatelessWidget {
  final String label;
  final int? value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  const _LiveStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
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
          Icon(icon, color: color, size: 20),
          const Spacer(),
          if (value != null)
            Text(
              value.toString(),
              style: TextStyle(
                color: col.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            Text(
              subtitle ?? '—',
              style: TextStyle(
                color: col.textSecondary,
                fontSize: 11,
              ),
            ),
          Text(
            label,
            style: TextStyle(color: col.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interactive animated bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _InteractiveBarChart extends StatefulWidget {
  final Map<String, int> counts;
  const _InteractiveBarChart({required this.counts});

  @override
  State<_InteractiveBarChart> createState() => _InteractiveBarChartState();
}

class _InteractiveBarChartState extends State<_InteractiveBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int? _selectedIdx;

  static const _entries = [
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
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int get _maxCount =>
      _entries.fold(1, (prev, e) => (widget.counts[e.$1] ?? 0) > prev ? (widget.counts[e.$1] ?? 0) : prev);

  int get _totalCount =>
      _entries.fold(0, (sum, e) => sum + (widget.counts[e.$1] ?? 0));

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final total = _totalCount;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: col.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: col.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total badge
              Row(
                children: [
                  Text(
                    'Total items:',
                    style: TextStyle(color: col.textMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      total.toString(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (_selectedIdx != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _selectedIdx = null),
                      child: Text(
                        'Clear',
                        style: TextStyle(
                          color: col.textMuted,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              ...List.generate(_entries.length, (i) => _buildRow(context, i, total)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, int i, int total) {
    final col = context.col;
    final (key, label, color) = _entries[i];
    final count = widget.counts[key] ?? 0;
    final maxCount = _maxCount;
    final ratio = maxCount == 0 ? 0.0 : (count / maxCount) * _anim.value;
    final isSelected = _selectedIdx == i;
    final isDimmed = _selectedIdx != null && !isSelected;
    final pct = total == 0 ? 0.0 : count / total * 100;

    return GestureDetector(
      onTap: () => setState(() => _selectedIdx = isSelected ? null : i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Dot + label
            AnimatedOpacity(
              opacity: isDimmed ? 0.35 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 78,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? col.textPrimary : col.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bar
            Expanded(
              child: AnimatedOpacity(
                opacity: isDimmed ? 0.3 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: isSelected ? 12 : 8,
                    backgroundColor: col.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Count + pct when selected
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? SizedBox(
                      width: 72,
                      key: ValueKey('sel_$i'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            count.toString(),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: col.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      width: 36,
                      key: ValueKey('norm_$i'),
                      child: Text(
                        count.toString(),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: isDimmed ? col.textMuted : col.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _SectionHeader(this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    if (icon == null) {
      return Text(
        text,
        style: TextStyle(
          color: col.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: col.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
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
