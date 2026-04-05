// lib/screens/admin/dares/admin_dare_screen.dart
//
// Admin Dare Monitoring — full lifecycle control, member tables,
// creator activity, analytics charts, milestone details.

import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../controllers/admin_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/dare_models.dart';
import '../../../services/admin_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AdminDareMonitoringScreen
// ─────────────────────────────────────────────────────────────────────────────

class AdminDareMonitoringScreen extends ConsumerStatefulWidget {
  const AdminDareMonitoringScreen({super.key});

  @override
  ConsumerState<AdminDareMonitoringScreen> createState() =>
      _AdminDareMonitoringScreenState();
}

class _AdminDareMonitoringScreenState
    extends ConsumerState<AdminDareMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.bg,
        foregroundColor: col.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.flash,
                color: Colors.black,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Dare Monitoring'),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: col.textMuted,
          indicatorColor: AppColors.primary,
          dividerColor: col.border,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(icon: Icon(Iconsax.chart_square, size: 16), text: 'Overview'),
            Tab(icon: Icon(Iconsax.flash, size: 16), text: 'Dares'),
            Tab(icon: Icon(Iconsax.people, size: 16), text: 'Creators'),
            Tab(icon: Icon(Iconsax.trend_up, size: 16), text: 'Analytics'),
          ],
        ),
      ),
      body: ref.watch(adminAllDaresProvider).when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (dares) => TabBarView(
          controller: _tab,
          children: [
            _OverviewTab(dares: dares),
            _DaresTab(dares: dares),
            _CreatorsTab(dares: dares),
            _AnalyticsTab(dares: dares),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Overview
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final List<DareModel> dares;
  const _OverviewTab({required this.dares});

  @override
  Widget build(BuildContext context) {
    final total = dares.length;
    final restricted = dares.where((d) => d.adminRestricted).length;
    final active = total - restricted;
    final totalMembers = dares
        .expand((d) => d.approvedMembers)
        .length;
    final totalChallenges = dares.fold(0, (s, d) => s + d.challenges.length);
    final totalCompletions = dares
        .expand((d) => d.approvedMembers)
        .fold(0, (s, m) => s + m.completedChallenges);
    final publicCount = dares
        .where((d) => d.visibility == DareVisibility.public)
        .length;
    final privateCount = total - publicCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // ── Summary stat grid
        _buildStatGrid(context, [
          _StatData('Total Dares', '$total', Iconsax.flash, AppColors.primary),
          _StatData('Active', '$active', Iconsax.tick_circle, AppColors.success),
          _StatData('Restricted', '$restricted', Iconsax.shield_slash, AppColors.error),
          _StatData('Members', '$totalMembers', Iconsax.people, AppColors.secondary),
          _StatData('Challenges', '$totalChallenges', Iconsax.element_3, AppColors.warning),
          _StatData('Completions', '$totalCompletions', Iconsax.medal, const Color(0xFF9B5DE5)),
        ]),
        const SizedBox(height: 28),

        // ── Category bar chart
        _AdminSectionHeader(
          icon: Iconsax.category,
          title: 'Dares by Category',
          subtitle: 'How many dares fall into each category',
        ),
        const SizedBox(height: 12),
        _CategoryBarChart(dares: dares),
        const SizedBox(height: 28),

        // ── Visibility pie
        _AdminSectionHeader(
          icon: Iconsax.eye,
          title: 'Visibility Split',
          subtitle: 'Public vs Private dare distribution',
        ),
        const SizedBox(height: 12),
        _VisibilityPieCard(publicCount: publicCount, privateCount: privateCount),
        const SizedBox(height: 28),

        // ── Most recent 5 dares
        _AdminSectionHeader(
          icon: Iconsax.clock,
          title: 'Recently Created',
          subtitle: 'Last 5 dares added to the platform',
        ),
        const SizedBox(height: 12),
        ...dares.take(5).map((d) => _DareSummaryTile(dare: d)),
      ],
    );
  }

  Widget _buildStatGrid(BuildContext context, List<_StatData> stats) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (_, i) {
        final s = stats[i];
        return Container(
          decoration: BoxDecoration(
            color: context.col.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: s.color.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(s.icon, color: s.color, size: 20),
              const SizedBox(height: 5),
              Text(
                s.value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: s.color,
                ),
              ),
              Text(
                s.label,
                style: TextStyle(fontSize: 9, color: context.col.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ).animate(delay: Duration(milliseconds: i * 55)).fadeIn().scale(begin: const Offset(0.9, 0.9));
      },
    );
  }
}

class _StatData {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatData(this.label, this.value, this.icon, this.color);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Dares Table
// ─────────────────────────────────────────────────────────────────────────────

enum _DareFilter { all, active, restricted, public, private }

class _DaresTab extends ConsumerStatefulWidget {
  final List<DareModel> dares;
  const _DaresTab({required this.dares});

  @override
  ConsumerState<_DaresTab> createState() => _DaresTabState();
}

class _DaresTabState extends ConsumerState<_DaresTab> {
  String _search = '';
  _DareFilter _filter = _DareFilter.all;
  final Set<String> _actioning = {};

  List<DareModel> get _filtered {
    var list = widget.dares;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list
          .where((d) =>
              d.title.toLowerCase().contains(q) ||
              d.creatorName.toLowerCase().contains(q) ||
              d.category.label.toLowerCase().contains(q))
          .toList();
    }
    return list.where((d) {
      switch (_filter) {
        case _DareFilter.all:
          return true;
        case _DareFilter.active:
          return !d.adminRestricted;
        case _DareFilter.restricted:
          return d.adminRestricted;
        case _DareFilter.public:
          return d.visibility == DareVisibility.public;
        case _DareFilter.private:
          return d.visibility == DareVisibility.private;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              // Search
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by title, creator, category…',
                  hintStyle: TextStyle(color: context.col.textMuted),
                  prefixIcon: Icon(Iconsax.search_normal, color: context.col.textMuted, size: 18),
                  filled: true,
                  fillColor: context.col.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.col.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.col.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
                style: TextStyle(color: context.col.textPrimary),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 10),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _DareFilter.values.map((f) {
                    final labels = {
                      _DareFilter.all: 'All (${widget.dares.length})',
                      _DareFilter.active: 'Active',
                      _DareFilter.restricted: 'Restricted',
                      _DareFilter.public: 'Public',
                      _DareFilter.private: 'Private',
                    };
                    final selected = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(labels[f]!),
                        selected: selected,
                        onSelected: (_) => setState(() => _filter = f),
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? AppColors.primary : context.col.textSecondary,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: selected
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : context.col.border,
                        ),
                        backgroundColor: context.col.surfaceElevated,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '${filtered.length} dare${filtered.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: context.col.textMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No dares match your search',
                    style: TextStyle(color: context.col.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _DareAdminCard(
                    dare: filtered[i],
                    isActioning: _actioning.contains(filtered[i].id),
                    onRestrict: (dare) => _restrictDare(dare),
                    onDelete: (dare) => _confirmDelete(dare),
                    onViewDetail: (dare) => _showDareDetail(dare),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _restrictDare(DareModel dare) async {
    final toggled = !dare.adminRestricted;
    // If restricting, ask for reason
    String? reason;
    if (toggled) {
      reason = await _showReasonDialog(dare.title);
      if (reason == null) return; // cancelled
    }
    setState(() => _actioning.add(dare.id));
    try {
      await ref.read(adminServiceProvider).restrictDare(
            dare.id,
            restrict: toggled,
            reason: reason,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(toggled
                ? '${dare.title} has been restricted'
                : '${dare.title} restriction lifted'),
            backgroundColor:
                toggled ? AppColors.warning : AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _actioning.remove(dare.id));
    }
  }

  Future<void> _confirmDelete(DareModel dare) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.col.surfaceElevated,
        title: Text('Delete Dare', style: TextStyle(color: ctx.col.textPrimary)),
        content: Text(
          'Permanently delete "${dare.title}" by ${dare.creatorName}?\n\n'
          'This will also delete all proofs and member records. '
          'This action CANNOT be undone.',
          style: TextStyle(color: ctx.col.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel', style: TextStyle(color: ctx.col.textPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actioning.add(dare.id));
    try {
      await ref.read(adminServiceProvider).deleteDareAsAdmin(dare.id, title: dare.title);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dare deleted successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _actioning.remove(dare.id));
    }
  }

  Future<String?> _showReasonDialog(String dareTitle) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.col.surfaceElevated,
        title: Text('Restrict Dare', style: TextStyle(color: ctx.col.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason for restricting "$dareTitle":',
              style: TextStyle(color: ctx.col.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLength: 200,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Violates community guidelines',
                hintStyle: TextStyle(color: ctx.col.textMuted),
                filled: true,
                fillColor: ctx.col.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: ctx.col.border),
                ),
              ),
              style: TextStyle(color: ctx.col.textPrimary),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: ctx.col.textPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
                  onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isNotEmpty
                      ? ctrl.text.trim()
                      : 'Restricted by admin'),
                  child: const Text('Restrict'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDareDetail(DareModel dare) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.col.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DareDetailSheet(dare: dare),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 3 — Creators
// ─────────────────────────────────────────────────────────────────────────────

class _CreatorsTab extends ConsumerStatefulWidget {
  final List<DareModel> dares;
  const _CreatorsTab({required this.dares});

  @override
  ConsumerState<_CreatorsTab> createState() => _CreatorsTabState();
}

class _CreatorsTabState extends ConsumerState<_CreatorsTab> {
  final Set<String> _actioning = {};

  /// Grouped: creatorId → { name, photo, dares, totalMembers, totalCompletions }
  List<_CreatorStat> get _creatorStats {
    final map = <String, _CreatorStat>{};
    for (final dare in widget.dares) {
      final existing = map[dare.creatorId];
      final memberCount = dare.approvedMembers.length;
      final completions = dare.approvedMembers
          .fold(0, (s, m) => s + m.completedChallenges);
      if (existing == null) {
        map[dare.creatorId] = _CreatorStat(
          userId: dare.creatorId,
          name: dare.creatorName,
          photoUrl: dare.creatorPhoto,
          dareCount: 1,
          totalMembers: memberCount,
          totalCompletions: completions,
          restrictedDares: dare.adminRestricted ? 1 : 0,
        );
      } else {
        map[dare.creatorId] = existing.copyWith(
          dareCount: existing.dareCount + 1,
          totalMembers: existing.totalMembers + memberCount,
          totalCompletions: existing.totalCompletions + completions,
          restrictedDares: existing.restrictedDares + (dare.adminRestricted ? 1 : 0),
        );
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.dareCount.compareTo(a.dareCount));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _creatorStats;
    if (stats.isEmpty) {
      return const Center(
        child: Text('No dare creators yet'),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.col.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(
              bottom: BorderSide(color: context.col.border),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 44),
              Expanded(
                flex: 3,
                child: Text('Creator', style: _headerStyle(context)),
              ),
              Expanded(child: Text('Dares', style: _headerStyle(context), textAlign: TextAlign.center)),
              Expanded(child: Text('Members', style: _headerStyle(context), textAlign: TextAlign.center)),
              Expanded(child: Text('Done ✓', style: _headerStyle(context), textAlign: TextAlign.center)),
              SizedBox(width: 80, child: Text('Actions', style: _headerStyle(context), textAlign: TextAlign.center)),
            ],
          ),
        ),
        // Rows
        Container(
          decoration: BoxDecoration(
            color: context.col.surfaceElevated,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border.all(color: context.col.border),
          ),
          child: Column(
            children: stats.asMap().entries.map((entry) {
              final i = entry.key;
              final stat = entry.value;
              return _CreatorRow(
                stat: stat,
                index: i,
                isActioning: _actioning.contains(stat.userId),
                onSuspend: () => _suspendCreator(stat),
                onUnsuspend: () => _unsuspendCreator(stat),
                onViewDares: () => _showCreatorDares(stat),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  TextStyle _headerStyle(BuildContext context) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: context.col.textMuted,
      );

  Future<void> _suspendCreator(_CreatorStat stat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.col.surfaceElevated,
        title: Text('Suspend Creator', style: TextStyle(color: ctx.col.textPrimary)),
        content: Text(
          'Suspend ${stat.name}?\nThey will be unable to access the app.',
          style: TextStyle(color: ctx.col.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel', style: TextStyle(color: ctx.col.textPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Suspend'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actioning.add(stat.userId));
    try {
      await ref.read(adminServiceProvider).setDareCreatorStatus(stat.userId, isActive: false);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _actioning.remove(stat.userId));
    }
  }

  Future<void> _unsuspendCreator(_CreatorStat stat) async {
    setState(() => _actioning.add(stat.userId));
    try {
      await ref.read(adminServiceProvider).setDareCreatorStatus(stat.userId, isActive: true);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _actioning.remove(stat.userId));
    }
  }

  void _showCreatorDares(_CreatorStat stat) {
    final creatorDares = widget.dares.where((d) => d.creatorId == stat.userId).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.col.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, ctrl) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.col.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                '${stat.name}\'s Dares',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: context.col.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                itemCount: creatorDares.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _DareSummaryTile(dare: creatorDares[i], compact: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorStat {
  final String userId, name;
  final String? photoUrl;
  final int dareCount, totalMembers, totalCompletions, restrictedDares;

  const _CreatorStat({
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.dareCount,
    required this.totalMembers,
    required this.totalCompletions,
    required this.restrictedDares,
  });

  _CreatorStat copyWith({
    int? dareCount,
    int? totalMembers,
    int? totalCompletions,
    int? restrictedDares,
  }) => _CreatorStat(
    userId: userId,
    name: name,
    photoUrl: photoUrl,
    dareCount: dareCount ?? this.dareCount,
    totalMembers: totalMembers ?? this.totalMembers,
    totalCompletions: totalCompletions ?? this.totalCompletions,
    restrictedDares: restrictedDares ?? this.restrictedDares,
  );
}

class _CreatorRow extends StatelessWidget {
  final _CreatorStat stat;
  final int index;
  final bool isActioning;
  final VoidCallback onSuspend;
  final VoidCallback onUnsuspend;
  final VoidCallback onViewDares;

  const _CreatorRow({
    required this.stat,
    required this.index,
    required this.isActioning,
    required this.onSuspend,
    required this.onUnsuspend,
    required this.onViewDares,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: index == 0
              ? BorderSide.none
              : BorderSide(color: context.col.border.withValues(alpha: 0.4)),
        ),
        color: stat.restrictedDares > 0
            ? AppColors.error.withValues(alpha: 0.04)
            : null,
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: context.col.surface,
            backgroundImage: stat.photoUrl != null
                ? CachedNetworkImageProvider(stat.photoUrl!)
                : null,
            child: stat.photoUrl == null
                ? Text(
                    stat.name.isNotEmpty ? stat.name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 13, color: context.col.textSecondary),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          // Name
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onViewDares,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: context.col.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (stat.restrictedDares > 0)
                    Text(
                      '${stat.restrictedDares} restricted',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Dare count
          Expanded(
            child: Text(
              '${stat.dareCount}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Members
          Expanded(
            child: Text(
              '${stat.totalMembers}',
              style: TextStyle(
                color: context.col.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Completions
          Expanded(
            child: Text(
              '${stat.totalCompletions}',
              style: TextStyle(
                color: context.col.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Actions
          SizedBox(
            width: 80,
            child: isActioning
                ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SmallAction(
                        icon: Iconsax.eye,
                        color: AppColors.primary,
                        tooltip: 'View Dares',
                        onTap: onViewDares,
                      ),
                      const SizedBox(width: 6),
                      _SmallAction(
                        icon: Iconsax.user_remove,
                        color: AppColors.error,
                        tooltip: 'Suspend Creator',
                        onTap: onSuspend,
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
// Tab 4 — Analytics
// ─────────────────────────────────────────────────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  final List<DareModel> dares;
  const _AnalyticsTab({required this.dares});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        // ── Members per dare (top 8)
        _AdminSectionHeader(
          icon: Iconsax.people,
          title: 'Members per Dare',
          subtitle: 'Top 8 dares by member count',
        ),
        const SizedBox(height: 12),
        _MembersBarChart(dares: dares),
        const SizedBox(height: 28),

        // ── Challenge completion rate
        _AdminSectionHeader(
          icon: Iconsax.tick_circle,
          title: 'Challenge Completion Rate',
          subtitle: 'Completed / possible across each dare (top 8)',
        ),
        const SizedBox(height: 12),
        _CompletionRateChart(dares: dares),
        const SizedBox(height: 28),

        // ── Category distribution pie
        _AdminSectionHeader(
          icon: Iconsax.category,
          title: 'Category Distribution',
          subtitle: 'Share of dares in each category',
        ),
        const SizedBox(height: 12),
        _FullCategoryPie(dares: dares),
        const SizedBox(height: 28),

        // ── Milestone achievement table
        _AdminSectionHeader(
          icon: Iconsax.medal,
          title: 'Milestone Detail',
          subtitle: 'All milestones defined across all dares',
        ),
        const SizedBox(height: 12),
        _MilestoneTable(dares: dares),
        const SizedBox(height: 28),

        // ── Top creators leaderboard
        _AdminSectionHeader(
          icon: Iconsax.ranking,
          title: 'Top Creators',
          subtitle: 'Ranked by number of dares created',
        ),
        const SizedBox(height: 12),
        _TopCreatorsLeaderboard(dares: dares),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chart widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBarChart extends StatelessWidget {
  final List<DareModel> dares;
  const _CategoryBarChart({required this.dares});

  @override
  Widget build(BuildContext context) {
    final counts = <DareCategory, int>{};
    for (final d in dares) {
      counts[d.category] = (counts[d.category] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();

    if (top.isEmpty) {
      return _emptyChart(context, 'No dare data yet');
    }

    final groups = top.asMap().entries.map((e) {
      final cat = e.value.key;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.value.toDouble(),
            color: cat.color,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    final maxY = top.first.value.toDouble();

    return _ChartCard(
      child: BarChart(
        BarChartData(
          maxY: (maxY * 1.2).ceilToDouble(),
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: context.col.border.withValues(alpha: 0.3), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: TextStyle(fontSize: 10, color: context.col.textMuted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= top.length) return const SizedBox.shrink();
                  final cat = top[idx].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(cat.icon, size: 14, color: cat.color),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, _) {
                final cat = top[group.x].key;
                return BarTooltipItem(
                  '${cat.label}\n${rod.toY.toInt()} dare${rod.toY > 1 ? 's' : ''}',
                  const TextStyle(color: Colors.white, fontSize: 11),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _VisibilityPieCard extends StatelessWidget {
  final int publicCount;
  final int privateCount;
  const _VisibilityPieCard({required this.publicCount, required this.privateCount});

  @override
  Widget build(BuildContext context) {
    final total = publicCount + privateCount;
    if (total == 0) return _emptyChart(context, 'No data');
    return _ChartCard(
      height: 160,
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: PieChart(
              PieChartData(
                sections: [
                  if (publicCount > 0)
                    PieChartSectionData(
                      value: publicCount.toDouble(),
                      color: AppColors.primary,
                      title: '$publicCount',
                      radius: 50,
                      titleStyle: const TextStyle(
                          color: Colors.black, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  if (privateCount > 0)
                    PieChartSectionData(
                      value: privateCount.toDouble(),
                      color: AppColors.secondary,
                      title: '$privateCount',
                      radius: 50,
                      titleStyle: const TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                ],
                centerSpaceRadius: 34,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(
                  color: AppColors.primary,
                  label: 'Public',
                  count: publicCount,
                  pct: (publicCount / total * 100).round(),
                ),
                const SizedBox(height: 12),
                _LegendRow(
                  color: AppColors.secondary,
                  label: 'Private',
                  count: privateCount,
                  pct: (privateCount / total * 100).round(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersBarChart extends StatelessWidget {
  final List<DareModel> dares;
  const _MembersBarChart({required this.dares});

  @override
  Widget build(BuildContext context) {
    final sorted = [...dares]
      ..sort((a, b) => b.approvedMembers.length.compareTo(a.approvedMembers.length));
    final top = sorted.take(8).toList();
    if (top.isEmpty) return _emptyChart(context, 'No dares yet');

    final groups = top.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.approvedMembers.length.toDouble(),
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF00B88A)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList();

    final maxY = top.first.approvedMembers.length.toDouble();

    return Column(
      children: [
        _ChartCard(
          child: BarChart(
            BarChartData(
              maxY: max(1, maxY * 1.25).ceilToDouble(),
              barGroups: groups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: context.col.border.withValues(alpha: 0.3), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      '${v.toInt()}',
                      style: TextStyle(fontSize: 10, color: context.col.textMuted),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx >= top.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'D${idx + 1}',
                          style: TextStyle(fontSize: 10, color: context.col.textMuted),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, _, rod, _) {
                    final dare = top[group.x];
                    final short = dare.title.length > 12
                        ? '${dare.title.substring(0, 12)}…'
                        : dare.title;
                    return BarTooltipItem(
                      '$short\n${rod.toY.toInt()} members',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: top.asMap().entries.map((e) {
            final title = e.value.title;
            final short = title.length > 14 ? '${title.substring(0, 14)}…' : title;
            return Text(
              'D${e.key + 1}: $short',
              style: TextStyle(fontSize: 10, color: context.col.textMuted),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CompletionRateChart extends StatelessWidget {
  final List<DareModel> dares;
  const _CompletionRateChart({required this.dares});

  @override
  Widget build(BuildContext context) {
    final valid = dares.where((d) => d.challenges.isNotEmpty && d.approvedMembers.isNotEmpty).toList();
    if (valid.isEmpty) return _emptyChart(context, 'No completion data yet');

    final sorted = [...valid]..sort((a, b) {
        final rateA = a.approvedMembers.fold(0, (s, m) => s + m.completedChallenges) /
            max(1, a.challenges.length * a.approvedMembers.length);
        final rateB = b.approvedMembers.fold(0, (s, m) => s + m.completedChallenges) /
            max(1, b.challenges.length * b.approvedMembers.length);
        return rateB.compareTo(rateA);
      });
    final top = sorted.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        children: top.asMap().entries.map((e) {
          final dare = e.value;
          final possible = dare.challenges.length * dare.approvedMembers.length;
          final completed = dare.approvedMembers.fold(0, (s, m) => s + m.completedChallenges);
          final rate = possible > 0 ? completed / possible : 0.0;
          final pct = (rate * 100).round();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dare.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.col.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$completed/$possible ($pct%)',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.col.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rate.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: context.col.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct >= 70 ? AppColors.success : pct >= 40 ? AppColors.warning : AppColors.error,
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

class _FullCategoryPie extends StatefulWidget {
  final List<DareModel> dares;
  const _FullCategoryPie({required this.dares});

  @override
  State<_FullCategoryPie> createState() => _FullCategoryPieState();
}

class _FullCategoryPieState extends State<_FullCategoryPie> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final counts = <DareCategory, int>{};
    for (final d in widget.dares) {
      counts[d.category] = (counts[d.category] ?? 0) + 1;
    }
    final total = widget.dares.length;
    if (total == 0) return _emptyChart(context, 'No data');

    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final sections = entries.asMap().entries.map((e) {
      final isTouched = _touched == e.key;
      final cat = e.value.key;
      final count = e.value.value;
      return PieChartSectionData(
        value: count.toDouble(),
        color: cat.color,
        title: isTouched ? '${(count / total * 100).round()}%' : '',
        radius: isTouched ? 62 : 52,
        titleStyle: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      );
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 160,
            width: 160,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 36,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (!event.isInterestedForInteractions) {
                      setState(() => _touched = null);
                      return;
                    }
                    setState(() => _touched = response?.touchedSection?.touchedSectionIndex);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: entries.map((e) {
                final pct = (e.value / total * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: e.key.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.key.label,
                          style: TextStyle(fontSize: 11, color: context.col.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${e.value} ($pct%)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.col.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneTable extends StatelessWidget {
  final List<DareModel> dares;
  const _MilestoneTable({required this.dares});

  @override
  Widget build(BuildContext context) {
    // Flatten all milestones across all challenges across all dares
    final rows = <_MilestoneRow>[];
    for (final dare in dares) {
      for (final challenge in dare.challenges) {
        for (final ms in challenge.milestones) {
          rows.add(_MilestoneRow(
            dareTitle: dare.title,
            challengeTitle: challenge.title,
            milestoneTitle: ms.title,
            xpReward: ms.xpReward,
            medalType: ms.medalType,
            dareRestricted: dare.adminRestricted,
          ));
        }
      }
    }

    if (rows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.col.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.col.border),
        ),
        child: Center(
          child: Text(
            'No milestones defined yet',
            style: TextStyle(color: context.col.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.col.border)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('Dare', style: _thStyle(context))),
                Expanded(flex: 2, child: Text('Challenge', style: _thStyle(context))),
                Expanded(flex: 2, child: Text('Milestone', style: _thStyle(context))),
                const SizedBox(width: 44, child: Text('XP', textAlign: TextAlign.center)),
                const SizedBox(width: 60, child: Text('Medal', textAlign: TextAlign.center)),
              ],
            ),
          ),
          ...rows.asMap().entries.map((e) {
            final row = e.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: e.key == 0
                    ? null
                    : Border(
                        top: BorderSide(
                          color: context.col.border.withValues(alpha: 0.4),
                        ),
                      ),
                color: row.dareRestricted ? AppColors.error.withValues(alpha: 0.04) : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.dareTitle,
                      style: TextStyle(fontSize: 11, color: context.col.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.challengeTitle,
                      style: TextStyle(fontSize: 11, color: context.col.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.milestoneTitle,
                      style: TextStyle(fontSize: 11, color: context.col.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '+${row.xpReward}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: row.medalType.bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          row.medalType.label,
                          style: TextStyle(
                            fontSize: 9,
                            color: row.medalType.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  TextStyle _thStyle(BuildContext context) => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: context.col.textMuted,
      );
}

class _MilestoneRow {
  final String dareTitle, challengeTitle, milestoneTitle;
  final int xpReward;
  final MedalType medalType;
  final bool dareRestricted;

  const _MilestoneRow({
    required this.dareTitle,
    required this.challengeTitle,
    required this.milestoneTitle,
    required this.xpReward,
    required this.medalType,
    required this.dareRestricted,
  });
}

class _TopCreatorsLeaderboard extends StatelessWidget {
  final List<DareModel> dares;
  const _TopCreatorsLeaderboard({required this.dares});

  @override
  Widget build(BuildContext context) {
    final map = <String, int>{};
    final names = <String, String>{};
    for (final d in dares) {
      map[d.creatorId] = (map[d.creatorId] ?? 0) + 1;
      names[d.creatorId] = d.creatorName;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(10).toList();

    return Column(
      children: top.asMap().entries.map((e) {
        final rank = e.key + 1;
        final entry = e.value;
        final name = names[entry.key] ?? 'Unknown';
        final medals = ['🥇', '🥈', '🥉'];
        final medal = rank <= 3 ? medals[rank - 1] : '$rank.';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: context.col.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: rank == 1
                  ? AppColors.warning.withValues(alpha: 0.4)
                  : context.col.border,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  medal,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.col.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${entry.value} dare${entry.value == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dare Admin Card (for dare table tab)
// ─────────────────────────────────────────────────────────────────────────────

class _DareAdminCard extends StatelessWidget {
  final DareModel dare;
  final bool isActioning;
  final ValueChanged<DareModel> onRestrict;
  final ValueChanged<DareModel> onDelete;
  final ValueChanged<DareModel> onViewDetail;

  const _DareAdminCard({
    required this.dare,
    required this.isActioning,
    required this.onRestrict,
    required this.onDelete,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dare.adminRestricted
              ? AppColors.error.withValues(alpha: 0.5)
              : context.col.border,
          width: dare.adminRestricted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Restricted banner
          if (dare.adminRestricted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.shield_slash, size: 12, color: AppColors.error),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dare.adminRestrictReason ?? 'Restricted by admin',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: dare.category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(dare.category.icon, size: 18, color: dare.category.color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dare.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: context.col.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Iconsax.user, size: 11, color: context.col.textMuted),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  dare.creatorName,
                                  style: TextStyle(fontSize: 11, color: context.col.textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Iconsax.clock, size: 11, color: context.col.textMuted),
                              const SizedBox(width: 3),
                              Text(
                                _fmtDate(dare.createdAt),
                                style: TextStyle(fontSize: 11, color: context.col.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Stat chips row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Chip(
                      icon: Iconsax.people,
                      label: '${dare.approvedMembers.length}/${dare.maxParticipants}',
                      color: AppColors.secondary,
                    ),
                    _Chip(
                      icon: Iconsax.element_3,
                      label: '${dare.challenges.length} tasks',
                      color: AppColors.primary,
                    ),
                    _Chip(
                      icon: dare.visibility == DareVisibility.public
                          ? Iconsax.eye
                          : Iconsax.eye_slash,
                      label: dare.visibility == DareVisibility.public ? 'Public' : 'Private',
                      color: dare.visibility == DareVisibility.public
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    _Chip(
                      icon: Iconsax.category,
                      label: dare.displayCategory,
                      color: dare.category.color,
                    ),
                    if (dare.joinRequests.isNotEmpty)
                      _Chip(
                        icon: Iconsax.clock,
                        label: '${dare.joinRequests.length} pending',
                        color: AppColors.warning,
                      ),
                  ],
                ),

                const SizedBox(height: 10),
                Divider(color: context.col.border, height: 1),
                const SizedBox(height: 8),

                // ── Action row
                isActioning
                    ? const Center(
                        child: SizedBox(
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          _ActionBtn(
                            icon: Iconsax.info_circle,
                            label: 'Detail',
                            color: AppColors.primary,
                            onTap: () => onViewDetail(dare),
                          ),
                          const Spacer(),
                          _ActionBtn(
                            icon: dare.adminRestricted
                                ? Iconsax.shield_tick
                                : Iconsax.shield_slash,
                            label: dare.adminRestricted ? 'Unrestrict' : 'Restrict',
                            color: dare.adminRestricted ? AppColors.success : AppColors.warning,
                            onTap: () => onRestrict(dare),
                          ),
                          const SizedBox(width: 12),
                          _ActionBtn(
                            icon: Iconsax.trash,
                            label: 'Delete',
                            color: AppColors.error,
                            onTap: () => onDelete(dare),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 180.ms);
  }

  String _fmtDate(DateTime d) {
    try {
      return DateFormat('d MMM y').format(d);
    } catch (_) {
      return '${d.day}/${d.month}/${d.year}';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dare Detail Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DareDetailSheet extends StatelessWidget {
  final DareModel dare;
  const _DareDetailSheet({required this.dare});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, ctrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.col.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dare.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: context.col.textPrimary,
                    ),
                  ),
                ),
                if (dare.adminRestricted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'RESTRICTED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                // Basic info
                _detailSection('Overview', [
                  _DetailRow('Creator', dare.creatorName),
                  _DetailRow('Category', dare.displayCategory),
                  _DetailRow('Visibility',
                      dare.visibility == DareVisibility.public ? 'Public' : 'Private'),
                  _DetailRow('Members',
                      '${dare.approvedMembers.length} / ${dare.maxParticipants}'),
                  _DetailRow('Join Code', dare.joinCode),
                  _DetailRow('Requires Proof', dare.requiresProof ? 'Yes' : 'No'),
                  _DetailRow('XP Reward', '+${dare.xpReward} XP on completion'),
                  if (dare.deadline != null)
                    _DetailRow('Deadline', _fmtDate(dare.deadline!)),
                  if (dare.adminRestricted && dare.adminRestrictReason != null)
                    _DetailRow('Restrict Reason', dare.adminRestrictReason!, valueColor: AppColors.error),
                ]),
                const SizedBox(height: 16),

                // Challenges
                if (dare.challenges.isNotEmpty) ...[
                  _sectionLabel('Challenges (${dare.challenges.length})', context),
                  const SizedBox(height: 8),
                  ...dare.challenges.map((c) => _ChallengeDetailTile(c)),
                  const SizedBox(height: 16),
                ],

                // Members
                if (dare.approvedMembers.isNotEmpty) ...[
                  _sectionLabel('Active Members (${dare.approvedMembers.length})', context),
                  const SizedBox(height: 8),
                  ...dare.approvedMembers.map((m) => _MemberDetailTile(m, dare.challenges.length)),
                  const SizedBox(height: 16),
                ],

                // Pending
                if (dare.joinRequests.isNotEmpty) ...[
                  _sectionLabel('Pending Requests (${dare.joinRequests.length})', context),
                  const SizedBox(height: 8),
                  ...dare.joinRequests.map((r) => _MemberDetailTile(r, dare.challenges.length, isPending: true)),
                ],

                // Tags
                if (dare.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: dare.tags
                        .map(
                          (t) => Chip(
                            label: Text(t, style: const TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: context.col.surface,
                            side: BorderSide(color: context.col.border),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    try {
      return DateFormat('d MMM y').format(d);
    } catch (_) {
      return '${d.day}/${d.month}/${d.year}';
    }
  }

  Widget _detailSection(String title, List<Widget> rows) {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.col.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: context.col.textPrimary,
                ),
              ),
            ),
            Divider(color: context.col.border, height: 1),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: context.col.textPrimary,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _DetailRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: context.col.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor ?? context.col.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeDetailTile extends StatelessWidget {
  final DareChallenge challenge;
  const _ChallengeDetailTile(this.challenge);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(challenge.category.icon, size: 14, color: challenge.category.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  challenge.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: context.col.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: challenge.medalType.bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  challenge.medalType.label,
                  style: TextStyle(
                    fontSize: 9,
                    color: challenge.medalType.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (challenge.description != null && challenge.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              challenge.description!,
              style: TextStyle(fontSize: 11, color: context.col.textMuted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '+${challenge.xpReward} XP',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              if (challenge.milestones.isNotEmpty)
                Text(
                  '${challenge.milestones.length} milestone${challenge.milestones.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 10, color: context.col.textMuted),
                ),
              if (challenge.type == DareChallengeType.appListing &&
                  challenge.listingLocation != null) ...[
                const SizedBox(width: 10),
                Icon(Iconsax.location, size: 11, color: context.col.textMuted),
                const SizedBox(width: 2),
                Text(
                  challenge.listingLocation!,
                  style: TextStyle(fontSize: 10, color: context.col.textMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberDetailTile extends StatelessWidget {
  final DareMember member;
  final int totalChallenges;
  final bool isPending;

  const _MemberDetailTile(this.member, this.totalChallenges, {this.isPending = false});

  @override
  Widget build(BuildContext context) {
    final statusColor = isPending
        ? AppColors.warning
        : member.status == DareMemberStatus.suspended
            ? AppColors.error
            : AppColors.success;
    final statusLabel = isPending
        ? 'Pending'
        : member.status == DareMemberStatus.suspended
            ? 'Suspended'
            : 'Active';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: context.col.surfaceElevated,
            backgroundImage: member.userPhoto != null
                ? CachedNetworkImageProvider(member.userPhoto!)
                : null,
            child: member.userPhoto == null
                ? Text(
                    member.userName.isNotEmpty ? member.userName[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 12, color: context.col.textSecondary),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: context.col.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(statusLabel, style: TextStyle(fontSize: 9, color: statusColor)),
                    if (!isPending && totalChallenges > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${member.completedChallenges}/$totalChallenges done',
                        style: TextStyle(fontSize: 9, color: context.col.textMuted),
                      ),
                    ],
                    if (!isPending && member.totalXpEarned > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '+${member.totalXpEarned} XP',
                        style: const TextStyle(fontSize: 9, color: AppColors.primary),
                      ),
                    ],
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
// Shared small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _DareSummaryTile extends StatelessWidget {
  final DareModel dare;
  final bool compact;
  const _DareSummaryTile({required this.dare, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dare.adminRestricted
              ? AppColors.error.withValues(alpha: 0.4)
              : context.col.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: dare.category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(dare.category.icon, size: 16, color: dare.category.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dare.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: context.col.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${dare.approvedMembers.length} members · ${dare.challenges.length} tasks',
                  style: TextStyle(fontSize: 11, color: context.col.textMuted),
                ),
              ],
            ),
          ),
          if (dare.adminRestricted)
            const Icon(Iconsax.shield_slash, size: 14, color: AppColors.error),
        ],
      ),
    );
  }
}

class _AdminSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  const _AdminSectionHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: context.col.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: context.col.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  final double height;
  const _ChartCard({required this.child, this.height = 210});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(8, 18, 18, 8),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: child,
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count, pct;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: context.col.textSecondary)),
        const Spacer(),
        Text(
          '$count ($pct%)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: context.col.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _SmallAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load dare data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(color: context.col.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _emptyChart(BuildContext context, String msg) {
  return Container(
    height: 100,
    decoration: BoxDecoration(
      color: context.col.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.col.border),
    ),
    child: Center(
      child: Text(msg, style: TextStyle(color: context.col.textMuted, fontSize: 13)),
    ),
  );
}
