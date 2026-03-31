import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dare_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dare_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DareNotificationsScreen — shows pending join requests for your dares
// ─────────────────────────────────────────────────────────────────────────────

class DareNotificationsScreen extends ConsumerWidget {
  const DareNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        backgroundColor: context.col.bg,
        appBar: AppBar(
          backgroundColor: context.col.bg,
          iconTheme: IconThemeData(color: context.col.textPrimary),
          title: Text(
            'Notifications',
            style: TextStyle(
              color: context.col.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Center(
          child: Text(
            'Sign in to see notifications',
            style: TextStyle(color: context.col.textSecondary),
          ),
        ),
      );
    }

    final async = ref.watch(pendingJoinRequestsProvider(user.id));

    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.col.textPrimary),
        title: Row(
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                color: context.col.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            async.when(
              data: (items) => items.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: context.col.border),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Could not load notifications',
                style: TextStyle(color: context.col.textSecondary),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: context.col.surfaceElevated,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.notification,
                      size: 36,
                      color: context.col.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join requests for your dares will appear here',
                    style: TextStyle(
                      color: context.col.textMuted,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _JoinRequestTile(
                dare: item.dare,
                requester: item.requester,
                onApprove: () => ref
                    .read(dareControllerProvider.notifier)
                    .approveJoin(
                      dareId: item.dare.id,
                      userId: item.requester.userId,
                    ),
                onDecline: () => ref
                    .read(dareControllerProvider.notifier)
                    .declineJoin(
                      dareId: item.dare.id,
                      userId: item.requester.userId,
                    ),
                onViewDare: () =>
                    context.push(AppRoutes.darePath(item.dare.id)),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _JoinRequestTile
// ─────────────────────────────────────────────────────────────────────────────

class _JoinRequestTile extends StatefulWidget {
  final DareModel dare;
  final DareMember requester;
  final VoidCallback onApprove;
  final VoidCallback onDecline;
  final VoidCallback onViewDare;

  const _JoinRequestTile({
    required this.dare,
    required this.requester,
    required this.onApprove,
    required this.onDecline,
    required this.onViewDare,
  });

  @override
  State<_JoinRequestTile> createState() => _JoinRequestTileState();
}

class _JoinRequestTileState extends State<_JoinRequestTile> {
  bool _actioning = false;

  Future<void> _act(VoidCallback fn) async {
    setState(() => _actioning = true);
    fn();
    // The stream will update and remove this tile; no need to reset
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dare title row ───────────────────────────────────────────
          GestureDetector(
            onTap: widget.onViewDare,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.dare.title,
                    style: TextStyle(
                      color: context.col.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 13,
                  color: context.col.textMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── User info + action buttons ───────────────────────────────
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withAlpha(40),
                backgroundImage: widget.requester.userPhoto != null
                    ? CachedNetworkImageProvider(widget.requester.userPhoto!)
                    : null,
                child: widget.requester.userPhoto == null
                    ? Text(
                        widget.requester.userName.isNotEmpty
                            ? widget.requester.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Name + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.requester.userName,
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Wants to join this dare',
                      style: TextStyle(
                        color: context.col.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Action buttons
              if (_actioning)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else ...[
                // Approve
                _ActionBtn(
                  icon: Iconsax.tick_circle,
                  color: AppColors.success,
                  tooltip: 'Approve',
                  onTap: () => _act(widget.onApprove),
                ),
                const SizedBox(width: 8),
                // Decline
                _ActionBtn(
                  icon: Iconsax.close_circle,
                  color: AppColors.error,
                  tooltip: 'Decline',
                  onTap: () => _act(widget.onDecline),
                ),
              ],
            ],
          ),

          // ── Dare category/visibility pills ───────────────────────────
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: widget.dare.category.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.dare.category.icon,
                      size: 11,
                      color: widget.dare.category.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.dare.displayCategory,
                      style: TextStyle(
                        color: widget.dare.category.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: context.col.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.people,
                      size: 11,
                      color: context.col.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.dare.participantCount}/${widget.dare.maxParticipants} members',
                      style: TextStyle(
                        color: context.col.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            shape: BoxShape.circle,
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
