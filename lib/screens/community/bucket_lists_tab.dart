import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/bucket_list_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bucket_list_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BucketListsTab — shown inside CommunityScreen
// ─────────────────────────────────────────────────────────────────────────────

class BucketListsTab extends ConsumerStatefulWidget {
  const BucketListsTab({super.key});

  @override
  ConsumerState<BucketListsTab> createState() => _BucketListsTabState();
}

class _BucketListsTabState extends ConsumerState<BucketListsTab>
    with SingleTickerProviderStateMixin {
  late TabController _inner;

  @override
  void initState() {
    super.initState();
    _inner = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(bucketListControllerProvider.notifier).loadMyLists(user.id);
    }
    ref.read(bucketListControllerProvider.notifier).loadPublicLists();
  }

  @override
  void dispose() {
    _inner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Column(
      children: [
        // ── Sub-tab bar ──────────────────────────────────────────────────
        Container(
          color: context.col.bg,
          child: TabBar(
            controller: _inner,
            labelColor: AppColors.primary,
            unselectedLabelColor: context.col.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [
              Tab(icon: Icon(Iconsax.task_square), text: 'My Lists'),
              Tab(icon: Icon(Iconsax.global), text: 'Discover'),
            ],
          ),
        ),

        // ── Tab content ───────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _inner,
            children: [
              _MyListsView(userId: user?.id),
              const _DiscoverView(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── My Lists ──────────────────────────────────────────────────────────────────

class _MyListsView extends ConsumerWidget {
  final String? userId;
  const _MyListsView({this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bucketListControllerProvider);

    if (userId == null) {
      return _UnauthCta(onLogin: () => context.go(AppRoutes.login));
    }

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.myLists.isEmpty) {
      return _EmptyMyLists(
        onCreate: () => context.push(AppRoutes.createBucketList),
        onJoin: () => _showJoinDialog(context, ref),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(bucketListControllerProvider.notifier).loadMyLists(userId!),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: state.myLists.length,
        separatorBuilder: (context, _) => const SizedBox(height: 14),
        itemBuilder: (context, i) => _BucketListCard(
          list: state.myLists[i],
          currentUserId: userId!,
          onTap: () =>
              context.push(AppRoutes.bucketListDetailPath(state.myLists[i].id)),
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _JoinByCodeSheet(userId: userId!),
    );
  }
}

// ── Discover ──────────────────────────────────────────────────────────────────

class _DiscoverView extends ConsumerWidget {
  const _DiscoverView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bucketListControllerProvider);
    final user = ref.watch(currentUserProvider);

    if (state.isLoadingPublic) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state.publicLists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'No public bucket lists yet',
              style: TextStyle(color: context.col.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to share one!',
              style: TextStyle(color: context.col.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: state.publicLists.length,
      separatorBuilder: (context, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) => _BucketListCard(
        list: state.publicLists[i],
        currentUserId: user?.id ?? '',
        onTap: () => context.push(
          AppRoutes.bucketListDetailPath(state.publicLists[i].id),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BucketListCard
// ─────────────────────────────────────────────────────────────────────────────

class _BucketListCard extends StatelessWidget {
  final BucketListModel list;
  final String currentUserId;
  final VoidCallback onTap;

  const _BucketListCard({
    required this.list,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isHost = list.isHost(currentUserId);
    final pct = (list.progress * 100).toInt();
    final pending = list.joinRequests.length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.col.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner ──────────────────────────────────────────────────
            Stack(
              children: [
                _BannerImage(url: list.bannerUrl, height: 110),

                // Category badge
                Positioned(
                  top: 10,
                  left: 12,
                  child: _Badge(
                    '${list.category.emoji}  ${list.displayCategory}',
                    color: context.col.surfaceElevated.withValues(alpha: 0.92),
                    textColor: context.col.textPrimary,
                  ),
                ),

                // Visibility
                Positioned(
                  top: 10,
                  right: 12,
                  child: _Badge(
                    list.visibility == BucketVisibility.public
                        ? '🌐 Public'
                        : '🔒 Private',
                    color: context.col.surfaceElevated.withValues(alpha: 0.92),
                    textColor: list.visibility == BucketVisibility.public
                        ? AppColors.primary
                        : context.col.textSecondary,
                  ),
                ),

                // Completion ribbon
                if (list.isCompleted)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: AppColors.primary.withValues(alpha: 0.85),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '🎉  Adventure Complete!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.col.bg,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          list.title,
                          style: TextStyle(
                            color: context.col.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isHost && pending > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$pending pending',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  if (list.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      list.description,
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: list.progress,
                      backgroundColor: context.col.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        list.isCompleted
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.7),
                      ),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      Text(
                        '${list.checkedCount}/${list.items.length} done · $pct%',
                        style: TextStyle(
                          color: context.col.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.people_outline,
                        size: 13,
                        color: context.col.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${list.approvedCount}/${list.maxMembers}',
                        style: TextStyle(
                          color: context.col.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (list.xpReward > 0) ...[
                        const SizedBox(width: 10),
                        Text(
                          '+${list.xpReward} XP',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _JoinByCodeSheet — bottom sheet modal
// ─────────────────────────────────────────────────────────────────────────────

class _JoinByCodeSheet extends ConsumerStatefulWidget {
  final String userId;
  const _JoinByCodeSheet({required this.userId});

  @override
  ConsumerState<_JoinByCodeSheet> createState() => _JoinByCodeSheetState();
}

class _JoinByCodeSheetState extends ConsumerState<_JoinByCodeSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;
  BucketListModel? _found;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Code must be 6 characters');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _found = null;
    });
    final result = await ref
        .read(bucketListControllerProvider.notifier)
        .lookupJoinCode(code);
    if (!mounted) return;
    if (result == null) {
      setState(() {
        _loading = false;
        _error = 'No bucket list found with that code';
      });
    } else {
      setState(() {
        _loading = false;
        _found = result;
      });
    }
  }

  Future<void> _join() async {
    if (_found == null) return;
    setState(() => _loading = true);
    final user = ref.read(currentUserProvider)!;
    await ref
        .read(bucketListControllerProvider.notifier)
        .requestJoin(
          listId: _found!.id,
          userId: user.id,
          userName: user.displayName,
          userPhoto: user.photoURL,
          isPublic: _found!.visibility == BucketVisibility.public,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _found!.visibility == BucketVisibility.public
              ? 'Join request sent! Waiting for host approval 🙌'
              : 'Join request sent! Waiting for host approval 🔒',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.col.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Join by Code',
            style: TextStyle(
              color: context.col.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the 6-character join code shared by the bucket list host.',
            style: TextStyle(color: context.col.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Code input
          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: TextStyle(
              color: context.col.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 8,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              counterText: '',
              hintText: 'ABC123',
              hintStyle: TextStyle(
                color: context.col.textMuted,
                letterSpacing: 8,
                fontSize: 22,
              ),
              filled: true,
              fillColor: context.col.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              errorText: _error,
            ),
            onSubmitted: (_) => _lookup(),
          ),

          const SizedBox(height: 16),

          // Found preview
          if (_found != null) _FoundPreview(list: _found!),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.col.textSecondary,
                    side: BorderSide(color: context.col.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _loading
                      ? null
                      : (_found != null ? _join : _lookup),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: context.col.bg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.col.bg,
                          ),
                        )
                      : Text(_found != null ? 'Send Request' : 'Look Up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FoundPreview extends StatelessWidget {
  final BucketListModel list;
  const _FoundPreview({required this.list});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _BannerImage(url: list.bannerUrl, height: 50, width: 50),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.title,
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${list.category.emoji} ${list.displayCategory} · by ${list.hostName}',
                  style: TextStyle(
                    color: context.col.textSecondary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  '${list.approvedCount}/${list.maxMembers} members · ${list.items.length} stops',
                  style: TextStyle(color: context.col.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyMyLists
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyMyLists extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _EmptyMyLists({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No Bucket Lists Yet',
            style: TextStyle(
              color: context.col.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your ultimate Mizoram adventure list\nor join one from a friend\'s code!',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.col.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Bucket List'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: context.col.bg,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onJoin,
            icon: const Icon(Icons.link_rounded),
            label: const Text('Join with Code'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _UnauthCta
// ─────────────────────────────────────────────────────────────────────────────

class _UnauthCta extends StatelessWidget {
  final VoidCallback onLogin;
  const _UnauthCta({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🗺️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'Plan adventures together!',
            style: TextStyle(
              color: context.col.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to create and share bucket lists with friends.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.col.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: onLogin,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: context.col.bg,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BannerImage helper
// ─────────────────────────────────────────────────────────────────────────────

class _BannerImage extends StatelessWidget {
  final String url;
  final double height;
  final double? width;

  const _BannerImage({required this.url, required this.height, this.width});

  @override
  Widget build(BuildContext context) {
    final w = width ?? double.infinity;

    if (url.isEmpty) {
      return _placeholder(context, w);
    }

    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: w,
      fit: BoxFit.cover,
      placeholder: (ctx, _) => _shimmer(w),
      errorWidget: (ctx, url2, _) => _placeholder(ctx, w),
      imageBuilder: (ctx, imageProvider) => Stack(
        fit: StackFit.passthrough,
        children: [
          // The image itself
          Container(
            height: height,
            width: w,
            decoration: BoxDecoration(
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          ),
          // Subtle bottom gradient so badges stay readable
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: height * 0.45,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmer(double w) {
    return _AnimatedShimmer(height: height, width: w);
  }

  Widget _placeholder(BuildContext context, double w) {
    return Container(
      height: height,
      width: w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.col.surfaceElevated,
            context.col.border.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.photo_camera_outlined,
          color: context.col.textMuted,
          size: 28,
        ),
      ),
    );
  }
}

// Animated shimmer loading placeholder
class _AnimatedShimmer extends StatefulWidget {
  final double height;
  final double width;
  const _AnimatedShimmer({required this.height, required this.width});

  @override
  State<_AnimatedShimmer> createState() => _AnimatedShimmerState();
}

class _AnimatedShimmerState extends State<_AnimatedShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = Tween<double>(
      begin: -1.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: [
              context.col.surfaceElevated,
              context.col.border,
              context.col.surfaceElevated,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Badge helper
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Badge(this.label, {required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAB helpers — exported for use in CommunityScreen
// ─────────────────────────────────────────────────────────────────────────────

void showJoinCodeSheet(BuildContext context, String userId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.col.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _JoinByCodeSheet(userId: userId),
  );
}
