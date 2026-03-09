import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/community_models.dart';
import '../../widgets/shared_widgets.dart';
import 'community_map.dart';
import 'bucket_lists_tab.dart';

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
          children: const [CommunityMap(), BucketListsTab(), _DilemmasTab()],
        ),
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabs,
        builder: (context, _) {
          if (_tabs.index == 1) {
            // Bucket lists tab: show create + join FABs
            final user = ref.read(currentUserProvider);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'join_list',
                  onPressed: () {
                    if (user != null) {
                      showJoinCodeSheet(context, user.id);
                    } else {
                      context.go(AppRoutes.login);
                    }
                  },
                  backgroundColor: AppColors.surfaceElevated,
                  foregroundColor: AppColors.primary,
                  child: const Icon(Icons.link_rounded),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'create_list',
                  onPressed: () {
                    if (user != null) {
                      context.push(AppRoutes.createBucketList);
                    } else {
                      context.go(AppRoutes.login);
                    }
                  },
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.bg,
                  child: const Icon(Icons.add_rounded),
                ),
              ],
            );
          }
          // Default tab: create post
          return FloatingActionButton(
            heroTag: 'create_post',
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
          );
        },
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
