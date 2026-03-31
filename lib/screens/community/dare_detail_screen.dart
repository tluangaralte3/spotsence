import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/dare_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dare_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DareDetailScreen — live-streaming dare detail view
// ─────────────────────────────────────────────────────────────────────────────

class DareDetailScreen extends ConsumerWidget {
  final String dareId;
  const DareDetailScreen({super.key, required this.dareId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dareDetailProvider(dareId));
    return async.when(
      loading: () => Scaffold(
        backgroundColor: context.col.bg,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.col.bg,
        body: Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: context.col.textPrimary),
          ),
        ),
      ),
      data: (dare) {
        if (dare == null) {
          return Scaffold(
            backgroundColor: context.col.bg,
            body: Center(
              child: Text(
                'Dare not found',
                style: TextStyle(color: context.col.textPrimary),
              ),
            ),
          );
        }
        final user = ref.watch(currentUserProvider);
        return _DareDetailBody(
          dare: dare,
          currentUserId: user?.id ?? '',
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DareDetailBody
// ─────────────────────────────────────────────────────────────────────────────

class _DareDetailBody extends ConsumerWidget {
  final DareModel dare;
  final String currentUserId;

  const _DareDetailBody({
    required this.dare,
    required this.currentUserId,
  });

  bool get _isCreator => dare.isCreator(currentUserId);
  bool get _isMember => dare.isParticipant(currentUserId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRemoved = dare.isRemoved(currentUserId);
    if (isRemoved) {
      return Scaffold(
        backgroundColor: context.col.bg,
        appBar: AppBar(backgroundColor: context.col.bg),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.slash, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'You have been removed from this dare',
                style:
                    TextStyle(color: context.col.textSecondary, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.col.bg,
      body: CustomScrollView(
        slivers: [
          _DareAppBar(dare: dare, isCreator: _isCreator, ref: ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & description
                  Text(
                    dare.title,
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dare.description,
                    style: TextStyle(
                      color: context.col.textSecondary,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),

                  // Category + visibility
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _CategoryPill(dare.category),
                      const SizedBox(width: 8),
                      _VisibilityPill(dare.visibility),
                      if (dare.deadline != null) ...[
                        const SizedBox(width: 8),
                        _DeadlinePill(dare.deadline!, dare.isExpired),
                      ],
                    ],
                  ),

                  // Tags
                  if (dare.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: dare.tags
                          .map(
                            (t) => Chip(
                              label: Text('#$t'),
                              labelStyle: TextStyle(
                                color: context.col.textSecondary,
                                fontSize: 12,
                              ),
                              backgroundColor: context.col.surfaceElevated,
                              side: BorderSide.none,
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Join Code (creator or member only)
          if (_isCreator || _isMember)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _JoinCodeCard(dare: dare),
              ),
            ),

          // Pending requests (creator only)
          if (_isCreator && dare.joinRequests.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _PendingRequestsCard(
                  dare: dare,
                  onApprove: (uid) => ref
                      .read(dareControllerProvider.notifier)
                      .approveJoin(dareId: dare.id, userId: uid),
                  onDecline: (uid) => ref
                      .read(dareControllerProvider.notifier)
                      .declineJoin(dareId: dare.id, userId: uid),
                ),
              ),
            ),

          // Stats card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _StatsCard(dare: dare),
            ),
          ),

          // Proof submissions (creator view)
          if (_isCreator)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _ProofReviewCard(dare: dare, ref: ref),
              ),
            ),

          // Challenges section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Challenges',
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${dare.challenges.length}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_isCreator)
                    TextButton.icon(
                      onPressed: () => context.push(
                        AppRoutes.addDareChallengePath(dare.id),
                      ),
                      icon: const Icon(Iconsax.add_circle, size: 16),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Challenges list
          if (dare.challenges.isEmpty)
            SliverToBoxAdapter(
              child: _EmptyChallenges(isCreator: _isCreator, dare: dare),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final challenge = dare.challenges[i];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _ChallengeTile(
                      challenge: challenge,
                      dare: dare,
                      currentUserId: currentUserId,
                      isMember: _isMember,
                      isCreator: _isCreator,
                      ref: ref,
                    ),
                  );
                },
                childCount: dare.challenges.length,
              ),
            ),

          // Members section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _MembersSection(
                dare: dare,
                currentUserId: currentUserId,
                isCreator: _isCreator,
                ref: ref,
              ),
            ),
          ),

          // Action button (join / leave)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              child: _ActionButton(
                dare: dare,
                currentUserId: currentUserId,
                isCreator: _isCreator,
                isMember: _isMember,
                ref: ref,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DareAppBar
// ─────────────────────────────────────────────────────────────────────────────

class _DareAppBar extends StatelessWidget {
  final DareModel dare;
  final bool isCreator;
  final WidgetRef ref;

  const _DareAppBar({
    required this.dare,
    required this.isCreator,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: context.col.bg,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
        ),
        onPressed: () => context.pop(),
      ),
      actions: [
        if (isCreator)
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.more,
                color: Colors.white,
                size: 18,
              ),
            ),
            color: context.col.surface,
            onSelected: (action) => _onHostMenu(context, ref, action),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Iconsax.edit, size: 16, color: context.col.textPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Edit Dare',
                      style: TextStyle(color: context.col.textPrimary),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: const [
                    Icon(Iconsax.trash, size: 16, color: AppColors.error),
                    SizedBox(width: 8),
                    Text(
                      'Delete Dare',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            dare.bannerUrl != null && dare.bannerUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: dare.bannerUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.bg),
                    errorWidget: (_, __, ___) =>
                        Container(color: context.col.surfaceElevated),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          dare.category.color.withAlpha(180),
                          AppColors.bg,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withAlpha(160)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onHostMenu(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        context.push(AppRoutes.editDarePath(dare.id));
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: context.col.surface,
            title: Text(
              'Delete Dare',
              style: TextStyle(color: context.col.textPrimary),
            ),
            content: Text(
              'Are you sure you want to delete "${dare.title}"? This cannot be undone.',
              style: TextStyle(color: context.col.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: context.col.textSecondary),
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(dareControllerProvider.notifier).delete(dare.id);
                  context.pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        break;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _JoinCodeCard
// ─────────────────────────────────────────────────────────────────────────────

class _JoinCodeCard extends StatelessWidget {
  final DareModel dare;
  const _JoinCodeCard({required this.dare});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.link, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join Code',
                style: TextStyle(
                  color: context.col.textMuted,
                  fontSize: 11,
                ),
              ),
              Text(
                dare.joinCode,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Iconsax.copy, size: 18),
            color: context.col.textSecondary,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: dare.joinCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Join code copied!'),
                  behavior: SnackBarBehavior.floating,
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
// _PendingRequestsCard
// ─────────────────────────────────────────────────────────────────────────────

class _PendingRequestsCard extends StatelessWidget {
  final DareModel dare;
  final void Function(String uid) onApprove;
  final void Function(String uid) onDecline;

  const _PendingRequestsCard({
    required this.dare,
    required this.onApprove,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.clock, size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Text(
                '${dare.joinRequests.length} Join Request(s)',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...dare.joinRequests.map(
            (req) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withAlpha(30),
                    backgroundImage:
                        req.userPhoto != null
                            ? CachedNetworkImageProvider(req.userPhoto!)
                            : null,
                    child: req.userPhoto == null
                        ? Text(
                            req.userName.isNotEmpty
                                ? req.userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(color: AppColors.primary),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      req.userName,
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.tick_circle, color: AppColors.success),
                    onPressed: () => onApprove(req.userId),
                    tooltip: 'Approve',
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle, color: AppColors.error),
                    onPressed: () => onDecline(req.userId),
                    tooltip: 'Decline',
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
// _StatsCard
// ─────────────────────────────────────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final DareModel dare;
  const _StatsCard({required this.dare});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        children: [
          _StatItem(
            icon: Iconsax.flag,
            value: '${dare.challenges.length}',
            label: 'Challenges',
            color: dare.category.color,
          ),
          _Divider(),
          _StatItem(
            icon: Iconsax.people,
            value: '${dare.participantCount}/${dare.maxParticipants}',
            label: 'Members',
            color: AppColors.info,
          ),
          _Divider(),
          _StatItem(
            icon: Iconsax.cup,
            value: '${dare.xpReward} XP',
            label: 'Reward',
            color: AppColors.accent,
          ),
          _Divider(),
          _StatItem(
            icon: Iconsax.medal_star,
            value: dare.requiresProof ? 'Yes' : 'No',
            label: 'Proof req.',
            color:
                dare.requiresProof ? AppColors.success : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 40,
    color: context.col.border,
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: context.col.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(color: context.col.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProofReviewCard — creator reviews submitted proofs
// ─────────────────────────────────────────────────────────────────────────────

class _ProofReviewCard extends ConsumerWidget {
  final DareModel dare;
  final WidgetRef ref;
  const _ProofReviewCard({required this.dare, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final proofsAsync = widgetRef.watch(dareProofsProvider(dare.id));

    return proofsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (proofs) {
        final pending = proofs.where(
          (p) => p.status == ProofStatus.pending,
        ).toList();
        if (pending.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.info.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.info.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Iconsax.document_text,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${pending.length} Proof(s) to Review',
                    style: const TextStyle(
                      color: AppColors.info,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...pending.take(3).map(
                (proof) => _ProofReviewTile(
                  proof: proof,
                  dare: dare,
                  ref: widgetRef,
                ),
              ),
              if (pending.length > 3)
                TextButton(
                  onPressed: () {
                    // Navigate to full proof list
                  },
                  child: Text(
                    'View all ${pending.length} pending proofs',
                    style: const TextStyle(color: AppColors.info),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProofReviewTile extends StatelessWidget {
  final ProofSubmission proof;
  final DareModel dare;
  final WidgetRef ref;

  const _ProofReviewTile({
    required this.proof,
    required this.dare,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final challenge = dare.challenges
        .where((c) => c.id == proof.challengeId)
        .firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withAlpha(30),
                backgroundImage:
                    proof.userPhoto != null
                        ? CachedNetworkImageProvider(proof.userPhoto!)
                        : null,
                child: proof.userPhoto == null
                    ? Text(
                        proof.userName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
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
                      proof.userName,
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (challenge != null)
                      Text(
                        challenge.title,
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
          if (proof.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: proof.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: proof.imageUrls[i],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref
                      .read(dareControllerProvider.notifier)
                      .reviewProof(
                        dareId: dare.id,
                        proofId: proof.id,
                        status: ProofStatus.rejected,
                        participantUserId: proof.userId,
                      ),
                  icon: const Icon(
                    Iconsax.close_circle,
                    size: 14,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Reject',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => ref
                      .read(dareControllerProvider.notifier)
                      .reviewProof(
                        dareId: dare.id,
                        proofId: proof.id,
                        status: ProofStatus.approved,
                        participantUserId: proof.userId,
                        challengeTitle: challenge?.title ?? 'Challenge',
                        dareTitle: dare.title,
                        medalType: challenge?.medalType ?? MedalType.bronze,
                        xpReward: challenge?.xpReward ?? 100,
                        bannerUrl: dare.bannerUrl,
                        challengeId: proof.challengeId,
                      ),
                  icon: const Icon(Iconsax.tick_circle, size: 14),
                  label: const Text('Approve', style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// _ChallengeTile
// ─────────────────────────────────────────────────────────────────────────────

class _ChallengeTile extends ConsumerWidget {
  final DareChallenge challenge;
  final DareModel dare;
  final String currentUserId;
  final bool isMember;
  final bool isCreator;
  final WidgetRef ref;

  const _ChallengeTile({
    required this.challenge,
    required this.dare,
    required this.currentUserId,
    required this.isMember,
    required this.isCreator,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    // Check my proof status for this challenge
    final myProofsAsync = widgetRef.watch(
      myDareProofsProvider('${dare.id}|$currentUserId'),
    );
    final myProofForChallenge = myProofsAsync.value
        ?.where((p) => p.challengeId == challenge.id)
        .firstOrNull;

    final proofStatus = myProofForChallenge?.status;
    final isCompleted = proofStatus == ProofStatus.approved;
    final isPending = proofStatus == ProofStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? AppColors.success.withAlpha(60)
              : context.col.border,
        ),
      ),
      child: Column(
        children: [
          // Listing image header — shown for appListing challenges that have one
          if (challenge.type == DareChallengeType.appListing &&
              challenge.imageUrl != null &&
              challenge.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: CachedNetworkImage(
                imageUrl: challenge.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 150,
                  color: context.col.surfaceElevated,
                  child: Center(
                    child: Icon(
                      challenge.category.icon,
                      size: 36,
                      color: challenge.category.color.withAlpha(80),
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          // Challenge header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: challenge.category.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    challenge.category.icon,
                    color: challenge.category.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              challenge.title,
                              style: TextStyle(
                                color: context.col.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          // Challenge type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: challenge.type == DareChallengeType.appListing
                                  ? AppColors.info.withAlpha(30)
                                  : AppColors.primary.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              challenge.type == DareChallengeType.appListing
                                  ? 'In-App'
                                  : 'Custom',
                              style: TextStyle(
                                color: challenge.type ==
                                        DareChallengeType.appListing
                                    ? AppColors.info
                                    : AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (challenge.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          challenge.description!,
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Rewards row
                      Row(
                        children: [
                          _RewardBadge(
                            icon: Iconsax.cup,
                            label: '${challenge.xpReward} XP',
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 6),
                          _RewardBadge(
                            icon: challenge.medalType.icon,
                            label: challenge.medalType.label,
                            color: challenge.medalType.color,
                          ),
                          if (challenge.requiresProof) ...[
                            const SizedBox(width: 6),
                            _RewardBadge(
                              icon: Iconsax.image,
                              label: 'Proof req.',
                              color: AppColors.info,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Proof status for current member
          if ((isMember || isCreator) && proofStatus != null)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success.withAlpha(20)
                    : isPending
                        ? AppColors.warning.withAlpha(20)
                        : AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isCompleted
                        ? Iconsax.tick_circle
                        : isPending
                            ? Iconsax.clock
                            : Iconsax.close_circle,
                    size: 14,
                    color: isCompleted
                        ? AppColors.success
                        : isPending
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCompleted
                        ? 'Completed — reward earned!'
                        : isPending
                            ? 'Proof submitted — awaiting review'
                            : 'Proof rejected — please resubmit',
                    style: TextStyle(
                      color: isCompleted
                          ? AppColors.success
                          : isPending
                              ? AppColors.warning
                              : AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Submit proof button
          if (isMember && !isCreator && !isCompleted && !isPending) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.dareProofPath(dare.id, challenge.id),
                  ),
                  icon: const Icon(Iconsax.image, size: 16),
                  label: const Text('Submit Proof'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Custom instructions
          if (challenge.type == DareChallengeType.custom &&
              challenge.customInstructions != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.col.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.note_text,
                    size: 14,
                    color: context.col.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      challenge.customInstructions!,
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // App listing location
          if (challenge.type == DareChallengeType.appListing &&
              challenge.listingLocation != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Icon(
                    Iconsax.location,
                    size: 13,
                    color: context.col.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    challenge.listingLocation!,
                    style: TextStyle(
                      color: context.col.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _RewardBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MembersSection
// ─────────────────────────────────────────────────────────────────────────────

class _MembersSection extends StatelessWidget {
  final DareModel dare;
  final String currentUserId;
  final bool isCreator;
  final WidgetRef ref;

  const _MembersSection({
    required this.dare,
    required this.currentUserId,
    required this.isCreator,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final members = dare.approvedMembers;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.people, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Participants (${members.length}/${dare.maxParticipants})',
                style: TextStyle(
                  color: context.col.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: members.map((m) => _MemberAvatar(member: m, dare: dare, isCreator: isCreator, ref: ref)).toList(),
          ),
          if (dare.isFull) ...[
            const SizedBox(height: 10),
            Text(
              'Dare is full',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final DareMember member;
  final DareModel dare;
  final bool isCreator;
  final WidgetRef ref;

  const _MemberAvatar({
    required this.member,
    required this.dare,
    required this.isCreator,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: isCreator && !member.isCreator
          ? () => _showOptions(context)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withAlpha(30),
                backgroundImage:
                    member.userPhoto != null
                        ? CachedNetworkImageProvider(member.userPhoto!)
                        : null,
                child: member.userPhoto == null
                    ? Text(
                        member.userName.isNotEmpty
                            ? member.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              if (member.isCreator)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.crown,
                      size: 8,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 56,
            child: Text(
              member.userName,
              style: TextStyle(
                color: context.col.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (member.completedChallenges > 0)
            Text(
              '${member.completedChallenges} done',
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 9,
              ),
            ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.col.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Iconsax.slash, color: AppColors.error),
            title: Text(
              'Remove ${member.userName}',
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(context);
              ref.read(dareControllerProvider.notifier).removeMember(
                dareId: dare.id,
                targetUserId: member.userId,
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionButton — join / leave
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final DareModel dare;
  final String currentUserId;
  final bool isCreator;
  final bool isMember;
  final WidgetRef ref;

  const _ActionButton({
    required this.dare,
    required this.currentUserId,
    required this.isCreator,
    required this.isMember,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    if (isCreator) return const SizedBox.shrink();

    if (isMember) {
      return OutlinedButton(
        onPressed: () => _confirmLeave(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text('Leave Dare'),
      );
    }

    final hasPending = dare.hasPendingRequest(currentUserId);
    if (hasPending) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.warning.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withAlpha(60)),
        ),
        child: const Text(
          'Join request pending...',
          style: TextStyle(
            color: AppColors.warning,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (dare.isFull || dare.isExpired) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.col.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          dare.isExpired ? 'Dare has expired' : 'Dare is full',
          style: TextStyle(color: context.col.textMuted),
        ),
      );
    }

    return FilledButton.icon(
      onPressed: currentUserId.isEmpty
          ? () => context.go(AppRoutes.login)
          : () => _confirmJoin(context),
      icon: Icon(
        dare.visibility == DareVisibility.public
            ? Iconsax.add_circle
            : Iconsax.send_sqaure_2,
      ),
      label: Text(
        dare.visibility == DareVisibility.public ? 'Join Dare' : 'Request to Join',
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bg,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _confirmLeave(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surface,
        title: Text(
          'Leave Dare',
          style: TextStyle(color: context.col.textPrimary),
        ),
        content: Text(
          'Are you sure you want to leave this dare?',
          style: TextStyle(color: context.col.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.col.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(dareControllerProvider.notifier).leave(
                dareId: dare.id,
                userId: currentUserId,
              );
              context.pop();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _confirmJoin(BuildContext context) {
    final isPublic = dare.visibility == DareVisibility.public;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.col.surface,
        title: Text(
          isPublic ? 'Join Dare' : 'Request to Join',
          style: TextStyle(color: context.col.textPrimary),
        ),
        content: Text(
          isPublic
              ? 'You will be added immediately.'
              : 'Your request will be reviewed by the creator.',
          style: TextStyle(color: context.col.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.col.textSecondary),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              final user = ref.read(currentUserProvider);
              if (user == null) return;
              ref.read(dareControllerProvider.notifier).requestJoin(
                dareId: dare.id,
                userId: user.id,
                userName: user.displayName,
                userPhoto: user.photoURL,
                isPublic: isPublic,
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(isPublic ? 'Join' : 'Request'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyChallenges
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyChallenges extends StatelessWidget {
  final bool isCreator;
  final DareModel dare;
  const _EmptyChallenges({required this.isCreator, required this.dare});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        children: [
          Icon(Iconsax.flag, size: 56, color: context.col.textMuted),
          const SizedBox(height: 12),
          Text(
            isCreator
                ? 'Add challenges for participants to complete'
                : 'No challenges added yet',
            style: TextStyle(
              color: context.col.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          if (isCreator) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  context.push(AppRoutes.addDareChallengePath(dare.id)),
              icon: const Icon(Iconsax.add_circle),
              label: const Text('Add First Challenge'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.bg,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill helpers
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  final DareCategory cat;
  const _CategoryPill(this.cat);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cat.color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cat.color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(cat.icon, size: 12, color: cat.color),
          const SizedBox(width: 4),
          Text(
            cat.label,
            style: TextStyle(
              color: cat.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisibilityPill extends StatelessWidget {
  final DareVisibility vis;
  const _VisibilityPill(this.vis);

  @override
  Widget build(BuildContext context) {
    final isPublic = vis == DareVisibility.public;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isPublic
                ? AppColors.success.withAlpha(25)
                : AppColors.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isPublic
                  ? AppColors.success.withAlpha(80)
                  : AppColors.warning.withAlpha(80),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Iconsax.global : Iconsax.lock,
            size: 12,
            color: isPublic ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(
              color: isPublic ? AppColors.success : AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlinePill extends StatelessWidget {
  final DateTime deadline;
  final bool isExpired;
  const _DeadlinePill(this.deadline, this.isExpired);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isExpired
            ? AppColors.error.withAlpha(25)
            : AppColors.info.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired
              ? AppColors.error.withAlpha(80)
              : AppColors.info.withAlpha(80),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Iconsax.timer_pause : Iconsax.timer_1,
            size: 12,
            color: isExpired ? AppColors.error : AppColors.info,
          ),
          const SizedBox(width: 4),
          Text(
            isExpired
                ? 'Expired'
                : '${deadline.day}/${deadline.month}/${deadline.year}',
            style: TextStyle(
              color: isExpired ? AppColors.error : AppColors.info,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
