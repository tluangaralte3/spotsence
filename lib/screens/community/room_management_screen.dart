import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/bucket_list_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bucket_list_models.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RoomManagementScreen — Host control panel for all hosted rooms
// ─────────────────────────────────────────────────────────────────────────────

class RoomManagementScreen extends ConsumerStatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  ConsumerState<RoomManagementScreen> createState() =>
      _RoomManagementScreenState();
}

class _RoomManagementScreenState extends ConsumerState<RoomManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

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
    final authState = ref.watch(authControllerProvider);
    final user = authState.value?.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Rooms')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.people, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'Sign in to manage your rooms',
                style: TextStyle(
                  color: context.col.textSecondary,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final roomsStream = ref.watch(hostedRoomsProvider(user.id));

    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.surface,
        elevation: 0,
        title: Text(
          'My Rooms',
          style: TextStyle(
            color: context.col.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: context.col.textPrimary),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: context.col.textMuted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.element_4, size: 16),
                  SizedBox(width: 6),
                  Text('Rooms'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.notification, size: 16),
                  SizedBox(width: 6),
                  Text('Requests'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: roomsStream.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load rooms',
            style: TextStyle(color: context.col.textMuted),
          ),
        ),
        data: (rooms) => TabBarView(
          controller: _tabs,
          children: [
            _RoomsTab(rooms: rooms, userId: user.id),
            _RequestsTab(rooms: rooms, userId: user.id),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RoomsTab — overview of all hosted rooms
// ─────────────────────────────────────────────────────────────────────────────

class _RoomsTab extends ConsumerWidget {
  final List<BucketListModel> rooms;
  final String userId;

  const _RoomsTab({required this.rooms, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.element_4,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No rooms created yet',
              style: TextStyle(
                color: context.col.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a room from the Community tab',
              style: TextStyle(
                color: context.col.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rooms.length,
      itemBuilder: (_, i) => _RoomOverviewCard(room: rooms[i]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RoomOverviewCard
// ─────────────────────────────────────────────────────────────────────────────

class _RoomOverviewCard extends ConsumerWidget {
  final BucketListModel room;
  const _RoomOverviewCard({required this.room});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = room.joinRequests.length;
    final memberCount = room.approvedMembers.length;
    final checkedCount = room.items.where((i) => i.isChecked).length;
    final totalCount = room.items.length;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.bucketListDetailPath(room.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pendingCount > 0
                ? AppColors.primary.withValues(alpha: 0.4)
                : context.col.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    room.title,
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.notification,
                            size: 11, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '$pendingCount pending',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(Iconsax.arrow_right_3, size: 16, color: context.col.textMuted),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Chip(
                  icon: Iconsax.people,
                  label: '$memberCount member${memberCount != 1 ? 's' : ''}',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Iconsax.tick_circle,
                  label: '$checkedCount/$totalCount tasks',
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: room.visibility == BucketVisibility.public ? Iconsax.global : Iconsax.lock,
                  label: room.visibility == BucketVisibility.public ? 'Public' : 'Private',
                  color: room.visibility == BucketVisibility.public ? AppColors.accent : context.col.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RequestsTab — all pending join requests across rooms
// ─────────────────────────────────────────────────────────────────────────────

class _RequestsTab extends ConsumerWidget {
  final List<BucketListModel> rooms;
  final String userId;

  const _RequestsTab({required this.rooms, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Flatten: (room, pendingMember) pairs
    final pending = [
      for (final room in rooms)
        for (final member in room.joinRequests) (room, member),
    ];

    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.notification,
                size: 34,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No pending requests',
              style: TextStyle(
                color: context.col.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New join requests will appear here',
              style:
                  TextStyle(color: context.col.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (_, i) {
        final (room, member) = pending[i];
        return _RequestCard(room: room, member: member);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RequestCard — approve / decline a single join request
// ─────────────────────────────────────────────────────────────────────────────

class _RequestCard extends ConsumerStatefulWidget {
  final BucketListModel room;
  final BucketMember member;

  const _RequestCard({required this.room, required this.member});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _loading = false;

  Future<void> _approve() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(bucketListControllerProvider.notifier)
          .approveJoin(
            listId: widget.room.id,
            userId: widget.member.userId,
          );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _decline() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(bucketListControllerProvider.notifier)
          .declineJoin(
            listId: widget.room.id,
            userId: widget.member.userId,
          );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage: widget.member.userPhoto != null
                ? NetworkImage(widget.member.userPhoto!)
                : null,
            child: widget.member.userPhoto == null
                ? Text(
                    widget.member.userName.isNotEmpty
                        ? widget.member.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.member.userName,
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Wants to join: ${widget.room.title}',
                  style: TextStyle(
                    color: context.col.textMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _decline,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Iconsax.close_circle,
                      size: 16,
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: _approve,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Iconsax.tick_circle,
                      size: 16,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
