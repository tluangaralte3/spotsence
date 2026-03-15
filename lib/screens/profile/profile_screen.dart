import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/community_controller.dart';
import '../../controllers/spots_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../models/community_models.dart';
import '../../models/gamification_models.dart';
import '../../models/spot_model.dart';
import '../../models/user_model.dart';
import '../../widgets/gamification_widgets.dart';
import '../../widgets/shared_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    if (!isAuthenticated || user == null) {
      return const _UnauthenticatedView();
    }

    return _AuthenticatedProfile(user: user);
  }
}

// ─── Unauthenticated ──────────────────────────────────────────────────────────

class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_rounded,
                size: 72,
                color: context.col.textSecondary,
              ),
              const SizedBox(height: 20),
              Text(
                'Sign in to view your profile',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Track your XP, badges, and saved spots',
                style: TextStyle(color: context.col.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Authenticated Profile ───────────────────────────────────────────────────

class _AuthenticatedProfile extends ConsumerStatefulWidget {
  final UserModel user;
  const _AuthenticatedProfile({required this.user});

  @override
  ConsumerState<_AuthenticatedProfile> createState() =>
      _AuthenticatedProfileState();
}

class _AuthenticatedProfileState extends ConsumerState<_AuthenticatedProfile>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final bookmarksAsync = ref.watch(bookmarksProvider(user.id));
    final bookmarksList = bookmarksAsync.value ?? [];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  final isDark =
                      ref.watch(themeControllerProvider) == ThemeMode.dark;
                  return IconButton(
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                    tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
                    onPressed: () => ref
                        .read(themeControllerProvider.notifier)
                        .toggleDarkLight(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Profile',
                onPressed: () => _showEditProfileSheet(context, user),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sign Out',
                onPressed: () => _confirmSignOut(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(user: user),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'My Posts'),
                  Tab(text: 'Stats'),
                  Tab(text: 'Badges'),
                  Tab(text: 'Saved'),
                  Tab(text: 'Activity'),
                ],
                labelColor: AppColors.primary,
                unselectedLabelColor: context.col.textSecondary,
                indicatorColor: AppColors.primary,
                dividerColor: context.col.border,
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _MyPostsTab(userId: user.id),
            _StatsTab(user: user),
            _BadgesTab(user: user),
            _SavedTab(bookmarks: bookmarksList),
            const _ActivityTab(),
          ],
        ),
      ),
    );
  }

  void _showEditProfileSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.col.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.col.surfaceElevated,
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1025), context.col.bg],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 90, 24, 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Avatar
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: context.col.surface,
                    backgroundImage: user.photoURL != null
                        ? CachedNetworkImageProvider(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                LevelBadge(level: user.level),
              ],
            ),
            const SizedBox(height: 12),

            // Name
            Text(
              user.displayName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              user.levelTitle,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (user.bio != null && user.bio!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                user.bio!,
                style: TextStyle(
                  color: context.col.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),

            // XP Bar
            XpProgressBar(
              currentXp: user.points,
              maxXp: user.points + user.xpToNextLevel,
              level: user.level,
            ),
            if (user.loginStreak >= 2) ...[
              const SizedBox(height: 10),
              StreakBanner(
                streak: user.loginStreak,
                xpMultiplier: (1.0 + (user.loginStreak ~/ 5) * 0.10).clamp(
                  1.0,
                  2.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Stats Tab ────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final UserModel user;
  const _StatsTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'icon': '⭐', 'label': 'Reviews', 'value': '${user.ratingsCount}'},
      {
        'icon': '📍',
        'label': 'Contributions',
        'value': '${user.contributionsCount}',
      },
      {
        'icon': '🔖',
        'label': 'Saved Spots',
        'value': '${user.bookmarks.length}',
      },
      {'icon': '🏅', 'label': 'Badges', 'value': '${user.badgesEarned.length}'},
      {'icon': '✨', 'label': 'Total XP', 'value': '${user.points}'},
      {'icon': '🎯', 'label': 'Level', 'value': '${user.level}'},
      {'icon': '📷', 'label': 'Photos', 'value': '${user.photosCount}'},
      {'icon': '🤔', 'label': 'Dilemmas', 'value': '${user.dilemmasCreated}'},
      {
        'icon': '✅',
        'label': 'Bucket Items',
        'value': '${user.bucketItemsCompleted}',
      },
      {'icon': '🔥', 'label': 'Streak', 'value': '${user.loginStreak} days'},
      {
        'icon': '🏆',
        'label': 'Best Streak',
        'value': '${user.longestStreak} days',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionTitle('Activity'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.1,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: stats.length,
          itemBuilder: (_, i) {
            final s = stats[i];
            return _StatCard(
              icon: s['icon']!,
              label: s['label']!,
              value: s['value']!,
            );
          },
        ),

        const SizedBox(height: 24),
        _SectionTitle('Level Progress'),
        const SizedBox(height: 12),
        _LevelProgressCard(user: user),

        if (user.location != null && user.location!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _SectionTitle('Location'),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.secondary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                user.location!,
                style: TextStyle(color: context.col.textSecondary),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: context.col.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

class _LevelProgressCard extends StatelessWidget {
  final UserModel user;
  const _LevelProgressCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final currentLevel = LevelInfo.levels.firstWhere(
      (l) => l.level == user.level,
      orElse: () => LevelInfo.levels.first,
    );
    final nextLevel = user.level < 10 ? LevelInfo.levels[user.level] : null;

    final progress = user.xpToNextLevel > 0
        ? (user.points - currentLevel.minPoints) / (user.xpToNextLevel)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${user.level}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    user.levelTitle,
                    style: TextStyle(
                      color: context.col.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (nextLevel != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Level ${nextLevel.level}',
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      nextLevel.title,
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  'MAX LEVEL',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            percent: progress.clamp(0.0, 1.0),
            lineHeight: 12,
            backgroundColor: context.col.surface,
            progressColor: AppColors.primary,
            barRadius: const Radius.circular(6),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${user.points} XP',
                style: TextStyle(
                  color: context.col.textSecondary,
                  fontSize: 11,
                ),
              ),
              if (nextLevel != null)
                Text(
                  '${nextLevel.minPoints - user.points} XP to Level ${nextLevel.level}',
                  style: TextStyle(
                    color: context.col.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Badges Tab ───────────────────────────────────────────────────────────────

class _BadgesTab extends ConsumerWidget {
  final UserModel user;
  const _BadgesTab({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user.badgesEarned.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏅', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              'No badges yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Contribute and explore to earn badges!',
              style: TextStyle(color: context.col.textSecondary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: user.badgesEarned.length,
      itemBuilder: (_, i) {
        final badgeId = user.badgesEarned[i];
        return BadgeCard(badgeId: badgeId)
            .animate(delay: Duration(milliseconds: i * 60))
            .fadeIn()
            .scale(begin: const Offset(0.85, 0.85));
      },
    );
  }
}

// ─── Saved Tab ────────────────────────────────────────────────────────────────

class _SavedTab extends ConsumerWidget {
  final List<SpotModel> bookmarks;
  const _SavedTab({required this.bookmarks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔖', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              'No saved spots',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Bookmark spots to see them here',
              style: TextStyle(color: context.col.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.listings),
              child: const Text('Explore Spots'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookmarks.length,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: CompactSpotCard(spot: bookmarks[i]),
      ),
    );
  }
}

// ─── My Posts Tab ─────────────────────────────────────────────────────────────

class _MyPostsTab extends ConsumerWidget {
  final String userId;
  const _MyPostsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsState = ref.watch(postsControllerProvider);
    final myPosts = postsState.posts.where((p) => p.userId == userId).toList();

    if (postsState.isLoading && myPosts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (myPosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✍️', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                'No posts yet',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Your community posts will appear here.',
                style: TextStyle(color: context.col.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: myPosts.length,
      itemBuilder: (context, i) {
        final post = myPosts[i];
        return _MyPostCard(post: post, userId: userId)
            .animate(delay: Duration(milliseconds: i * 50))
            .fadeIn()
            .slideY(begin: 0.04);
      },
    );
  }
}

class _MyPostCard extends ConsumerWidget {
  final CommunityPost post;
  final String userId;
  const _MyPostCard({required this.post, required this.userId});

  static const _typeEmoji = {
    'post': '📝',
    'tip': '💡',
    'question': '❓',
    'review': '⭐',
  };

  static const _typeLabel = {
    'post': 'Post',
    'tip': 'Tip',
    'question': 'Question',
    'review': 'Review',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge + actions row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_typeEmoji[post.type] ?? '📝'} ${_typeLabel[post.type] ?? post.type}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (post.spotName != null && post.spotName!.isNotEmpty)
                  Expanded(
                    child: Text(
                      '@ ${post.spotName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.col.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showEditSheet(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: context.col.textSecondary,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _confirmDelete(context, ref),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Content
            Text(
              post.content,
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),

            // Footer
            Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color: context.col.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.likeCount}',
                  style: TextStyle(fontSize: 12, color: context.col.textMuted),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: context.col.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount}',
                  style: TextStyle(fontSize: 12, color: context.col.textMuted),
                ),
                const Spacer(),
                Text(
                  _formatDate(post.createdAt),
                  style: TextStyle(fontSize: 11, color: context.col.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Delete Post'),
        content: const Text(
          'This will permanently delete your post. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final err = await ref
                  .read(postsControllerProvider.notifier)
                  .deletePost(post.id);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(err),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditPostSheet(post: post, ref: ref),
    );
  }
}

class _EditPostSheet extends StatefulWidget {
  final CommunityPost post;
  final WidgetRef ref;
  const _EditPostSheet({required this.post, required this.ref});

  @override
  State<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<_EditPostSheet> {
  late final TextEditingController _contentCtrl;
  late String _type;
  bool _loading = false;

  static const _types = [
    {'id': 'post', 'label': '📝 Post'},
    {'id': 'tip', 'label': '💡 Tip'},
    {'id': 'question', 'label': '❓ Question'},
    {'id': 'review', 'label': '⭐ Review'},
  ];

  @override
  void initState() {
    super.initState();
    _contentCtrl = TextEditingController(text: widget.post.content);
    _type = widget.post.type;
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final err = await widget.ref
        .read(postsControllerProvider.notifier)
        .updatePost(
          postId: widget.post.id,
          content: _contentCtrl.text.trim(),
          type: _type,
        );
    if (mounted) {
      setState(() => _loading = false);
      if (err == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post updated ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Edit Post', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((t) {
              final selected = _type == t['id'];
              return GestureDetector(
                onTap: () => setState(() => _type = t['id']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : context.col.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? AppColors.primary : context.col.border,
                    ),
                  ),
                  child: Text(
                    t['label']!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.primary
                          : context.col.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentCtrl,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'What\'s on your mind?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_loading || _contentCtrl.text.trim().isEmpty)
                  ? null
                  : _save,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Activity Tab ─────────────────────────────────────────────────────────────

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const XpActivityFeed();
  }
}

// ─── Edit Profile Sheet (original) ───────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  final UserModel user;
  const _EditProfileSheet({required this.user});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _locationCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName);
    _bioCtrl = TextEditingController(text: widget.user.bio ?? '');
    _locationCtrl = TextEditingController(text: widget.user.location ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);

    final error = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          displayName: _nameCtrl.text.trim(),
          bio: _bioCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
        );

    if (mounted) {
      setState(() => _loading = false);
      if (error == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated ✓'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio',
              prefixIcon: Icon(Icons.info_outline),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.col.bg,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => Container(color: context.col.bg, child: tabBar);

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => false;
}
