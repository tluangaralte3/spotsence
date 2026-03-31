import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../controllers/dare_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dare_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DareDashboardScreen — Dare stats, interactive charts, and member management
// ─────────────────────────────────────────────────────────────────────────────

class DareDashboardScreen extends ConsumerWidget {
  final String userId;
  const DareDashboardScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daresAsync = ref.watch(createdDaresStreamProvider(userId));
    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        foregroundColor: context.col.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.flash,
                color: AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Dare Dashboard'),
          ],
        ),
      ),
      body: daresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error: $e',
              style: TextStyle(color: context.col.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (dares) => dares.isEmpty
            ? const _EmptyState()
            : _DashboardBody(dares: dares, userId: userId),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.flash, size: 64, color: context.col.textMuted),
            const SizedBox(height: 16),
            Text(
              'No dares created yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: context.col.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Head to the Community tab and create\nyour first dare challenge!',
              style: TextStyle(color: context.col.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Body ───────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerStatefulWidget {
  final List<DareModel> dares;
  final String userId;
  const _DashboardBody({required this.dares, required this.userId});

  @override
  ConsumerState<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends ConsumerState<_DashboardBody> {
  final Map<String, bool> _expanded = {};
  final Set<String> _actioning = {};

  // ── Aggregated stats ───────────────────────────────────────────────────────

  int get _totalApproved => widget.dares
      .expand((d) => d.members)
      .where((m) => m.status == DareMemberStatus.approved)
      .length;

  int get _totalPending => widget.dares
      .expand((d) => d.joinRequests)
      .length;

  int get _totalSuspended => widget.dares
      .expand((d) => d.members)
      .where((m) => m.status == DareMemberStatus.suspended)
      .length;

  int get _totalCompletions => widget.dares
      .expand((d) => d.members)
      .fold(0, (sum, m) => sum + m.completedChallenges);

  // ── Bar chart data (max 6 dares) ───────────────────────────────────────────

  List<BarChartGroupData> _buildBarGroups() {
    final limited = widget.dares.take(6).toList();
    return List.generate(limited.length, (i) {
      final dare = limited[i];
      final maxPossible = (dare.challenges.length *
              max(1, dare.approvedMembers.length))
          .toDouble();
      final completions = dare.approvedMembers
          .fold(0, (s, m) => s + m.completedChallenges)
          .toDouble();
      return BarChartGroupData(
        x: i,
        groupVertically: false,
        barRods: [
          BarChartRodData(
            toY: maxPossible > 0 ? maxPossible : 1,
            color: AppColors.primary.withValues(alpha: 0.22),
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: completions,
            color: AppColors.primary,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    });
  }

  // ── Pie chart sections ─────────────────────────────────────────────────────

  List<PieChartSectionData> _buildPieSections() {
    final approved = _totalApproved;
    final pending = _totalPending;
    final suspended = _totalSuspended;
    final total = approved + pending + suspended;
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: context.col.border,
          title: 'None',
          radius: 50,
          titleStyle: TextStyle(fontSize: 11, color: context.col.textMuted),
        ),
      ];
    }
    return [
      if (approved > 0)
        PieChartSectionData(
          value: approved.toDouble(),
          color: AppColors.success,
          title: '$approved',
          radius: 55,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      if (pending > 0)
        PieChartSectionData(
          value: pending.toDouble(),
          color: AppColors.warning,
          title: '$pending',
          radius: 55,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      if (suspended > 0)
        PieChartSectionData(
          value: suspended.toDouble(),
          color: AppColors.error,
          title: '$suspended',
          radius: 55,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
    ];
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Stats row
              _buildStatsRow(),
              const SizedBox(height: 28),

              // ── Challenge completions chart
              _SectionHeader(
                icon: Iconsax.chart_square,
                title: 'Challenge Completions',
                subtitle: 'Max possible vs completed per dare',
              ),
              const SizedBox(height: 12),
              _buildBarChartCard(),
              const SizedBox(height: 8),
              _buildBarLegendChips(),
              const SizedBox(height: 28),

              // ── Member status pie
              _SectionHeader(
                icon: Iconsax.people,
                title: 'Member Status',
                subtitle: 'Breakdown across all your dares',
              ),
              const SizedBox(height: 12),
              _buildMemberStatusCard(),
              const SizedBox(height: 28),

              // ── Member management per dare
              _SectionHeader(
                icon: Iconsax.setting_2,
                title: 'Manage Members',
                subtitle: 'Approve, suspend, or remove participants',
              ),
              const SizedBox(height: 12),
              ...widget.dares.map((d) => _buildDareManagementCard(d)),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'Dares',
            value: '${widget.dares.length}',
            icon: Iconsax.flash,
            color: AppColors.primary,
          ).animate().fadeIn(delay: 0.ms).slideY(begin: 0.1),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Members',
            value: '$_totalApproved',
            icon: Iconsax.people,
            color: AppColors.success,
          ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.1),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Completions',
            value: '$_totalCompletions',
            icon: Iconsax.tick_circle,
            color: AppColors.secondary,
          ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.1),
        ),
      ],
    );
  }

  // ── Bar chart ──────────────────────────────────────────────────────────────

  Widget _buildBarChartCard() {
    final groups = _buildBarGroups();
    if (groups.isEmpty) {
      return _emptyChartBox('No dares with challenges yet');
    }
    final maxY = groups
        .expand((g) => g.barRods)
        .map((r) => r.toY)
        .fold(0.0, max);
    final interval = max(1.0, (maxY / 4).ceilToDouble());

    return Container(
      height: 210,
      padding: const EdgeInsets.fromLTRB(8, 18, 18, 8),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: BarChart(
        BarChartData(
          maxY: (maxY + interval).ceilToDouble(),
          barGroups: groups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) => FlLine(
              color: context.col.border.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: interval,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.col.textMuted,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx >= widget.dares.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'D${idx + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        color: context.col.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, _, rod, rodIdx) {
                final dare = widget.dares[group.x];
                final short = dare.title.length > 10
                    ? '${dare.title.substring(0, 10)}…'
                    : dare.title;
                final label = rodIdx == 0 ? 'Max' : 'Done';
                return BarTooltipItem(
                  '$short\n$label: ${rod.toY.toInt()}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarLegendChips() {
    final limited = widget.dares.take(6).toList();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        // Colour key
        _ColorKey(color: AppColors.primary.withValues(alpha: 0.25), label: 'Max possible'),
        _ColorKey(color: AppColors.primary, label: 'Completed'),
        const SizedBox(width: 4),
        // Dare index labels
        ...List.generate(limited.length, (i) {
          final title = limited[i].title;
          final display =
              title.length > 14 ? '${title.substring(0, 14)}…' : title;
          return Chip(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            visualDensity: VisualDensity.compact,
            backgroundColor: context.col.surfaceElevated,
            side: BorderSide(color: context.col.border),
            label: Text(
              'D${i + 1}: $display',
              style: TextStyle(
                fontSize: 10,
                color: context.col.textSecondary,
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Pie chart ──────────────────────────────────────────────────────────────

  Widget _buildMemberStatusCard() {
    final total = _totalApproved + _totalPending + _totalSuspended;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: total == 0
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No members yet',
                  style: TextStyle(color: context.col.textMuted, fontSize: 13),
                ),
              ),
            )
          : Row(
              children: [
                SizedBox(
                  height: 160,
                  width: 160,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieSections(),
                      centerSpaceRadius: 38,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LegendRow(
                        color: AppColors.success,
                        label: 'Active',
                        count: _totalApproved,
                      ),
                      const SizedBox(height: 12),
                      _LegendRow(
                        color: AppColors.warning,
                        label: 'Pending',
                        count: _totalPending,
                      ),
                      const SizedBox(height: 12),
                      _LegendRow(
                        color: AppColors.error,
                        label: 'Suspended',
                        count: _totalSuspended,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: context.col.border, height: 1),
                      const SizedBox(height: 12),
                      _LegendRow(
                        color: context.col.textMuted,
                        label: 'Total',
                        count: total,
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ── Dare management card ───────────────────────────────────────────────────

  Widget _buildDareManagementCard(DareModel dare) {
    final isExpanded = _expanded[dare.id] ?? false;
    // Participants (exclude creator row)
    final participants = dare.members
        .where((m) => m.role != DareMemberRole.creator)
        .toList();
    final pendingRequests = dare.joinRequests;
    final totalCount = participants.length + pendingRequests.length;

    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.col.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.col.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // ── Card header (tap to expand)
                InkWell(
                  onTap: () =>
                      setState(() => _expanded[dare.id] = !isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Category icon
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color:
                                dare.category.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            dare.category.icon,
                            color: dare.category.color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dare.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: context.col.textPrimary,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.people,
                                    size: 12,
                                    color: context.col.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$totalCount '
                                    '${totalCount == 1 ? "person" : "people"}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.col.textMuted,
                                    ),
                                  ),
                                  if (pendingRequests.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${pendingRequests.length} pending',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (_totalSuspendedForDare(dare) > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_totalSuspendedForDare(dare)} suspended',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Iconsax.arrow_up_2
                              : Iconsax.arrow_down_1,
                          size: 16,
                          color: context.col.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Expandable member list
                if (isExpanded) ...[
                  Divider(color: context.col.border, height: 1),
                  if (totalCount == 0)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.people,
                            size: 16,
                            color: context.col.textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'No participants yet',
                            style: TextStyle(
                              color: context.col.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Pending requests first
                    if (pendingRequests.isNotEmpty) ...[
                      _sectionLabel('Join Requests', context),
                      ...pendingRequests.map(
                        (r) => _buildMemberTile(dare, r, isPending: true),
                      ),
                    ],
                    // Active / suspended members
                    if (participants.isNotEmpty) ...[
                      _sectionLabel('Participants', context),
                      ...participants.map(
                        (m) => _buildMemberTile(dare, m, isPending: false),
                      ),
                    ],
                  ],
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms);
  }

  int _totalSuspendedForDare(DareModel dare) =>
      dare.members
          .where((m) => m.status == DareMemberStatus.suspended)
          .length;

  Widget _sectionLabel(String label, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      color: context.col.border.withValues(alpha: 0.15),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.col.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMemberTile(
    DareModel dare,
    DareMember member, {
    required bool isPending,
  }) {
    final key = '${dare.id}|${member.userId}';
    final isActioning = _actioning.contains(key);

    Color statusColor;
    String statusLabel;
    if (isPending) {
      statusColor = AppColors.warning;
      statusLabel = 'Pending';
    } else {
      switch (member.status) {
        case DareMemberStatus.approved:
          statusColor = AppColors.success;
          statusLabel = 'Active';
        case DareMemberStatus.suspended:
          statusColor = AppColors.error;
          statusLabel = 'Suspended';
        default:
          statusColor = context.col.textMuted;
          statusLabel = 'Pending';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: context.col.border.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: context.col.surface,
            backgroundImage: member.userPhoto != null
                ? CachedNetworkImageProvider(member.userPhoto!)
                : null,
            child: member.userPhoto == null
                ? Text(
                    member.userName.isNotEmpty
                        ? member.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.col.textSecondary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),

          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.col.textPrimary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!isPending &&
                        member.completedChallenges > 0 &&
                        dare.challenges.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${member.completedChallenges}/${dare.challenges.length} challenges',
                        style: TextStyle(
                          fontSize: 10,
                          color: context.col.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions
          if (isActioning)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          else
            _buildActions(dare, member, isPending: isPending, key: key),
        ],
      ),
    );
  }

  Widget _buildActions(
    DareModel dare,
    DareMember member, {
    required bool isPending,
    required String key,
  }) {
    if (isPending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionIcon(
            icon: Iconsax.tick_circle,
            color: AppColors.success,
            tooltip: 'Approve',
            onTap: () => _approveJoin(dare, member, key),
          ),
          const SizedBox(width: 6),
          _ActionIcon(
            icon: Iconsax.close_circle,
            color: AppColors.error,
            tooltip: 'Decline',
            onTap: () => _declineJoin(dare, member, key),
          ),
        ],
      );
    }

    final isSuspended = member.status == DareMemberStatus.suspended;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ActionIcon(
          icon: isSuspended ? Iconsax.play_circle : Iconsax.pause_circle,
          color: isSuspended ? AppColors.success : AppColors.warning,
          tooltip: isSuspended ? 'Unsuspend' : 'Suspend',
          onTap: () => isSuspended
              ? _unsuspendMember(dare, member, key)
              : _suspendMember(dare, member, key),
        ),
        const SizedBox(width: 6),
        _ActionIcon(
          icon: Iconsax.user_remove,
          color: AppColors.error,
          tooltip: 'Remove',
          onTap: () => _confirmRemove(dare, member, key),
        ),
      ],
    );
  }

  // ── Action handlers ────────────────────────────────────────────────────────

  Future<void> _approveJoin(
      DareModel dare, DareMember member, String key) async {
    setState(() => _actioning.add(key));
    try {
      await ref.read(dareControllerProvider.notifier).approveJoin(
            dareId: dare.id,
            userId: member.userId,
          );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _actioning.remove(key));
    }
  }

  Future<void> _declineJoin(
      DareModel dare, DareMember member, String key) async {
    setState(() => _actioning.add(key));
    try {
      await ref.read(dareControllerProvider.notifier).declineJoin(
            dareId: dare.id,
            userId: member.userId,
          );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _actioning.remove(key));
    }
  }

  Future<void> _suspendMember(
      DareModel dare, DareMember member, String key) async {
    setState(() => _actioning.add(key));
    try {
      await ref.read(dareControllerProvider.notifier).suspendMember(
            dareId: dare.id,
            targetUserId: member.userId,
          );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _actioning.remove(key));
    }
  }

  Future<void> _unsuspendMember(
      DareModel dare, DareMember member, String key) async {
    setState(() => _actioning.add(key));
    try {
      await ref.read(dareControllerProvider.notifier).unsuspendMember(
            dareId: dare.id,
            targetUserId: member.userId,
          );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _actioning.remove(key));
    }
  }

  Future<void> _confirmRemove(
      DareModel dare, DareMember member, String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.col.surfaceElevated,
        title: Text(
          'Remove Member',
          style: TextStyle(color: ctx.col.textPrimary),
        ),
        content: Text(
          'Remove "${member.userName}" from "${dare.title}"?\n'
          'They will be permanently blocked from rejoining.',
          style: TextStyle(color: ctx.col.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: ctx.col.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Remove'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _actioning.add(key));
    try {
      await ref.read(dareControllerProvider.notifier).removeMember(
            dareId: dare.id,
            targetUserId: member.userId,
          );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _actioning.remove(key));
    }
  }

  // ── Helper widgets ─────────────────────────────────────────────────────────

  Widget _emptyChartBox(String message) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: context.col.textMuted, fontSize: 13),
        ),
      ),
    );
  }
}

// ─── Reusable small widgets ───────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: context.col.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

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
              style: TextStyle(
                fontSize: 11,
                color: context.col.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final bool bold;
  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: context.col.textSecondary,
            fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: bold ? context.col.textPrimary : context.col.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionIcon({
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

class _ColorKey extends StatelessWidget {
  final Color color;
  final String label;
  const _ColorKey({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: context.col.textSecondary),
        ),
      ],
    );
  }
}
