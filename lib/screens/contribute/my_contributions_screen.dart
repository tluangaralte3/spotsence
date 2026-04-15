// lib/screens/contribute/my_contributions_screen.dart
//
// Full-page screen listing the current user's contribution submissions
// with real-time status tracking (pending / approved / rejected).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../controllers/contribute_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/contributed_listing_model.dart';

class MyContributionsScreen extends ConsumerWidget {
  const MyContributionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributionsAsync = ref.watch(myContributionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contributions'),
        backgroundColor: context.col.bg,
        foregroundColor: context.col.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: contributionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (contributions) {
          if (contributions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.send_1,
                        color: AppColors.primary, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'No submissions yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Places you contribute will appear here\nwith their approval status.',
                      style: TextStyle(color: context.col.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.contribute),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add a Place'),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Summary chips ─────────────────────────────────────────────
          final pending = contributions
              .where((c) => c.status == ContributedListingStatus.pending)
              .length;
          final approved = contributions
              .where((c) => c.status == ContributedListingStatus.approved)
              .length;
          final rejected = contributions
              .where((c) => c.status == ContributedListingStatus.rejected)
              .length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary row
              Row(
                children: [
                  _SummaryChip(
                    label: 'Pending',
                    count: pending,
                    color: AppColors.warning,
                    icon: Icons.hourglass_top_rounded,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Approved',
                    count: approved,
                    color: AppColors.success,
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 8),
                  _SummaryChip(
                    label: 'Rejected',
                    count: rejected,
                    color: AppColors.error,
                    icon: Icons.cancel_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...contributions.asMap().entries.map(
                    (e) => _ContributionCard(contribution: e.value)
                        .animate(delay: Duration(milliseconds: e.key * 60))
                        .fadeIn()
                        .slideY(begin: 0.1),
                  ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.contribute),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add a Place'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Summary chip ──────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Contribution card ────────────────────────────────────────────────────────

class _ContributionCard extends StatelessWidget {
  final ContributedListing contribution;
  const _ContributionCard({required this.contribution});

  @override
  Widget build(BuildContext context) {
    final status = contribution.status;
    final (statusColor, statusBg, statusIcon) = switch (status) {
      ContributedListingStatus.approved => (
          AppColors.success,
          AppColors.success.withValues(alpha: 0.12),
          Icons.check_circle_rounded,
        ),
      ContributedListingStatus.rejected => (
          AppColors.error,
          AppColors.error.withValues(alpha: 0.12),
          Icons.cancel_rounded,
        ),
      ContributedListingStatus.pending => (
          AppColors.warning,
          AppColors.warning.withValues(alpha: 0.12),
          Icons.hourglass_top_rounded,
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contribution.imageUrls.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: contribution.imageUrls.first,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${contribution.category.emoji} ${contribution.category.label}',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.col.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  contribution.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contribution.address,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.col.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Submitted ${_formatDate(contribution.createdAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.col.textMuted,
                  ),
                ),
                if (status == ContributedListingStatus.approved &&
                    contribution.reviewedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Approved ${_formatDate(contribution.reviewedAt!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (status == ContributedListingStatus.rejected &&
                    contribution.adminNotes != null &&
                    contribution.adminNotes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: AppColors.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            contribution.adminNotes!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
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
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
