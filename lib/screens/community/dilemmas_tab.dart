import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';
import '../../widgets/shared_widgets.dart';

// DilemmasTab
class DilemmasTab extends ConsumerStatefulWidget {
  const DilemmasTab({super.key});

  @override
  ConsumerState<DilemmasTab> createState() => _DilemmasTabState();
}

class _DilemmasTabState extends ConsumerState<DilemmasTab> {
  void _openCreate() {
    context.push(AppRoutes.createDilemma);
  }

  @override
  Widget build(BuildContext context) {
    final dilemmasAsync = ref.watch(dilemmasStreamProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: context.col.bg,
      body: dilemmasAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'Could not load dilemmas',
                style: TextStyle(color: context.col.textSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(dilemmasStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (dilemmas) {
          if (dilemmas.isEmpty) {
            return EmptyState(
              emoji: '\u{1F914}',
              title: 'No dilemmas yet',
              subtitle: 'Be the first to post a travel dilemma!',
              action: user != null
                  ? ElevatedButton.icon(
                      onPressed: _openCreate,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Post a Dilemma'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: context.col.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : null,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: dilemmas.length,
            itemBuilder: (_, i) =>
                _DilemmaCard(
                      dilemma: dilemmas[i],
                      currentUserId: user?.id,
                      index: i,
                    )
                    .animate(delay: Duration(milliseconds: i * 50))
                    .fadeIn()
                    .slideY(begin: 0.06, curve: Curves.easeOut),
          );
        },
      ),
      floatingActionButton: user != null
          ? FloatingActionButton.extended(
              heroTag: 'create_dilemma',
              onPressed: _openCreate,
              backgroundColor: AppColors.primary,
              foregroundColor: context.col.bg,
              icon: const Icon(Icons.how_to_vote_outlined),
              label: const Text(
                'New Dilemma',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
    );
  }
}

// _DilemmaCard
class _DilemmaCard extends ConsumerStatefulWidget {
  final Dilemma dilemma;
  final String? currentUserId;
  final int index;

  const _DilemmaCard({
    required this.dilemma,
    required this.currentUserId,
    required this.index,
  });

  @override
  ConsumerState<_DilemmaCard> createState() => _DilemmaCardState();
}

class _DilemmaCardState extends ConsumerState<_DilemmaCard> {
  bool _voting = false;

  Future<void> _vote(String option) async {
    if (_voting) return;
    final uid = widget.currentUserId;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to vote'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    setState(() => _voting = true);
    await ref
        .read(dilemmasControllerProvider.notifier)
        .vote(widget.dilemma.id, option, uid);
    if (mounted) setState(() => _voting = false);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surface,
        title: const Text('Delete Dilemma?'),
        content: Text(
          'This will permanently remove the dilemma and all votes.',
          style: TextStyle(color: context.col.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref
          .read(dilemmasControllerProvider.notifier)
          .deleteDilemma(widget.dilemma.id);
    }
  }

  void _showMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Delete Dilemma',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _delete();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.close_rounded,
                color: context.col.textSecondary,
              ),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _countdown(DateTime exp) {
    final diff = exp.difference(DateTime.now());
    if (diff.isNegative) return 'Ended';
    if (diff.inDays > 0) return '${diff.inDays}d left';
    if (diff.inHours > 0) return '${diff.inHours}h left';
    return '${diff.inMinutes}m left';
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dilemma;
    final uid = widget.currentUserId;
    final myVote = uid != null ? d.userVote(uid) : null;
    final voted = myVote != null;
    final expired = d.isExpired;
    final closed = !d.isActive;
    final isAuthor = uid == d.authorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundImage:
                      (d.authorPhoto != null && d.authorPhoto!.isNotEmpty)
                      ? NetworkImage(d.authorPhoto!)
                      : null,
                  child: (d.authorPhoto == null || d.authorPhoto!.isEmpty)
                      ? Text(
                          d.authorName.isNotEmpty
                              ? d.authorName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
                        d.authorName,
                        style: TextStyle(
                          color: context.col.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            _timeAgo(d.createdAt),
                            style: TextStyle(
                              color: context.col.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          if (d.expiresAt != null) ...[
                            Text(
                              ' \u00b7 ',
                              style: TextStyle(color: context.col.textMuted),
                            ),
                            Icon(
                              expired
                                  ? Icons.timer_off_outlined
                                  : Icons.timer_outlined,
                              size: 12,
                              color: expired
                                  ? AppColors.error
                                  : context.col.textMuted,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              expired ? 'Ended' : _countdown(d.expiresAt!),
                              style: TextStyle(
                                color: expired
                                    ? AppColors.error
                                    : context.col.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (closed)
                  _StatusBadge(label: 'CLOSED', color: context.col.textMuted)
                else
                  _StatusBadge(label: 'LIVE', color: AppColors.success),
                if (isAuthor) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    icon: Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: context.col.textMuted,
                    ),
                    onPressed: _showMenu,
                  ),
                ],
              ],
            ),
          ),

          // Question
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              d.question,
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),

          // VS Cards
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _VoteCard(
                    option: d.optionA,
                    side: 'A',
                    percent: d.percentA,
                    votes: d.votesA.length,
                    isMyVote: myVote == 'A',
                    voted: voted || closed,
                    color: AppColors.secondary,
                    onTap: closed ? null : () => _vote('A'),
                    loading: _voting,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const SizedBox(height: 32),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.col.surfaceElevated,
                        border: Border.all(color: context.col.border),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: context.col.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _VoteCard(
                    option: d.optionB,
                    side: 'B',
                    percent: d.percentB,
                    votes: d.votesB.length,
                    isMyVote: myVote == 'B',
                    voted: voted || closed,
                    color: AppColors.warning,
                    onTap: closed ? null : () => _vote('B'),
                    loading: _voting,
                  ),
                ),
              ],
            ),
          ),

          // Footer
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.col.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.how_to_vote_outlined,
                  size: 14,
                  color: context.col.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  d.totalVotes == 0
                      ? 'Be the first to vote!'
                      : '${d.totalVotes} vote${d.totalVotes == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: context.col.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (voted && !closed) ...[
                  const Spacer(),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Voted ${myVote == 'A' ? d.optionA.name : d.optionB.name}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
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
}

// _StatusBadge
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// _VoteCard
class _VoteCard extends StatelessWidget {
  final DilemmaOption option;
  final String side;
  final double percent;
  final int votes;
  final bool isMyVote;
  final bool voted;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  const _VoteCard({
    required this.option,
    required this.side,
    required this.percent,
    required this.votes,
    required this.isMyVote,
    required this.voted,
    required this.color,
    required this.onTap,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMyVote ? color : context.col.border,
            width: isMyVote ? 2 : 1,
          ),
          color: isMyVote
              ? color.withValues(alpha: 0.08)
              : context.col.surfaceElevated,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place image
            SizedBox(
              height: 90,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (option.imageUrl != null && option.imageUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: option.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, error, child) =>
                          _PlaceBg(color: color),
                    )
                  else
                    _PlaceBg(color: color),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Percent overlay after voting
                  if (voted)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.25),
                        alignment: Alignment.center,
                        child: Text(
                          '${(percent * 100).round()}%',
                          style: TextStyle(
                            color: isMyVote ? color : Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Checkmark for my vote
                  if (isMyVote)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // Side label A / B
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        side,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Place info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (option.category != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _catLabel(option.category!),
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (option.district != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      option.district!,
                      style: TextStyle(
                        color: context.col.textMuted,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Progress bar after voting
                  if (voted) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: percent),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, v, child) => LinearProgressIndicator(
                          value: v,
                          backgroundColor: context.col.border,
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$votes vote${votes == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: isMyVote ? color : context.col.textMuted,
                        fontSize: 10,
                        fontWeight: isMyVote
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                  // Vote button before voting
                  if (!voted && onTap != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      alignment: Alignment.center,
                      child: loading
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: color,
                              ),
                            )
                          : Text(
                              'Vote',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _catLabel(String cat) {
    switch (cat) {
      case 'cafe':
        return '\u2615 Caf\u00e9';
      case 'restaurant':
        return '\u{1F37D}\uFE0F Restaurant';
      case 'hotel':
        return '\u{1F3E8} Hotel';
      case 'homestay':
        return '\u{1F3E0} Homestay';
      default:
        return '\u26F0\uFE0F Spot';
    }
  }
}

class _PlaceBg extends StatelessWidget {
  final Color color;
  const _PlaceBg({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Icon(Icons.place_rounded, color: color, size: 32),
    );
  }
}
