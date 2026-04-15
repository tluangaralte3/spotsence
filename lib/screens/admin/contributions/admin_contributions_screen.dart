// lib/screens/admin/contributions/admin_contributions_screen.dart
//
// Admin review screen for user-contributed listings.
// Tabs: Pending (requires action) | All (read-only history).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/contribute_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/contributed_listing_model.dart';
import '../../../services/contribute_service.dart';

class AdminContributionsScreen extends ConsumerStatefulWidget {
  const AdminContributionsScreen({super.key});

  @override
  ConsumerState<AdminContributionsScreen> createState() =>
      _AdminContributionsScreenState();
}

class _AdminContributionsScreenState
    extends ConsumerState<AdminContributionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _approve(ContributedListing c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surfaceElevated,
        title: const Text('Approve Contribution?'),
        content: Text(
          '"${c.name}" will be published to the ${c.category.label} listings and appear on the map.',
          style: TextStyle(color: context.col.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final err =
        await ref.read(contributeServiceProvider).approve(c);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      err == null
          ? SnackBar(
              content: Text('"${c.name}" approved and published!'),
              backgroundColor: AppColors.success,
            )
          : SnackBar(
              content: Text('Error: $err'),
              backgroundColor: AppColors.error,
            ),
    );
  }

  Future<void> _rejectDialog(ContributedListing c) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surfaceElevated,
        title: const Text('Reject Contribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reason / feedback for the contributor (optional):',
                style: TextStyle(
                    color: context.col.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Duplicate entry, low-quality photos…',
                hintStyle: TextStyle(
                    color: context.col.textMuted, fontSize: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final err = await ref
        .read(contributeServiceProvider)
        .reject(c, notesCtrl.text.trim());
    notesCtrl.dispose();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      err == null
          ? SnackBar(
              content: Text('"${c.name}" rejected.'),
              backgroundColor: AppColors.error,
            )
          : SnackBar(
              content: Text('Error: $err'),
              backgroundColor: AppColors.error,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final pendingAsync = ref.watch(pendingContributionsProvider);
    final allAsync = ref.watch(allContributionsProvider);

    final pendingCount =
        pendingAsync.value?.length ?? 0;

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.surface,
        elevation: 0,
        title: Text('Contributions',
            style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: col.textMuted,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pending'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$pendingCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'All'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── Pending Tab ───────────────────────────────────────────────
          pendingAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64,
                          color: AppColors.success.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text('All caught up!',
                          style: TextStyle(
                              color: col.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 18)),
                      const SizedBox(height: 6),
                      Text('No pending contributions.',
                          style: TextStyle(
                              color: col.textSecondary, fontSize: 14)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, sep1) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ContributionCard(
                  item: items[i],
                  showActions: true,
                  onApprove: () => _approve(items[i]),
                  onReject: () => _rejectDialog(items[i]),
                ),
              );
            },
          ),

          // ── All Tab ───────────────────────────────────────────────────
          allAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Text('No contributions yet.',
                      style: TextStyle(color: col.textMuted)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, sep1) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ContributionCard(
                  item: items[i],
                  showActions:
                      items[i].status == ContributedListingStatus.pending,
                  onApprove: () => _approve(items[i]),
                  onReject: () => _rejectDialog(items[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contribution card
// ─────────────────────────────────────────────────────────────────────────────

class _ContributionCard extends StatelessWidget {
  final ContributedListing item;
  final bool showActions;
  final VoidCallback onApprove, onReject;

  const _ContributionCard({
    required this.item,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image strip
          if (item.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: item.imageUrls.length,
                  itemBuilder: (_, i) => Image.network(
                    item.imageUrls[i],
                    width: 180,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, err2, trace) => Container(
                      width: 180,
                      height: 140,
                      color: col.surfaceElevated,
                      child: Icon(Icons.broken_image,
                          color: col.textMuted),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + Status chips
                Row(children: [
                  _chip(
                    '${item.category.emoji} ${item.category.label}',
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _statusChip(item.status, col),
                ]),
                const SizedBox(height: 10),

                // Name
                Text(item.name,
                    style: TextStyle(
                        color: col.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 4),

                // District + GPS
                Row(children: [
                  Icon(Icons.location_on,
                      size: 13, color: col.textMuted),
                  const SizedBox(width: 4),
                  Text('${item.district}  ·  ',
                      style: TextStyle(
                          color: col.textSecondary, fontSize: 12)),
                  Text(
                    '${item.latitude.toStringAsFixed(5)}, ${item.longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                        color: col.textMuted,
                        fontSize: 11,
                        fontFamily: 'monospace'),
                  ),
                ]),
                const SizedBox(height: 8),

                // Description
                Text(item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: col.textSecondary, fontSize: 13)),

                // Admin notes (if rejected)
                if (item.adminNotes != null &&
                    item.adminNotes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              AppColors.error.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(item.adminNotes!,
                              style: TextStyle(
                                  color: col.textSecondary,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Contributor row
                const SizedBox(height: 10),
                Row(children: [
                  if (item.contributorPhotoUrl != null)
                    CircleAvatar(
                      radius: 12,
                      backgroundImage:
                          NetworkImage(item.contributorPhotoUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 12,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        item.contributorName.isNotEmpty
                            ? item.contributorName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.contributorName,
                        style: TextStyle(
                            color: col.textSecondary, fontSize: 12)),
                  ),
                  Text(
                    _formatDate(item.createdAt),
                    style:
                        TextStyle(color: col.textMuted, fontSize: 11),
                  ),
                ]),

                // Actions
                if (showActions) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                              color: AppColors.error
                                  .withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
      );

  Widget _statusChip(ContributedListingStatus status, AppColorScheme col) {
    Color bg, fg;
    switch (status) {
      case ContributedListingStatus.pending:
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        break;
      case ContributedListingStatus.approved:
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      case ContributedListingStatus.rejected:
        bg = AppColors.error.withValues(alpha: 0.15);
        fg = AppColors.error;
        break;
    }
    return _chip(status.label, bg, fg);
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
