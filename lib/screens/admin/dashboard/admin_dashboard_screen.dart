// lib/screens/admin/dashboard/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/admin_controller.dart';
import '../../../models/admin_model.dart';
import '../admin_shell.dart';

// icon + accent colour per ListingTab
const _tabMeta = <ListingTab, ({IconData icon, Color color})>{
  ListingTab.spots: (icon: Icons.place_outlined, color: AppColors.primary),
  ListingTab.restaurants: (
    icon: Icons.restaurant_outlined,
    color: Color(0xFFFF6B6B),
  ),
  ListingTab.accommodations: (
    icon: Icons.hotel_outlined,
    color: Color(0xFF4ECDC4),
  ),
  ListingTab.cafes: (icon: Icons.coffee_outlined, color: Color(0xFFFFBE0B)),
  ListingTab.adventure: (icon: Icons.terrain, color: Color(0xFFFF8B94)),
  ListingTab.shopping: (
    icon: Icons.shopping_bag_outlined,
    color: Color(0xFFB8B8FF),
  ),
  ListingTab.events: (icon: Icons.event_outlined, color: AppColors.accent),
  ListingTab.ventures: (
    icon: Icons.explore_outlined,
    color: AppColors.secondary,
  ),
};

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    ref.invalidate(collectionCountsProvider);
    await ref
        .read(collectionCountsProvider.future)
        .catchError((_) => <String, int>{});
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final countsAsync = ref.watch(collectionCountsProvider);
    final profile = ref.watch(adminProfileProvider).asData?.value;

    return Scaffold(
      backgroundColor: col.bg,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: col.surface,
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          children: [
            // ── Header banner ───────────────────────────────────────────
            _DashboardHeader(profile: profile),
            const SizedBox(height: 24),

            // ── Collection Stats ─────────────────────────────────────────
            _SectionLabel('Collection Stats'),
            const SizedBox(height: 12),
            countsAsync.when(
              loading: () => const _StatsShimmer(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (counts) => _StatsGrid(counts: counts),
            ),
            const SizedBox(height: 28),

            // ── Listing Categories ────────────────────────────────────────
            _SectionLabel('Listing Categories'),
            const SizedBox(height: 4),
            Text(
              'Tap a category to jump directly to it',
              style: TextStyle(color: col.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            _ListingCategoriesSection(ref: ref),
            const SizedBox(height: 28),

            // ── Admin Info ───────────────────────────────────────────────
            _SectionLabel('Admin Info'),
            const SizedBox(height: 12),
            _AdminInfoCard(profile: profile),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Grid
// ─────────────────────────────────────────────────────────────────────────────

class _StatMeta {
  final String key, label;
  final IconData icon;
  final Color color;
  const _StatMeta(this.key, this.label, this.icon, this.color);
}

class _StatsGrid extends StatelessWidget {
  final Map<String, int> counts;
  const _StatsGrid({required this.counts});

  static const _meta = [
    _StatMeta('users', 'Users', Icons.people_outline, AppColors.secondary),
    _StatMeta('spots', 'Spots', Icons.place_outlined, AppColors.primary),
    _StatMeta(
      'restaurants',
      'Restaurants',
      Icons.restaurant_outlined,
      Color(0xFFFF6B6B),
    ),
    _StatMeta(
      'accommodations',
      'Accommodations',
      Icons.hotel_outlined,
      Color(0xFF4ECDC4),
    ),
    _StatMeta('cafes', 'Cafes', Icons.coffee_outlined, Color(0xFFFFE66D)),
    _StatMeta('adventureSpots', 'Adventure', Icons.terrain, Color(0xFFFF8B94)),
    _StatMeta(
      'shoppingAreas',
      'Shopping',
      Icons.shopping_bag_outlined,
      Color(0xFFB8B8FF),
    ),
    _StatMeta('events', 'Events', Icons.event_outlined, AppColors.accent),
    _StatMeta(
      'tour_packages',
      'Ventures',
      Icons.explore_outlined,
      AppColors.primary,
    ),
    _StatMeta(
      'equipment_rentals',
      'Rentals',
      Icons.handyman_outlined,
      Color(0xFF06B6D4),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Column(
      children: [
        for (int i = 0; i < _meta.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: _StatTile(
                    meta: _meta[i],
                    value: counts[_meta[i].key] ?? 0,
                    col: col,
                  ),
                ),
                const SizedBox(width: 10),
                if (i + 1 < _meta.length)
                  Expanded(
                    child: _StatTile(
                      meta: _meta[i + 1],
                      value: counts[_meta[i + 1].key] ?? 0,
                      col: col,
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final _StatMeta meta;
  final int value;
  final AppColorScheme col;
  const _StatTile({required this.meta, required this.value, required this.col});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(meta.icon, color: meta.color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meta.label,
                style: TextStyle(
                  color: col.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Column(
      children: List.generate(
        5,
        (r) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: List.generate(
              2,
              (c) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: c == 0 ? 5 : 0,
                    left: c == 1 ? 5 : 0,
                  ),
                  height: 66,
                  decoration: BoxDecoration(
                    color: col.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: col.border),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard header banner
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final AdminModel? profile;
  const _DashboardHeader({this.profile});

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final name = profile?.displayName.split(' ').first ?? 'Admin';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    profile?.role.label ?? 'Super Admin',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('👑', style: TextStyle(fontSize: 28)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Listing Categories section
// ─────────────────────────────────────────────────────────────────────────────

class _ListingCategoriesSection extends ConsumerWidget {
  final WidgetRef ref;
  const _ListingCategoriesSection({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ListingTab.values.length + 1, // +1 for Rentals tile
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, i) {
        // Extra tile at the end for Equipment Rentals
        if (i == ListingTab.values.length) {
          return _ListingCategoryTile(
            label: 'Rentals',
            icon: Icons.handyman_outlined,
            color: const Color(0xFF06B6D4),
            col: col,
            onTap: () => ref.read(adminTabIndexProvider.notifier).set(8),
          );
        }
        final tab = ListingTab.values[i];
        final meta = _tabMeta[tab]!;
        return _ListingCategoryTile(
          label: tab.label,
          icon: meta.icon,
          color: meta.color,
          col: col,
          onTap: () {
            // Switch to   tab (index 1) and pre-select the tab
            ref.read(selectedListingTabProvider.notifier).set(tab);
            ref.read(adminTabIndexProvider.notifier).set(1);
          },
        );
      },
    );
  }
}

class _ListingCategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final AppColorScheme col;
  final VoidCallback onTap;

  const _ListingCategoryTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.col,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: col.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: col.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
// Quick Actions (removed — replaced by Listing Categories)
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Admin Info Card
// ─────────────────────────────────────────────────────────────────────────────

class _AdminInfoCard extends StatelessWidget {
  final AdminModel? profile;
  const _AdminInfoCard({this.profile});

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.border),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: profile?.email ?? '—',
            col: col,
          ),
          Divider(color: col.border, height: 1),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: profile?.role.label ?? '—',
            col: col,
          ),
          Divider(color: col.border, height: 1),
          _InfoRow(
            icon: Icons.access_time_outlined,
            label: 'Last Login',
            value: profile?.lastLogin != null ? _fmt(profile!.lastLogin!) : '—',
            col: col,
          ),
          Divider(color: col.border, height: 1),
          _InfoRow(
            icon: Icons.circle_outlined,
            label: 'Status',
            value: (profile?.isActive ?? false) ? 'Active' : 'Inactive',
            col: col,
            valueColor: (profile?.isActive ?? false)
                ? AppColors.primary
                : AppColors.error,
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year}  '
      '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final AppColorScheme col;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.col,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: col.textMuted, size: 16),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: col.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? col.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.col.textPrimary,
        fontSize: 16,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }
}
