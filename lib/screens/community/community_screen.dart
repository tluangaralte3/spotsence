import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';
import '../../widgets/shared_widgets.dart';
import 'community_map.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Feed'),
            Tab(text: 'Bucket Lists'),
            Tab(text: 'Dilemmas'),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _tabs,
        builder: (context, _) => TabBarView(
          controller: _tabs,
          // Disable swipe on the map tab so pan/zoom gestures reach flutter_map
          physics: _tabs.index == 0
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          children: const [CommunityMap(), _BucketListsTab(), _DilemmasTab()],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final user = ref.read(currentUserProvider);
          if (user == null) {
            context.go(AppRoutes.login);
          } else {
            context.push(AppRoutes.createPost);
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bg,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Posts Feed ────────────────────────────────────────────────────────────────

class _PostsFeed extends ConsumerWidget {
  const _PostsFeed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(postsControllerProvider);
    final controller = ref.read(postsControllerProvider.notifier);
    final user = ref.watch(currentUserProvider);

    if (state.posts.isEmpty && state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: controller.refresh,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.posts.length + (state.isLoading ? 1 : 0),
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: AppColors.border),
        itemBuilder: (ctx, i) {
          if (i >= state.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          final post = state.posts[i];
          return _PostCard(
            post: post,
            isLiked: user != null && post.isLikedBy(user.id),
            onLike: user != null
                ? () => controller.toggleLike(post.id, user.id)
                : () => context.go(AppRoutes.login),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final bool isLiked;
  final VoidCallback onLike;
  const _PostCard({
    required this.post,
    required this.isLiked,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.surfaceElevated,
                backgroundImage: post.userPhoto != null
                    ? NetworkImage(post.userPhoto!)
                    : null,
                child: post.userPhoto == null
                    ? Text(
                        post.userName.isNotEmpty
                            ? post.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
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
                      post.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      timeago.format(
                        DateTime.tryParse(post.createdAt) ?? DateTime.now(),
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Post type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post.type,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Content
          Text(
            post.content,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(height: 1.5, fontSize: 14),
          ),

          // Spot tag
          if (post.spotName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 12,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.spotName!,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Actions
          Row(
            children: [
              _ActionBtn(
                icon: isLiked ? Icons.favorite_rounded : Icons.favorite_outline,
                label: '${post.likeCount}',
                active: isLiked,
                onTap: onLike,
              ),
              const SizedBox(width: 16),
              _ActionBtn(
                icon: Icons.chat_bubble_outline,
                label: '${post.commentCount}',
                onTap: () {},
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
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: active ? AppColors.error : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? AppColors.error : AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bucket Lists ──────────────────────────────────────────────────────────────

class _BucketListsTab extends ConsumerWidget {
  const _BucketListsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(bucketListsProvider);
    return async.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (_, __) =>
          const EmptyState(emoji: '😕', title: 'Could not load bucket lists'),
      data: (lists) => lists.isEmpty
          ? const EmptyState(
              emoji: '📋',
              title: 'No bucket lists yet',
              subtitle: 'Create one and invite friends!',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: lists.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _BucketListCard(list: lists[i]),
            ),
    );
  }
}

class _BucketListCard extends StatelessWidget {
  final BucketList list;
  const _BucketListCard({required this.list});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  list.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: list.status == 'open'
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  list.status,
                  style: TextStyle(
                    fontSize: 11,
                    color: list.status == 'open'
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (list.description != null) ...[
            const SizedBox(height: 6),
            Text(
              list.description!,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
            ),
          ],
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: list.progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${list.visitedCount}/${list.places.length} visited',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${list.participants.length}/${list.maxParticipants} travelers',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Dilemmas ──────────────────────────────────────────────────────────────────

class _DilemmasTab extends ConsumerWidget {
  const _DilemmasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dilemmas = ref.watch(dilemmasControllerProvider);
    final user = ref.watch(currentUserProvider);

    if (dilemmas.isEmpty) {
      return const EmptyState(
        emoji: '🤔',
        title: 'No dilemmas yet',
        subtitle: 'Post a travel dilemma for the community to vote!',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: dilemmas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _DilemmaCard(
        dilemma: dilemmas[i],
        userId: user?.id,
        onVote: (option) => ref
            .read(dilemmasControllerProvider.notifier)
            .vote(dilemmas[i].id, option, user?.id ?? ''),
      ),
    );
  }
}

class _DilemmaCard extends StatelessWidget {
  final Dilemma dilemma;
  final String? userId;
  final void Function(String) onVote;
  const _DilemmaCard({
    required this.dilemma,
    required this.userId,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final myVote = userId != null ? dilemma.userVote(userId!) : null;
    final voted = myVote != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dilemma.question,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'by ${dilemma.authorName}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Voting options
          Row(
            children: [
              Expanded(
                child: _VoteOption(
                  option: dilemma.optionA,
                  label: 'A',
                  percent: dilemma.percentA,
                  voted: voted,
                  isMyVote: myVote == 'A',
                  onTap: voted ? null : () => onVote('A'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _VoteOption(
                  option: dilemma.optionB,
                  label: 'B',
                  percent: dilemma.percentB,
                  voted: voted,
                  isMyVote: myVote == 'B',
                  onTap: voted ? null : () => onVote('B'),
                ),
              ),
            ],
          ),

          if (voted) ...[
            const SizedBox(height: 10),
            Text(
              '${dilemma.totalVotes} votes total',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoteOption extends StatelessWidget {
  final DilemmaOption option;
  final String label;
  final double percent;
  final bool voted;
  final bool isMyVote;
  final VoidCallback? onTap;

  const _VoteOption({
    required this.option,
    required this.label,
    required this.percent,
    required this.voted,
    required this.isMyVote,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMyVote
              ? AppColors.primary.withOpacity(0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMyVote ? AppColors.primary : AppColors.border,
            width: isMyVote ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              option.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isMyVote ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            if (voted) ...[
              const SizedBox(height: 8),
              Text(
                '${(percent * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isMyVote ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
