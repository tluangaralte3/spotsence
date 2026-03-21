// lib/screens/admin/dashboard/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/admin_model.dart';
import '../admin_shell.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final countsAsync = ref.watch(collectionCountsProvider);
    final profile = ref.watch(adminProfileProvider).asData?.value;

    return Scaffold(
      backgroundColor: col.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(collectionCountsProvider),
        child: CustomScrollView(
          slivers: [
            _DashboardAppBar(profile: profile),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionHeader('📊 Collection Stats'),
                  const SizedBox(height: 12),
                  countsAsync.when(
                    loading: () => const _StatsGridShimmer(),
                    error: (e, _) => _ErrorCard(message: e.toString()),
                    data: (counts) => _StatsGrid(counts: counts),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader('⚡ Quick Actions'),
                  const SizedBox(height: 12),
                  _QuickActionsGrid(ref: ref),
                  const SizedBox(height: 24),
                  _SectionHeader('🔔 Admin Info'),
                  const SizedBox(height: 12),
                  _AdminInfoCard(profile: profile),
                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget {
  final AdminModel? profile;
  const _DashboardAppBar({this.profile});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: col.surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A1628), Color(0xFF121827)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '👑 SUPER ADMIN',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back,',
                    style: TextStyle(color: col.textSecondary, fontSize: 14),
                  ),
                  Text(
                    profile?.displayName ?? 'Admin',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Grid
// ─────────────────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final Map<String, int> counts;
  const _StatsGrid({required this.counts});

  static const _statMeta = [
    ('users', 'Users', Icons.people, AppColors.secondary),
    ('spots', 'Spots', Icons.place, AppColors.primary),
    ('restaurants', 'Restaurants', Icons.restaurant, Color(0xFFFF6B6B)),
    ('hotels', 'Hotels', Icons.hotel, Color(0xFF4ECDC4)),
    ('cafes', 'Cafes', Icons.coffee, Color(0xFFFFE66D)),
    ('homestays', 'Homestays', Icons.home, Color(0xFFA8E6CF)),
    ('adventureSpots', 'Adventure', Icons.terrain, Color(0xFFFF8B94)),
    ('shoppingAreas', 'Shopping', Icons.shopping_bag, Color(0xFFB8B8FF)),
    ('events', 'Events', Icons.event, AppColors.accent),
    ('tour_packages', 'Ventures', Icons.explore, AppColors.primary),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: _statMeta.map((m) {
        final (key, label, icon, color) = m;
        return _StatCard(
          label: label,
          value: counts[key] ?? 0,
          icon: icon,
          color: color,
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  const _StatCard({
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: col.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGridShimmer extends StatelessWidget {
  const _StatsGridShimmer();

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: List.generate(
        10,
        (_) => Container(
          decoration: BoxDecoration(
            color: col.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: col.border),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  final WidgetRef ref;
  const _QuickActionsGrid({required this.ref});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final actions = [
      (icon: Icons.place_outlined, label: 'Add Spot', tab: 0),
      (icon: Icons.restaurant, label: 'Add Restaurant', tab: 0),
      (icon: Icons.hotel, label: 'Add Hotel', tab: 0),
      (icon: Icons.explore_outlined, label: 'Add Venture', tab: 0),
      (icon: Icons.event_outlined, label: 'Add Event', tab: 0),
      (icon: Icons.people_outline, label: 'View Users', tab: 2),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: actions.map((a) {
        return InkWell(
          onTap: () => ref.read(adminTabIndexProvider.notifier).set(a.tab),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: col.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: col.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a.icon, color: AppColors.primary, size: 24),
                const SizedBox(height: 6),
                Text(
                  a.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: col.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin info card
// ─────────────────────────────────────────────────────────────────────────────

class _AdminInfoCard extends StatelessWidget {
  final AdminModel? profile;
  const _AdminInfoCard({this.profile});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('Email', profile?.email ?? '—', Icons.email_outlined),
          const SizedBox(height: 8),
          _InfoRow('Role', profile?.role.label ?? '—', Icons.badge_outlined),
          const SizedBox(height: 8),
          _InfoRow(
            'Last Login',
            profile?.lastLogin != null ? _formatDate(profile!.lastLogin!) : '—',
            Icons.access_time,
          ),
          const SizedBox(height: 8),
          _InfoRow(
            'Status',
            (profile?.isActive ?? false) ? '✅ Active' : '⛔ Inactive',
            Icons.circle_outlined,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.warning,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Custom Claim (superAdmin) must be set via Firebase '
                    'Admin SDK. The client cannot set claims.',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _InfoRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Row(
      children: [
        Icon(icon, color: col.textMuted, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(color: col.textSecondary, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: col.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.col.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }
}
