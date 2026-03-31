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
// DareTab — shown inside CommunityScreen (renamed from BucketListsTab)
// ─────────────────────────────────────────────────────────────────────────────

class DareTab extends ConsumerStatefulWidget {
  const DareTab({super.key});

  @override
  ConsumerState<DareTab> createState() => _DareTabState();
}

class _DareTabState extends ConsumerState<DareTab>
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
      ref.read(dareControllerProvider.notifier).loadMyDares(user.id);
    }
    ref.read(dareControllerProvider.notifier).loadPublicDares();
  }

  @override
  void dispose() {
    _inner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    // If the user signs in after the tab mounts, kick off the load
    ref.listen(currentUserProvider, (prev, next) {
      if (next != null && prev?.id != next.id) {
        ref.read(dareControllerProvider.notifier).loadMyDares(next.id);
      }
    });

    return Column(
      children: [
        // Inner tab bar
        Container(
          color: context.col.bg,
          child: TabBar(
            controller: _inner,
            labelColor: AppColors.primary,
            unselectedLabelColor: context.col.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: const [Tab(text: 'My Dares'), Tab(text: 'Discover')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _inner,
            children: [
              _MyDaresView(userId: user?.id),
              const _DiscoverView(),
            ],
          ),
        ),
      ],
    );
  }
}

// ── My Dares ──────────────────────────────────────────────────────────────────

class _MyDaresView extends ConsumerWidget {
  final String? userId;
  const _MyDaresView({this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId == null) {
      return _UnauthCta(onLogin: () => context.go(AppRoutes.login));
    }

    // Use live stream so My Dares updates in real-time (pending → approved)
    final async = ref.watch(myDaresStreamProvider(userId!));

    return async.when(
      loading: () {
        // Show cached list while stream connects to avoid blank flash
        final cached = ref.read(dareControllerProvider).myDares;
        if (cached.isNotEmpty) return _buildList(context, ref, cached);
        return const Center(child: CircularProgressIndicator());
      },
      error: (_, _) => _buildList(
        context,
        ref,
        ref.read(dareControllerProvider).myDares,
      ),
      data: (myDares) => _buildList(context, ref, myDares),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<DareModel> myDares,
  ) {
    final hostedCount = myDares.where((d) => d.isCreator(userId!)).length;

    if (myDares.isEmpty) {
      return _EmptyMyDares(
        onCreate: () => context.push(AppRoutes.createDare),
        onJoin: () => showJoinCodeSheet(context, userId!),
      );
    }

    return RefreshIndicator(
      // Pull-to-refresh reloads the controller cache too
      onRefresh: () =>
          ref.read(dareControllerProvider.notifier).loadMyDares(userId!),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: myDares.length + 1, // +1 for cap banner
        itemBuilder: (context, i) {
          if (i == 0) return _DareCapBanner(hostedCount: hostedCount);
          final dare = myDares[i - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DareCard(
              dare: dare,
              currentUserId: userId!,
              onTap: () => context.push(AppRoutes.darePath(dare.id)),
            ),
          );
        },
      ),
    );
  }
}

// ── Dare cap banner ───────────────────────────────────────────────────────────

class _DareCapBanner extends StatelessWidget {
  final int hostedCount;
  const _DareCapBanner({required this.hostedCount});

  @override
  Widget build(BuildContext context) {
    final isFull = hostedCount >= kFreeDareCap;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            isFull
                ? AppColors.error.withAlpha(25)
                : AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isFull
                  ? AppColors.error.withAlpha(80)
                  : AppColors.primary.withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFull ? Iconsax.warning_2 : Iconsax.cup,
            size: 20,
            color: isFull ? AppColors.error : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFull
                      ? 'Dare limit reached ($hostedCount/$kFreeDareCap)'
                      : '$hostedCount / $kFreeDareCap dares hosted',
                  style: TextStyle(
                    color:
                        isFull
                            ? AppColors.error
                            : context.col.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (isFull)
                  Text(
                    'Complete or delete a dare to create a new one',
                    style: TextStyle(
                      color: AppColors.error.withAlpha(180),
                      fontSize: 12,
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

// ── Discover ──────────────────────────────────────────────────────────────────

class _DiscoverView extends ConsumerWidget {
  const _DiscoverView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dareControllerProvider);
    final user = ref.watch(currentUserProvider);
    final userId = user?.id ?? '';

    // Discover shows ALL public dares (including own)
    final discoverDares = state.publicDares;

    // Show full-page spinner only on initial load (list is empty)
    if (state.isLoadingPublic && discoverDares.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (discoverDares.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(dareControllerProvider.notifier).loadPublicDares(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Iconsax.flag,
                    size: 64,
                    color: context.col.textMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No public dares yet',
                    style: TextStyle(
                      color: context.col.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to create a dare!',
                    style: TextStyle(color: context.col.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.push(AppRoutes.createDare),
                    icon: const Icon(Iconsax.add),
                    label: const Text('Create Dare'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.bg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(dareControllerProvider.notifier).loadPublicDares(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: discoverDares.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final dare = discoverDares[i];
          return _DareCard(
            dare: dare,
            currentUserId: userId,
            onTap: () => context.push(AppRoutes.darePath(dare.id)),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DareCard
// ─────────────────────────────────────────────────────────────────────────────

class _DareCard extends StatelessWidget {
  final DareModel dare;
  final String currentUserId;
  final VoidCallback onTap;

  const _DareCard({
    required this.dare,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCreator = dare.isCreator(currentUserId);
    final isPending = !isCreator && dare.hasPendingRequest(currentUserId);
    final isActive = isCreator || dare.isParticipant(currentUserId);
    final pendingCount = dare.joinRequests.length;
    final categoryColor = dare.category.color;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isPending ? 0.72 : 1.0,
        child: Container(
        decoration: BoxDecoration(
          color: isPending ? context.col.surfaceElevated : context.col.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPending
                ? AppColors.warning.withAlpha(80)
                : isActive
                    ? context.col.border
                    : context.col.border,
          ),
          boxShadow: isPending
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Banner ──────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: _BannerImage(
                    url: dare.bannerUrl ?? '',
                    height: 140,
                  ),
                ),
                // Category badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: _CategoryBadge(category: dare.category),
                ),
                // Visibility badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          dare.visibility == DareVisibility.public
                              ? Iconsax.global
                              : Iconsax.lock,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dare.visibility == DareVisibility.public
                              ? 'Public'
                              : 'Private',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Pending requests badge (creator only)
                if (isCreator && pendingCount > 0)
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pendingCount pending',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // My join-request pending badge (non-creator)
                if (!isCreator && dare.hasPendingRequest(currentUserId))
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(220),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.clock,
                            size: 11,
                            color: Colors.black,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Request Pending',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // ── Content ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dare.title,
                          style: TextStyle(
                            color: context.col.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCreator)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Host',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (dare.isParticipant(currentUserId))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (isPending)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withAlpha(80),
                            ),
                          ),
                          child: const Text(
                            'Not Active Yet',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (dare.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      dare.description,
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: Iconsax.flag,
                        value: '${dare.challenges.length}',
                        label: 'Challenges',
                        color: categoryColor,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Iconsax.people,
                        value: '${dare.participantCount}/${dare.maxParticipants}',
                        label: 'Members',
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Iconsax.cup,
                        value: '${dare.xpReward} XP',
                        label: 'Reward',
                        color: AppColors.accent,
                      ),
                    ],
                  ),

                  // Deadline
                  if (dare.deadline != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          dare.isExpired
                              ? Iconsax.timer_pause
                              : Iconsax.timer_1,
                          size: 13,
                          color:
                              dare.isExpired
                                  ? AppColors.error
                                  : context.col.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dare.isExpired
                              ? 'Expired'
                              : 'Ends ${_formatDate(dare.deadline!)}',
                          style: TextStyle(
                            color:
                                dare.isExpired
                                    ? AppColors.error
                                    : context.col.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Tags
                  if (dare.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: dare.tags
                          .take(3)
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: context.col.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  color: context.col.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  // Not Activated footer for pending members
                  if (isPending) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withAlpha(50),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.clock,
                            size: 12,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Awaiting creator approval to activate',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),  // closes Opacity
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// _CategoryBadge
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final DareCategory category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: category.color.withAlpha(220),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            category.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _StatChip
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              label,
              style: TextStyle(
                color: context.col.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _JoinByCodeSheet
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
  DareModel? _found;

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
        .read(dareControllerProvider.notifier)
        .lookupJoinCode(code);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _found = result;
      _error = result == null ? 'No dare found with that code' : null;
    });
  }

  Future<void> _join() async {
    final dare = _found;
    if (dare == null) return;
    setState(() => _loading = true);
    await ref.read(dareControllerProvider.notifier).requestJoin(
      dareId: dare.id,
      userId: widget.userId,
      userName: ref.read(currentUserProvider)?.displayName ?? 'User',
      userPhoto: ref.read(currentUserProvider)?.photoURL,
      isPublic: dare.visibility == DareVisibility.public,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.col.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Join a Dare',
            style: TextStyle(
              color: context.col.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the 6-character code to join a dare',
            style: TextStyle(color: context.col.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: TextStyle(
              color: context.col.textPrimary,
              letterSpacing: 4,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'XXXXXX',
              hintStyle: TextStyle(color: context.col.textMuted),
              filled: true,
              fillColor: context.col.surfaceElevated,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Iconsax.search_normal),
                      onPressed: _lookup,
                    ),
            ),
            onSubmitted: (_) => _lookup(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ],
          if (_found != null) ...[
            const SizedBox(height: 16),
            _FoundPreview(dare: _found!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _join,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _found!.visibility == DareVisibility.public
                            ? Iconsax.add_circle
                            : Iconsax.send_sqaure_2,
                      ),
                label: Text(
                  _found!.visibility == DareVisibility.public
                      ? 'Join Now'
                      : 'Request to Join',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.bg,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FoundPreview extends StatelessWidget {
  final DareModel dare;
  const _FoundPreview({required this.dare});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _BannerImage(url: dare.bannerUrl ?? '', height: 60, width: 60),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dare.title,
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _CategoryBadge(category: dare.category),
                    const SizedBox(width: 8),
                    Text(
                      '${dare.participantCount}/${dare.maxParticipants} members',
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyMyDares
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyMyDares extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  const _EmptyMyDares({required this.onCreate, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withAlpha(40),
                    AppColors.secondary.withAlpha(40),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.flag_2,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Dares Yet',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your own dare or join one with a code',
              style: TextStyle(
                color: context.col.textSecondary,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Iconsax.add_circle),
                    label: const Text('Create Dare'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.bg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onJoin,
                    icon: const Icon(Iconsax.link),
                    label: const Text('Join with Code'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.lock, size: 64, color: context.col.textMuted),
            const SizedBox(height: 20),
            Text(
              'Sign in to join dares',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Log in to create and join dares with the community',
              style: TextStyle(color: context.col.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onLogin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.bg,
              ),
              child: const Text('Sign In'),
            ),
          ],
        ),
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
    if (url.isEmpty) return _placeholder(context, w);

    return CachedNetworkImage(
      imageUrl: url,
      width: w,
      height: height,
      fit: BoxFit.cover,
      placeholder: (_, _) => _shimmer(w),
      errorWidget: (_, _, _) => _placeholder(context, w),
    );
  }

  Widget _shimmer(double w) => _AnimatedShimmer(height: height, width: w);

  Widget _placeholder(BuildContext context, double w) => Container(
    width: w,
    height: height,
    color: context.col.surfaceElevated,
    child: Center(
      child: Icon(
        Iconsax.flag,
        size: 32,
        color: context.col.textMuted,
      ),
    ),
  );
}

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
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
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
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.col.surfaceElevated,
              context.col.border,
              context.col.surfaceElevated,
            ],
            stops: [0.0, _anim.value, 1.0],
          ),
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
    backgroundColor: Colors.transparent,
    builder: (_) => _JoinByCodeSheet(userId: userId),
  );
}
