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
// DareRewardsScreen — profile rewards hub (medals + scratch cards)
// ─────────────────────────────────────────────────────────────────────────────

class DareRewardsScreen extends ConsumerStatefulWidget {
  const DareRewardsScreen({super.key});

  @override
  ConsumerState<DareRewardsScreen> createState() => _DareRewardsScreenState();
}

class _DareRewardsScreenState extends ConsumerState<DareRewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Scaffold(
        backgroundColor: context.col.bg,
        body: Center(
          child: Text(
            'Sign in to view rewards',
            style: TextStyle(color: context.col.textMuted),
          ),
        ),
      );
    }

    final medals = ref.watch(dareMedalsProvider(user.id));
    final cards = ref.watch(scratchCardsProvider(user.id));

    final unscratched = cards.asData?.value
            .where((c) => !c.isScratched)
            .length ??
        0;
    final scratchedCards =
        cards.asData?.value.where((c) => c.isScratched).toList() ?? [];
    final unscrachedCards =
        cards.asData?.value.where((c) => !c.isScratched).toList() ?? [];

    return Scaffold(
      backgroundColor: context.col.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            backgroundColor: context.col.bg,
            pinned: true,
            expandedHeight: 180,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: context.col.textSecondary,
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _RewardsHeader(
                user: user,
                medalCount: medals.asData?.value.length ?? 0,
                totalXp: _calcTotalXp(cards.asData?.value ?? []),
                unscratchedCards: unscratched,
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.primary,
              unselectedLabelColor: context.col.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.medal_star5, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Medals (${medals.asData?.value.length ?? 0})',
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.card, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Cards${unscratched > 0 ? " ($unscratched new)" : ""}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _MedalsTab(medals: medals),
            _CardsTab(
              unscratched: unscrachedCards,
              scratched: scratchedCards,
            ),
          ],
        ),
      ),
    );
  }

  int _calcTotalXp(List<ScratchCard> cards) {
    return cards
        .where((c) => c.isScratched && c.rewardType == ScratchRewardType.xp)
        .fold(0, (sum, c) => sum + c.xpAmount);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _RewardsHeader extends StatelessWidget {
  final dynamic user;
  final int medalCount;
  final int totalXp;
  final int unscratchedCards;

  const _RewardsHeader({
    required this.user,
    required this.medalCount,
    required this.totalXp,
    required this.unscratchedCards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withAlpha(20),
            AppColors.primary.withAlpha(10),
          ],
        ),
      ),
      child: Row(
        children: [
          _StatBadge(
            icon: Iconsax.medal_star5,
            value: '$medalCount',
            label: 'Medals',
            color: AppColors.accent,
          ),
          const SizedBox(width: 12),
          _StatBadge(
            icon: Iconsax.flash,
            value: '+$totalXp',
            label: 'XP Earned',
            color: AppColors.info,
          ),
          if (unscratchedCards > 0) ...[
            const SizedBox(width: 12),
            _StatBadge(
              icon: Iconsax.card,
              value: '$unscratchedCards',
              label: 'New Cards',
              color: AppColors.primary,
              pulse: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool pulse;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Medals tab
// ─────────────────────────────────────────────────────────────────────────────

class _MedalsTab extends StatelessWidget {
  final AsyncValue<List<DareMedalRecord>> medals;
  const _MedalsTab({required this.medals});

  @override
  Widget build(BuildContext context) {
    return medals.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: context.col.error)),
      ),
      data: (list) {
        if (list.isEmpty) {
          return _EmptyState(
            icon: Iconsax.medal_star5,
            title: 'No medals yet',
            subtitle:
                'Complete dare challenges to earn medals and build your collection',
            color: AppColors.accent,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.9,
          ),
          itemCount: list.length,
          itemBuilder: (context, i) => _MedalCard(medal: list[i]),
        );
      },
    );
  }
}

class _MedalCard extends StatelessWidget {
  final DareMedalRecord medal;
  const _MedalCard({required this.medal});

  @override
  Widget build(BuildContext context) {
    final col = medal.medalType.color;
    return Container(
      decoration: BoxDecoration(
        color: medal.medalType.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: col.withAlpha(40),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: col.withAlpha(30),
                border: Border.all(color: col.withAlpha(100)),
              ),
              child: Icon(medal.medalType.icon, color: col, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              medal.medalType.label,
              style: TextStyle(
                color: col,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              medal.challengeTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              medal.dareTitle,
              style: TextStyle(color: Colors.white60, fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(medal.earnedAt),
              style: TextStyle(
                color: col.withAlpha(180),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cards tab
// ─────────────────────────────────────────────────────────────────────────────

class _CardsTab extends StatelessWidget {
  final List<ScratchCard> unscratched;
  final List<ScratchCard> scratched;

  const _CardsTab({required this.unscratched, required this.scratched});

  @override
  Widget build(BuildContext context) {
    if (unscratched.isEmpty && scratched.isEmpty) {
      return _EmptyState(
        icon: Iconsax.card,
        title: 'No scratch cards yet',
        subtitle:
            'Complete dare challenges to earn scratch cards with exciting rewards',
        color: AppColors.primary,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (unscratched.isNotEmpty) ...[
          _SubHeader(
            icon: Iconsax.star,
            title: 'Scratch Now (${unscratched.length})',
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: unscratched.length,
            itemBuilder: (ctx, i) => _UnscratchedCardTile(
              card: unscratched[i],
              onTap: () => context.push(
                AppRoutes.scratchCardPath(unscratched[i].id),
                extra: unscratched[i],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (scratched.isNotEmpty) ...[
          _SubHeader(
            icon: Iconsax.archive,
            title: 'Past Cards (${scratched.length})',
            color: context.col.textSecondary,
          ),
          const SizedBox(height: 12),
          ...scratched.map((c) => _ScratchedCardRow(card: c)),
        ],
      ],
    );
  }
}

class _UnscratchedCardTile extends StatelessWidget {
  final ScratchCard card;
  final VoidCallback onTap;
  const _UnscratchedCardTile({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withAlpha(60),
              blurRadius: 10,
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Iconsax.card,
              size: 36,
              color: Color(0xFF5D4037),
            ),
            const SizedBox(height: 8),
            const Text(
              '✦ TAP TO\nSCRATCH ✦',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF5D4037),
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x30000000),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                card.dareTitle,
                style: const TextStyle(
                  color: Color(0xFF5D4037),
                  fontSize: 9,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScratchedCardRow extends StatelessWidget {
  final ScratchCard card;
  const _ScratchedCardRow({required this.card});

  @override
  Widget build(BuildContext context) {
    final isNothing = card.rewardType == ScratchRewardType.nothing;
    final rewardColor = isNothing ? context.col.textMuted : _rewardColor(card);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rewardColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_rewardIcon(card.rewardType), color: rewardColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _rewardText(card),
                  style: TextStyle(
                    color: isNothing
                        ? context.col.textSecondary
                        : context.col.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  card.challengeTitle,
                  style: TextStyle(color: context.col.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            card.scratchedAt != null
                ? _formatDate(card.scratchedAt!)
                : '',
            style: TextStyle(color: context.col.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Color _rewardColor(ScratchCard card) {
    switch (card.rewardType) {
      case ScratchRewardType.xp:
        return AppColors.info;
      case ScratchRewardType.medal:
        return AppColors.accent;
      case ScratchRewardType.badge:
        return AppColors.secondary;
      case ScratchRewardType.multiplier:
        return AppColors.primary;
      case ScratchRewardType.nothing:
        return Colors.grey;
    }
  }

  IconData _rewardIcon(ScratchRewardType type) {
    switch (type) {
      case ScratchRewardType.xp:
        return Iconsax.flash;
      case ScratchRewardType.medal:
        return Iconsax.medal_star5;
      case ScratchRewardType.badge:
        return Iconsax.shield_tick;
      case ScratchRewardType.multiplier:
        return Iconsax.element_plus;
      case ScratchRewardType.nothing:
        return Iconsax.emoji_happy;
    }
  }

  String _rewardText(ScratchCard card) {
    switch (card.rewardType) {
      case ScratchRewardType.xp:
        return '+${card.xpAmount} XP';
      case ScratchRewardType.medal:
        return '${card.medal?.label ?? ''} Medal';
      case ScratchRewardType.badge:
        return card.badgeTitle ?? 'Badge';
      case ScratchRewardType.multiplier:
        return '×${card.multiplier?.toStringAsFixed(1)} Multiplier';
      case ScratchRewardType.nothing:
        return 'Better luck next time';
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SubHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SubHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: context.col.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: context.col.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
