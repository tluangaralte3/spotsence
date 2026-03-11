import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/bucket_list_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bucket_list_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BucketListDetailScreen — live-streaming detail view
// ─────────────────────────────────────────────────────────────────────────────

class BucketListDetailScreen extends ConsumerWidget {
  final String listId;
  const BucketListDetailScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bucketListDetailProvider(listId));
    final user = ref.watch(currentUserProvider);

    return async.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
      data: (list) {
        if (list == null) {
          return const Scaffold(
            backgroundColor: AppColors.bg,
            body: Center(
              child: Text(
                'List not found',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return _DetailBody(list: list, currentUserId: user?.id ?? '');
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DetailBody
// ─────────────────────────────────────────────────────────────────────────────

class _DetailBody extends ConsumerWidget {
  final BucketListModel list;
  final String currentUserId;

  const _DetailBody({required this.list, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHost = list.isHost(currentUserId);
    final isMember = list.isMember(currentUserId);
    final pct = (list.progress * 100).toInt();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── Banner SliverAppBar ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.bg,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (isHost)
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Colors.white,
                  ),
                  color: AppColors.surface,
                  onSelected: (v) => _onHostMenu(context, ref, v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Edit List',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(
                            Icons.share_outlined,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Share Code',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete List',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              if (!isHost && isMember)
                IconButton(
                  icon: const Icon(
                    Icons.exit_to_app_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: () => _confirmLeave(context, ref),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  list.bannerUrl.isNotEmpty
                      ? Image.network(
                          list.bannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.surfaceElevated),
                        )
                      : Container(color: AppColors.surfaceElevated),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (list.challengeTitle != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              '⚡ ${list.challengeTitle}',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        Text(
                          list.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${list.category.emoji} ${list.displayCategory} · by ${list.hostName}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body content ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Progress + stats ─────────────────────────────
                  _ProgressCard(list: list, pct: pct),
                  const SizedBox(height: 16),

                  // ── Join code (host only) ────────────────────────
                  if (isHost) _JoinCodeCard(list: list),
                  if (isHost) const SizedBox(height: 16),

                  // ── Pending requests (host only) ─────────────────
                  if (isHost && list.joinRequests.isNotEmpty) ...[
                    _PendingRequestsCard(
                      list: list,
                      onApprove: (uid) => ref
                          .read(bucketListControllerProvider.notifier)
                          .approveJoin(listId: list.id, userId: uid),
                      onDecline: (uid) => ref
                          .read(bucketListControllerProvider.notifier)
                          .declineJoin(listId: list.id, userId: uid),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Members ──────────────────────────────────────
                  _MembersRow(list: list),
                  const SizedBox(height: 20),

                  // ── Bucket Items ─────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Bucket List Items',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isHost || isMember)
                        GestureDetector(
                          onTap: () => context.push(
                            AppRoutes.addBucketItemPath(list.id),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (list.items.isEmpty)
                    _EmptyItems(
                      canAdd: isHost || isMember,
                      onAdd: () =>
                          context.push(AppRoutes.addBucketItemPath(list.id)),
                    )
                  else
                    ...list.items.asMap().entries.map(
                      (e) => _BucketItemTile(
                        item: e.value,
                        index: e.key,
                        listId: list.id,
                        canCheck: isHost || isMember,
                        currentUserId: currentUserId,
                        currentUserName:
                            ref.read(currentUserProvider)?.displayName ?? '',
                      ),
                    ),

                  // ── Completion banner ────────────────────────────
                  if (list.isCompleted) ...[
                    const SizedBox(height: 20),
                    _CompletionBanner(xpReward: list.xpReward),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom FAB: join (for non-members) ────────────────────────
      floatingActionButton: (!isHost && !isMember)
          ? FloatingActionButton.extended(
              onPressed: () => _confirmJoin(context, ref),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.bg,
              icon: const Icon(Icons.group_add_rounded),
              label: const Text('Join This List'),
            )
          : null,
    );
  }

  void _onHostMenu(BuildContext context, WidgetRef ref, String action) {
    if (action == 'edit') {
      context.push(AppRoutes.editBucketListPath(list.id));
      return;
    }
    if (action == 'share') {
      Clipboard.setData(ClipboardData(text: list.joinCode));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Join code "${list.joinCode}" copied! Share it with friends 🎉',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } else if (action == 'delete') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Delete List?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'This will permanently delete the bucket list and all its items.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await ref
                    .read(bucketListControllerProvider.notifier)
                    .delete(list.id);
                if (context.mounted) context.pop();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _confirmLeave(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Leave List?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'You will need a join code to rejoin.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(bucketListControllerProvider.notifier)
                  .leave(listId: list.id, userId: currentUserId);
              if (context.mounted) context.pop();
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmJoin(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go(AppRoutes.login);
      return;
    }

    if (list.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This list is full 😔'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Join this list?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Your request will be sent to ${list.hostName} for approval.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(bucketListControllerProvider.notifier)
                  .requestJoin(
                    listId: list.id,
                    userId: user.id,
                    userName: user.displayName,
                    userPhoto: user.photoURL,
                    isPublic: list.visibility == BucketVisibility.public,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Request sent to ${list.hostName}! 🙌'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.bg,
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProgressCard
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final BucketListModel list;
  final int pct;

  const _ProgressCard({required this.list, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                label: 'Progress',
                value: '$pct%',
                color: AppColors.primary,
              ),
              _Stat(
                label: 'Checked',
                value: '${list.checkedCount}/${list.items.length}',
                color: AppColors.textPrimary,
              ),
              _Stat(
                label: 'Members',
                value: '${list.approvedCount}/${list.maxMembers}',
                color: AppColors.textPrimary,
              ),
              _Stat(
                label: 'XP Reward',
                value: '+${list.xpReward}',
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: list.progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _JoinCodeCard
// ─────────────────────────────────────────────────────────────────────────────

class _JoinCodeCard extends StatelessWidget {
  final BucketListModel list;
  const _JoinCodeCard({required this.list});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.vpn_key_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Join Code',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  list.joinCode,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 6,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: list.joinCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code copied to clipboard! 🎉'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PendingRequestsCard
// ─────────────────────────────────────────────────────────────────────────────

class _PendingRequestsCard extends StatelessWidget {
  final BucketListModel list;
  final void Function(String uid) onApprove;
  final void Function(String uid) onDecline;

  const _PendingRequestsCard({
    required this.list,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔔 ${list.joinRequests.length} Join Request${list.joinRequests.length > 1 ? 's' : ''}',
            style: const TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          ...list.joinRequests.map(
            (req) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surfaceElevated,
                    backgroundImage: req.userPhoto != null
                        ? NetworkImage(req.userPhoto!)
                        : null,
                    child: req.userPhoto == null
                        ? Text(
                            req.userName.isNotEmpty
                                ? req.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      req.userName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onDecline(req.userId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onApprove(req.userId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Approve ✓',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
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
// _MembersRow
// ─────────────────────────────────────────────────────────────────────────────

class _MembersRow extends StatelessWidget {
  final BucketListModel list;
  const _MembersRow({required this.list});

  @override
  Widget build(BuildContext context) {
    final approved = list.approvedMembers;

    return Row(
      children: [
        ...approved
            .take(6)
            .map(
              (m) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Tooltip(
                  message: '${m.userName}${m.isHost ? ' (Host)' : ''}',
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.surfaceElevated,
                        backgroundImage: m.userPhoto != null
                            ? NetworkImage(m.userPhoto!)
                            : null,
                        child: m.userPhoto == null
                            ? Text(
                                m.userName.isNotEmpty
                                    ? m.userName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                      if (m.isHost)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.bg, width: 1),
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              size: 8,
                              color: AppColors.bg,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        if (approved.length > 6)
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceElevated,
            child: Text(
              '+${approved.length - 6}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          '${approved.length} traveler${approved.length != 1 ? 's' : ''}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BucketItemTile
// ─────────────────────────────────────────────────────────────────────────────

class _BucketItemTile extends ConsumerWidget {
  final BucketItem item;
  final int index;
  final String listId;
  final bool canCheck;
  final String currentUserId;
  final String currentUserName;

  const _BucketItemTile({
    required this.item,
    required this.index,
    required this.listId,
    required this.canCheck,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: item.isChecked
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isChecked
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 4,
          ),
          leading: GestureDetector(
            onTap: canCheck
                ? () => ref
                      .read(bucketListControllerProvider.notifier)
                      .toggleItem(
                        listId: listId,
                        itemIndex: index,
                        newChecked: !item.isChecked,
                        userId: currentUserId,
                        userName: currentUserName,
                      )
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.isChecked
                    ? AppColors.primary
                    : AppColors.surfaceElevated,
                border: Border.all(
                  color: item.isChecked ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: item.isChecked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.bg,
                    )
                  : null,
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              color: item.isChecked
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.category.emoji} ${item.displayCategory}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              if (item.isChecked && item.checkedByUserName != null)
                Text(
                  '✓ by ${item.checkedByUserName}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                  ),
                ),
              if (item.note != null && item.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '📝 ${item.note}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
          trailing: item.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyItems
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyItems extends StatelessWidget {
  final bool canAdd;
  final VoidCallback onAdd;

  const _EmptyItems({required this.canAdd, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Text('📍', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          const Text(
            'No items yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add places, restaurants, cafés and more!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          if (canAdd) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add First Item'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
// _CompletionBanner
// ─────────────────────────────────────────────────────────────────────────────

class _CompletionBanner extends StatelessWidget {
  final int xpReward;
  const _CompletionBanner({required this.xpReward});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.accent.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          const Text(
            'Adventure Complete!',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You\'ve conquered every stop on this bucket list!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              '+$xpReward XP Earned! 🏆',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
