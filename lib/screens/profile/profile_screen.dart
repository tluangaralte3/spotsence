import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/spots_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
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
    _tabController = TabController(length: 4, vsync: this);
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
            backgroundColor: context.col.bg,
            foregroundColor: context.col.textPrimary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            actions: [
              // ── Super Admin entry point ─────────────────────────────
              if (user.isSuperAdminEmail)
                Consumer(
                  builder: (context, ref, _) {
                    final isSuperAdmin =
                        ref.watch(isSuperAdminProvider).asData?.value ??
                        user.isSuperAdminEmail;
                    if (!isSuperAdmin) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      tooltip: 'Admin Panel',
                      color: AppColors.primary,
                      onPressed: () => context.go(AppRoutes.admin),
                    );
                  },
                ),
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
                  Tab(icon: Icon(Iconsax.chart_square, size: 18), text: 'Stats'),
                  Tab(icon: Icon(Iconsax.medal, size: 18), text: 'Badges'),
                  Tab(icon: Icon(Iconsax.bookmark, size: 18), text: 'Saved'),
                  Tab(icon: Icon(Iconsax.activity, size: 18), text: 'Activity'),
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
        title: Text('Sign Out', style: TextStyle(color: ctx.col.textPrimary)),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: ctx.col.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: ctx.col.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: Colors.white),
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

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
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
                    color: AppColors.primary,
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
      {'icon': Iconsax.star, 'label': 'Reviews', 'value': '${user.ratingsCount}'},
      {
        'icon': Iconsax.location,
        'label': 'Contributions',
        'value': '${user.contributionsCount}',
      },
      {
        'icon': Iconsax.bookmark,
        'label': 'Saved Spots',
        'value': '${user.bookmarks.length}',
      },
      {'icon': Iconsax.medal, 'label': 'Badges', 'value': '${user.badgesEarned.length}'},
      {'icon': Iconsax.flash, 'label': 'Total XP', 'value': '${user.points}'},
      {'icon': Iconsax.ranking, 'label': 'Level', 'value': '${user.level}'},
      {'icon': Iconsax.camera, 'label': 'Photos', 'value': '${user.photosCount}'},
      {'icon': Iconsax.message_question, 'label': 'Dilemmas', 'value': '${user.dilemmasCreated}'},
      {
        'icon': Iconsax.tick_circle,
        'label': 'Bucket Items',
        'value': '${user.bucketItemsCompleted}',
      },
      {'icon': Iconsax.chart, 'label': 'Streak', 'value': '${user.loginStreak} days'},
      {
        'icon': Iconsax.cup,
        'label': 'Best Streak',
        'value': '${user.longestStreak} days',
      },
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Dare Dashboard shortcut ──────────────────────────────────────
        GestureDetector(
          onTap: () => context.push(
            '${AppRoutes.dareDashboard}?uid=${user.id}',
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.flash,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dare Dashboard',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.col.textPrimary,
                        ),
                      ),
                      Text(
                        'Stats, charts & manage dare participants',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.col.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Iconsax.arrow_right_3,
                  color: AppColors.primary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // ── My Bookings shortcut ─────────────────────────────────────────
        GestureDetector(
          onTap: () => context.push(AppRoutes.myBookings),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.confirmation_num_outlined,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Bookings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.col.textPrimary,
                        ),
                      ),
                      Text(
                        'Track your venture booking requests',
                        style: TextStyle(
                            fontSize: 11, color: context.col.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.primary, size: 20),
              ],
            ),
          ),
        ),

        // ── My Contributions shortcut ────────────────────────────────────
        GestureDetector(
          onTap: () => context.push(AppRoutes.myContributions),
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Iconsax.send_1,
                      color: AppColors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Contributions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.col.textPrimary,
                        ),
                      ),
                      Text(
                        'Track approval status of submitted places',
                        style: TextStyle(
                            fontSize: 11, color: context.col.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.secondary, size: 20),
              ],
            ),
          ),
        ),

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
              icon: s['icon']! as IconData,
              label: s['label']! as String,
              value: s['value']! as String,
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
  final IconData icon;
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
          Icon(icon, color: AppColors.primary, size: 22),
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
            const Icon(Iconsax.medal, color: AppColors.primary, size: 52),
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
            const Icon(Iconsax.bookmark, color: AppColors.primary, size: 52),
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
            content: Text('Profile updated'),
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
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => true;
}
