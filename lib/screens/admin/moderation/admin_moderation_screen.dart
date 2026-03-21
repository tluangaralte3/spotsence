// lib/screens/admin/moderation/admin_moderation_screen.dart
//
// Content moderation — review community posts and flag reports.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/admin_service.dart';

// Provider for flagged/pending community content
final _moderationProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collectionGroup('reviews')
      .where('flagged', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots();
});

final _recentPostsProvider = StreamProvider<QuerySnapshot>((ref) {
  return FirebaseFirestore.instance
      .collection('community_posts')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots();
});

class AdminModerationScreen extends ConsumerStatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  ConsumerState<AdminModerationScreen> createState() =>
      _AdminModerationScreenState();
}

class _AdminModerationScreenState extends ConsumerState<AdminModerationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.surface,
        title: Text(
          'Moderation',
          style: TextStyle(color: col.textPrimary, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: col.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Flagged Reviews'),
            Tab(text: 'Recent Posts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_FlaggedReviewsTab(), _RecentPostsTab()],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flagged Reviews Tab
// ─────────────────────────────────────────────────────────────────────────────

class _FlaggedReviewsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final flagged = ref.watch(_moderationProvider);

    return flagged.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) {
        // collectionGroup may fail without composite index — show info
        return _InfoCard(
          icon: Icons.info_outline,
          color: AppColors.info,
          message:
              'Flagged reviews query requires a Firestore composite '
              'index on `reviews` (flagged ASC, createdAt DESC). '
              'Create it in the Firebase Console.\n\nError: $e',
        );
      },
      data: (snap) {
        if (snap.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 52,
                ),
                const SizedBox(height: 12),
                Text(
                  'No flagged content 🎉',
                  style: TextStyle(
                    color: col.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snap.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) =>
              _ModerationCard(doc: snap.docs[i], collection: 'reviews'),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Posts Tab
// ─────────────────────────────────────────────────────────────────────────────

class _RecentPostsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final posts = ref.watch(_recentPostsProvider);

    return posts.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => _InfoCard(
        icon: Icons.info_outline,
        color: AppColors.warning,
        message: 'community_posts collection not found or query failed: $e',
      ),
      data: (snap) {
        if (snap.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.article_outlined, color: col.textMuted, size: 48),
                const SizedBox(height: 12),
                Text(
                  'No posts yet.',
                  style: TextStyle(color: col.textSecondary, fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snap.docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) =>
              _ModerationCard(doc: snap.docs[i], collection: 'community_posts'),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Moderation card
// ─────────────────────────────────────────────────────────────────────────────

class _ModerationCard extends ConsumerWidget {
  final QueryDocumentSnapshot doc;
  final String collection;
  const _ModerationCard({required this.doc, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final col = context.col;
    final data = doc.data() as Map<String, dynamic>;
    final text =
        data['text'] as String? ??
        data['content'] as String? ??
        data['body'] as String? ??
        '—';
    final author =
        data['authorName'] as String? ??
        data['userName'] as String? ??
        'Unknown';
    final flagged = data['flagged'] as bool? ?? false;
    final ts = data['createdAt'];
    final date = ts is Timestamp ? ts.toDate() : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: flagged ? AppColors.error.withValues(alpha: 0.4) : col.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: col.textMuted, size: 14),
              const SizedBox(width: 4),
              Text(
                author,
                style: TextStyle(color: col.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              if (flagged)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '⚑ FLAGGED',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (date != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${date.day}/${date.month}',
                  style: TextStyle(color: col.textMuted, fontSize: 11),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: col.textPrimary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (flagged)
                OutlinedButton.icon(
                  onPressed: () => _unflag(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _delete(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.delete_outline, size: 14),
                label: const Text('Remove', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _unflag(BuildContext context, WidgetRef ref) async {
    await doc.reference.update({'flagged': false});
    await ref
        .read(adminServiceProvider)
        .logAdminActivity(
          action: 'contentApproved',
          targetCollection: collection,
          targetId: doc.id,
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content approved'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surface,
        title: Text(
          'Remove content?',
          style: TextStyle(color: context.col.textPrimary),
        ),
        content: Text(
          'This will permanently delete the item.',
          style: TextStyle(color: context.col.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.col.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await doc.reference.delete();
      await ref
          .read(adminServiceProvider)
          .logAdminActivity(
            action: 'contentRemoved',
            targetCollection: collection,
            targetId: doc.id,
          );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info card
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: col.textSecondary,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
