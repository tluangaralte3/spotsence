import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
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
      loading: () => Scaffold(
        backgroundColor: context.col.bg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.col.bg,
        body: Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
      data: (list) {
        if (list == null) {
          return Scaffold(
            backgroundColor: context.col.bg,
            body: Center(
              child: Text(
                'List not found',
                style: TextStyle(color: context.col.textSecondary),
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
      backgroundColor: context.col.bg,
      body: CustomScrollView(
        slivers: [
          // ── Banner SliverAppBar ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: context.col.bg,
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
                  color: context.col.surface,
                  onSelected: (v) => _onHostMenu(context, ref, v),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            color: context.col.textSecondary,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Edit List',
                            style: TextStyle(color: context.col.textPrimary),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(
                            Icons.share_outlined,
                            color: context.col.textSecondary,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Share Code',
                            style: TextStyle(color: context.col.textPrimary),
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
                          errorBuilder: (_, _, _) =>
                              Container(color: context.col.surfaceElevated),
                        )
                      : Container(color: context.col.surfaceElevated),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Iconsax.flash, size: 11, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  list.challengeTitle!,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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
                          '${list.displayCategory} · by ${list.hostName}',
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

                  // ── Members + Room interactions ──────────────────
                  _RoomMembersSection(
                    list: list,
                    currentUserId: currentUserId,
                    isHost: isHost,
                    isMember: isMember,
                  ),
                  const SizedBox(height: 20),

                  // ── Bucket Items ─────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Bucket List Items',
                          style: TextStyle(
                            color: context.col.textPrimary,
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
              heroTag: 'bucket_list_join_fab',
              onPressed: () => _confirmJoin(context, ref),
              backgroundColor: AppColors.primary,
              foregroundColor: context.col.bg,
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
          content: Text('Join code "${list.joinCode}" copied to clipboard!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } else if (action == 'delete') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: context.col.surface,
          title: Text(
            'Delete List?',
            style: TextStyle(color: context.col.textPrimary),
          ),
          content: Text(
            'This will permanently delete the bucket list and all its items.',
            style: TextStyle(color: context.col.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: context.col.textSecondary),
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
        backgroundColor: context.col.surface,
        title: Text(
          'Leave List?',
          style: TextStyle(color: context.col.textPrimary),
        ),
        content: Text(
          'You will need a join code to rejoin.',
          style: TextStyle(color: context.col.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.col.textSecondary),
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
          content: Text('This room is full.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surface,
        title: Text(
          'Join this list?',
          style: TextStyle(color: context.col.textPrimary),
        ),
        content: Text(
          'Your request will be sent to ${list.hostName} for approval.',
          style: TextStyle(color: context.col.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.col.textSecondary),
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
              foregroundColor: context.col.bg,
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
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
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
                color: context.col.textPrimary,
              ),
              _Stat(
                label: 'Members',
                value: '${list.approvedCount}/${list.maxMembers}',
                color: context.col.textPrimary,
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
              backgroundColor: context.col.border,
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
          style: TextStyle(color: context.col.textMuted, fontSize: 11),
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
          const Icon(Iconsax.key, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Join Code',
                  style: TextStyle(
                    color: context.col.textSecondary,
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
                  content: Text('Code copied to clipboard!'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Iconsax.copy, color: AppColors.primary),
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
          Row(
            children: [
              const Icon(Iconsax.notification, size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                '${list.joinRequests.length} Join Request${list.joinRequests.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...list.joinRequests.map(
            (req) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: context.col.surfaceElevated,
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
                      style: TextStyle(
                        color: context.col.textPrimary,
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
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.tick_circle, size: 12, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('Approve', style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          )),
                        ],
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
// _RoomMembersSection — members list with time-based interaction controls
// ─────────────────────────────────────────────────────────────────────────────

class _RoomMembersSection extends ConsumerWidget {
  final BucketListModel list;
  final String currentUserId;
  final bool isHost;
  final bool isMember;

  const _RoomMembersSection({
    required this.list,
    required this.currentUserId,
    required this.isHost,
    required this.isMember,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final approved = list.approvedMembers;
    final now = DateTime.now();

    // Find current user's member record
    final myMember = approved.cast<BucketMember?>().firstWhere(
      (m) => m?.userId == currentUserId,
      orElse: () => null,
    );
    final myDays = myMember?.daysInRoom(now) ?? 0;
    final canConnect = myMember?.canConnect(now) ?? false;
    final canPoke = myMember?.canPoke(now) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ───────────────────────────────────────────
        Row(
          children: [
            const Icon(Iconsax.people, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              '${approved.length} Member${approved.length != 1 ? 's' : ''}',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        // ── Time-unlock status bar (only for joined members) ─────────
        if (isMember || isHost) ...[
          const SizedBox(height: 10),
          _TimeUnlockBar(daysInRoom: myDays),
        ],

        const SizedBox(height: 12),

        // ── Member avatars row ───────────────────────────────────────
        _MembersRow(list: list),

        // ── Connect section (unlock at 10 days) ──────────────────────
        if ((isMember || isHost) && canConnect) ...[
          const SizedBox(height: 16),
          _ConnectSection(
            list: list,
            currentUserId: currentUserId,
            isHost: isHost,
            ref: ref,
          ),
        ] else if ((isMember || isHost) && !canConnect) ...[
          const SizedBox(height: 12),
          _LockedFeatureHint(
            icon: Iconsax.link_2,
            label: 'Connect',
            description: 'Exchange social links with members',
            daysRequired: kConnectUnlockDays,
            currentDays: myDays,
          ),
        ],

        // ── Member action tiles (poke / report / strike) ─────────────
        if (isMember || isHost) ...[
          const SizedBox(height: 16),
          ...approved
              .where((m) => m.userId != currentUserId)
              .map(
                (member) => _MemberActionTile(
                  member: member,
                  currentUserId: currentUserId,
                  listId: list.id,
                  isHost: isHost,
                  canPoke: canPoke,
                  ref: ref,
                ),
              ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TimeUnlockBar
// ─────────────────────────────────────────────────────────────────────────────

class _TimeUnlockBar extends StatelessWidget {
  final int daysInRoom;
  const _TimeUnlockBar({required this.daysInRoom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.clock, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Day $daysInRoom in this room',
                style: TextStyle(
                  color: context.col.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _UnlockDot(
                icon: Iconsax.link_2,
                label: 'Connect',
                unlockDay: kConnectUnlockDays,
                currentDay: daysInRoom,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (daysInRoom / kPokeUnlockDays).clamp(0.0, 1.0),
                    backgroundColor: context.col.border,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _UnlockDot(
                icon: Iconsax.finger_cricle,
                label: 'Poke',
                unlockDay: kPokeUnlockDays,
                currentDay: daysInRoom,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnlockDot extends StatelessWidget {
  final IconData icon;
  final String label;
  final int unlockDay;
  final int currentDay;

  const _UnlockDot({
    required this.icon,
    required this.label,
    required this.unlockDay,
    required this.currentDay,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = currentDay >= unlockDay;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: unlocked
                ? AppColors.primary.withValues(alpha: 0.15)
                : context.col.border,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 14,
            color: unlocked ? AppColors.primary : context.col.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          unlocked ? label : 'Day $unlockDay',
          style: TextStyle(
            color: unlocked ? AppColors.primary : context.col.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _LockedFeatureHint
// ─────────────────────────────────────────────────────────────────────────────

class _LockedFeatureHint extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final int daysRequired;
  final int currentDays;

  const _LockedFeatureHint({
    required this.icon,
    required this.label,
    required this.description,
    required this.daysRequired,
    required this.currentDays,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = daysRequired - currentDays;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.col.border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: context.col.textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: context.col.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.col.border,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$daysLeft days left',
              style: TextStyle(
                color: context.col.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ConnectSection — shows members who have opted to share contact
// ─────────────────────────────────────────────────────────────────────────────

class _ConnectSection extends StatelessWidget {
  final BucketListModel list;
  final String currentUserId;
  final bool isHost;
  final WidgetRef ref;

  const _ConnectSection({
    required this.list,
    required this.currentUserId,
    required this.isHost,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final myMember = list.approvedMembers.cast<BucketMember?>().firstWhere(
      (m) => m?.userId == currentUserId,
      orElse: () => null,
    );
    final myContactShared = myMember?.contactShared ?? false;
    final sharingMembers = list.approvedMembers
        .where((m) => m.contactShared && m.userId != currentUserId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Iconsax.link_2, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Connect',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => ref
                  .read(bucketListControllerProvider.notifier)
                  .setContactShared(
                    listId: list.id,
                    userId: currentUserId,
                    shared: !myContactShared,
                  ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: myContactShared
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : context.col.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: myContactShared
                        ? AppColors.primary.withValues(alpha: 0.4)
                        : context.col.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      myContactShared ? Iconsax.eye : Iconsax.eye_slash,
                      size: 12,
                      color: myContactShared
                          ? AppColors.primary
                          : context.col.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      myContactShared ? 'Sharing' : 'Share mine',
                      style: TextStyle(
                        color: myContactShared
                            ? AppColors.primary
                            : context.col.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (sharingMembers.isEmpty)
          Text(
            'No members are sharing their contact yet. Be the first!',
            style: TextStyle(
              color: context.col.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          )
        else
          ...sharingMembers.map(
            (m) => _ConnectMemberTile(member: m),
          ),
      ],
    );
  }
}

class _ConnectMemberTile extends StatelessWidget {
  final BucketMember member;
  const _ConnectMemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: member.userPhoto != null
                ? NetworkImage(member.userPhoto!)
                : null,
            child: member.userPhoto == null
                ? Text(
                    member.userName.isNotEmpty
                        ? member.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userName,
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Member · ${member.daysInRoom(DateTime.now())} days in room',
                  style: TextStyle(
                    color: context.col.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Iconsax.link_2, size: 16, color: AppColors.primary),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MemberActionTile — poke / report / strike per member
// ─────────────────────────────────────────────────────────────────────────────

class _MemberActionTile extends ConsumerWidget {
  final BucketMember member;
  final String currentUserId;
  final String listId;
  final bool isHost;
  final bool canPoke;
  final WidgetRef ref;

  const _MemberActionTile({
    required this.member,
    required this.currentUserId,
    required this.listId,
    required this.isHost,
    required this.canPoke,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final now = DateTime.now();
    final days = member.daysInRoom(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.col.surfaceElevated,
                backgroundImage: member.userPhoto != null
                    ? NetworkImage(member.userPhoto!)
                    : null,
                child: member.userPhoto == null
                    ? Text(
                        member.userName.isNotEmpty
                            ? member.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
              if (member.isHost)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.col.bg, width: 1),
                    ),
                    child: Icon(Iconsax.crown, size: 8, color: context.col.bg),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userName,
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Iconsax.clock, size: 11, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(
                      '$days day${days != 1 ? 's' : ''} in room',
                      style: TextStyle(
                        color: context.col.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (member.strikes > 0) ...[
                      const SizedBox(width: 8),
                      ...List.generate(
                        member.strikes,
                        (_) => const Padding(
                          padding: EdgeInsets.only(right: 2),
                          child: Icon(
                            Iconsax.warning_2,
                            size: 11,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canPoke)
                _IconActionButton(
                  icon: Iconsax.finger_cricle,
                  tooltip: 'Poke',
                  color: AppColors.primary,
                  onTap: () => _poke(context, widgetRef),
                ),
              const SizedBox(width: 6),
              _IconActionButton(
                icon: Iconsax.flag,
                tooltip: 'Report',
                color: AppColors.warning,
                onTap: () => _report(context, widgetRef),
              ),
              if (isHost) ...[
                const SizedBox(width: 6),
                _IconActionButton(
                  icon: Iconsax.warning_2,
                  tooltip: 'Strike',
                  color: AppColors.error,
                  onTap: () => _strike(context, widgetRef),
                ),
                const SizedBox(width: 6),
                _IconActionButton(
                  icon: Iconsax.user_remove,
                  tooltip: 'Remove',
                  color: AppColors.error,
                  onTap: () => _remove(context, widgetRef),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _poke(BuildContext context, WidgetRef ref) async {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    final err = await ref.read(bucketListControllerProvider.notifier).poke(
      listId: listId,
      fromId: me.id,
      fromName: me.displayName,
      toId: member.userId,
      toName: member.userName,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err ?? 'You poked ${member.userName}!',
        ),
        backgroundColor: err != null ? AppColors.error : AppColors.primary,
      ),
    );
  }

  void _report(BuildContext context, WidgetRef ref) {
    final me = ref.read(currentUserProvider);
    if (me == null) return;
    showDialog(
      context: context,
      builder: (_) => _ReportDialog(
        targetName: member.userName,
        onConfirm: (reason) => ref
            .read(bucketListControllerProvider.notifier)
            .reportMember(
              listId: listId,
              reporterId: me.id,
              reporterName: me.displayName,
              targetId: member.userId,
              targetName: member.userName,
              reason: reason,
            ),
      ),
    );
  }

  void _strike(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surface,
        title: Row(
          children: [
            const Icon(Iconsax.warning_2, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Issue Strike?',
              style: TextStyle(color: context.col.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Issue a strike to ${member.userName}? '
          '${member.strikes + 1 >= 3 ? 'This is the 3rd strike — they will be automatically removed.' : '${2 - member.strikes} strike(s) will remain before auto-removal.'}',
          style: TextStyle(color: context.col.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: context.col.textSecondary)),
          ),
          FilledButton.icon(
            icon: const Icon(Iconsax.warning_2, size: 16),
            label: const Text('Strike'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(bucketListControllerProvider.notifier).strikeMember(
                listId: listId,
                targetUserId: member.userId,
              );
            },
          ),
        ],
      ),
    );
  }

  void _remove(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surface,
        title: Row(
          children: [
            const Icon(Iconsax.user_remove, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text('Remove Member?', style: TextStyle(color: context.col.textPrimary)),
          ],
        ),
        content: Text(
          'Remove ${member.userName} from this room? They will not be able to rejoin.',
          style: TextStyle(color: context.col.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: context.col.textSecondary)),
          ),
          FilledButton.icon(
            icon: const Icon(Iconsax.user_remove, size: 16),
            label: const Text('Remove'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(bucketListControllerProvider.notifier).removeMember(
                listId: listId,
                targetUserId: member.userId,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ReportDialog
// ─────────────────────────────────────────────────────────────────────────────

class _ReportDialog extends StatefulWidget {
  final String targetName;
  final Future<void> Function(String reason) onConfirm;

  const _ReportDialog({required this.targetName, required this.onConfirm});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _reasons = [
    'Inappropriate behaviour',
    'Spam or fake activity',
    'Harassment',
    'Sharing harmful content',
    'Other',
  ];
  String? _selected;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.col.surface,
      title: Row(
        children: [
          const Icon(Iconsax.flag, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Text(
            'Report ${widget.targetName}',
            style: TextStyle(color: context.col.textPrimary),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _reasons
            .map(
              (r) => RadioListTile<String>(
                title: Text(r, style: TextStyle(color: context.col.textPrimary, fontSize: 13)),
                value: r,
                // ignore: deprecated_member_use
                groupValue: _selected,
                activeColor: AppColors.primary,
                dense: true,
                // ignore: deprecated_member_use
                onChanged: (v) => setState(() => _selected = v),
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: context.col.textSecondary)),
        ),
        FilledButton.icon(
          icon: _submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Iconsax.send_1, size: 14),
          label: const Text('Submit'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
          onPressed: _selected == null || _submitting
              ? null
              : () async {
                  setState(() => _submitting = true);
                  await widget.onConfirm(_selected!);
                  if (context.mounted) Navigator.of(context).pop();
                },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MembersRow (compact avatar row, used inside _RoomMembersSection)
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
                        backgroundColor: context.col.surfaceElevated,
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
                              border: Border.all(
                                color: context.col.bg,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Iconsax.crown,
                              size: 8,
                              color: context.col.bg,
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
            backgroundColor: context.col.surfaceElevated,
            child: Text(
              '+${approved.length - 6}',
              style: TextStyle(color: context.col.textSecondary, fontSize: 10),
            ),
          ),
        const SizedBox(width: 8),
        Text(
          '${approved.length} member${approved.length != 1 ? 's' : ''}',
          style: TextStyle(color: context.col.textSecondary, fontSize: 12),
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
              : context.col.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isChecked
                ? AppColors.primary.withValues(alpha: 0.4)
                : context.col.border,
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
                    : context.col.surfaceElevated,
                border: Border.all(
                  color: item.isChecked
                      ? AppColors.primary
                      : context.col.border,
                  width: 2,
                ),
              ),
              child: item.isChecked
                  ? Icon(Icons.check_rounded, size: 16, color: context.col.bg)
                  : null,
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              color: item.isChecked
                  ? context.col.textSecondary
                  : context.col.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              decoration: item.isChecked ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(item.category.icon, size: 11, color: context.col.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    item.displayCategory,
                    style: TextStyle(color: context.col.textMuted, fontSize: 11),
                  ),
                ],
              ),
              if (item.isChecked && item.checkedByUserName != null)
                Row(
                  children: [
                    const Icon(Iconsax.tick_circle, size: 11, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(
                      'by ${item.checkedByUserName}',
                      style: const TextStyle(color: AppColors.primary, fontSize: 11),
                    ),
                  ],
                ),
              if (item.note != null && item.note!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(Iconsax.note_text, size: 11, color: context.col.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          item.note!,
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
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
                    errorBuilder: (_, _, _) => const SizedBox(),
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
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.location, size: 26, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(
            'No tasks yet',
            style: TextStyle(
              color: context.col.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add places, activities, and more to this room!',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.col.textSecondary, fontSize: 12),
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
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.cup, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Challenge Complete!',
            style: TextStyle(
              color: context.col.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your group completed every task in this room!',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.col.textSecondary, fontSize: 13),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Iconsax.flash, size: 16, color: AppColors.accent),
                const SizedBox(width: 6),
                Text(
                  '+$xpReward XP Earned!',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
