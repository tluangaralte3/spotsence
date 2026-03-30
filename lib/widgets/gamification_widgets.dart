import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../controllers/gamification_controller.dart';
import '../core/theme/app_theme.dart';
import '../models/gamification_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// XP Progress Bar
// ─────────────────────────────────────────────────────────────────────────────

/// A full-width linear XP progress bar with level numbers on each end.
class XpProgressBar extends StatelessWidget {
  final int currentXp;
  final int maxXp;
  final int level;

  const XpProgressBar({
    super.key,
    required this.currentXp,
    required this.maxXp,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxXp > 0 ? (currentXp / maxXp).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    'Lv $level',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$currentXp / $maxXp XP',
                  style: TextStyle(
                    color: context.col.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          percent: progress,
          lineHeight: 8,
          backgroundColor: context.col.surface,
          linearGradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
          animation: true,
          animationDuration: 800,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level Badge (circular)
// ─────────────────────────────────────────────────────────────────────────────

/// A small circular badge showing the level number. Used in leaderboard tiles,
/// profile headers, and spot cards.
class LevelBadge extends StatelessWidget {
  final int level;

  /// When [small] is true, renders at 20×20; otherwise 28×28.
  final bool small;

  const LevelBadge({super.key, required this.level, this.small = false});

  Color get _color {
    if (level >= 9) return AppColors.gold;
    if (level >= 7) return AppColors.secondary;
    if (level >= 4) return AppColors.primary;
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    final size = small ? 20.0 : 28.0;
    final fontSize = small ? 9.0 : 12.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withOpacity(0.2),
        border: Border.all(color: _color, width: small ? 1.5 : 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$level',
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge Chip
// ─────────────────────────────────────────────────────────────────────────────

/// Inline chip used in lists / search results to show a badge label.
class BadgeChip extends StatelessWidget {
  final String label;
  final String rarity; // common | rare | epic | legendary
  final String? icon;

  const BadgeChip({
    super.key,
    required this.label,
    required this.rarity,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.rarityColor(rarity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Text(icon!, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge Card  (used in profile badges grid)
// ─────────────────────────────────────────────────────────────────────────────

/// Larger card version for the profile badges grid.
/// Looks up badge details from [BadgeModel.allBadges] by [badgeId].
class BadgeCard extends StatelessWidget {
  final String badgeId;

  const BadgeCard({super.key, required this.badgeId});

  @override
  Widget build(BuildContext context) {
    final badge = _findBadge(badgeId);
    final color = AppTheme.rarityColor(badge?.rarity ?? 'common');

    return Container(
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(badge?.icon ?? '🏅', style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              badge?.name ?? badgeId,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            badge?.rarity ?? '',
            style: TextStyle(color: context.col.textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }

  BadgeModel? _findBadge(String id) {
    try {
      return BadgeModel.allBadges.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Achievement Card (toast / pop-up)
// ─────────────────────────────────────────────────────────────────────────────

/// Displayed as a bottom overlay when the user earns a new badge.
class AchievementCard extends StatelessWidget {
  final BadgeModel badge;
  final VoidCallback? onDismiss;

  const AchievementCard({super.key, required this.badge, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.rarityColor(badge.rarity);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.col.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Badge icon with glow
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 16),
              ],
            ),
            alignment: Alignment.center,
            child: Text(badge.icon, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎉 Badge Unlocked!',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  badge.name,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  badge.description,
                  style: TextStyle(
                    color: context.col.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                BadgeChip(
                  label: '+${badge.pointsReward} XP',
                  rarity: badge.rarity,
                  icon: '✨',
                ),
              ],
            ),
          ),

          if (onDismiss != null)
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: context.col.textSecondary,
              ),
              onPressed: onDismiss,
            ),
        ],
      ),
    ).animate().slideY(begin: 0.3).fadeIn();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rank Badge
// ─────────────────────────────────────────────────────────────────────────────

/// Used in leaderboard to highlight rank #1/#2/#3 with medal colors.
class RankBadge extends StatelessWidget {
  final int rank;

  const RankBadge({super.key, required this.rank});

  String get _emoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (rank > 3) {
      return Text(
        '#$rank',
        style: TextStyle(
          color: context.col.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      );
    }

    return Text(_emoji, style: const TextStyle(fontSize: 22));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Points Animated Counter
// ─────────────────────────────────────────────────────────────────────────────

/// Displays a running point total. Pass a new [points] value to trigger
/// the count-up animation (uses flutter_animate).
class PointsCounter extends StatelessWidget {
  final int points;
  final TextStyle? style;

  const PointsCounter({super.key, required this.points, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$points',
      style:
          style ??
          const TextStyle(
            color: AppColors.gold,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mini Stat Chip  (reusable inline stat bubble)
// ─────────────────────────────────────────────────────────────────────────────

class MiniStatChip extends StatelessWidget {
  final String emoji;
  final String value;
  final Color? color;

  const MiniStatChip({
    super.key,
    required this.emoji,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.col.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// XP Toast Overlay
// ─────────────────────────────────────────────────────────────────────────────

/// Stack this widget on top of the root scaffold to display animated XP toasts.
/// Listens to [gamificationRewardStreamProvider] and shows a bottom pop-up
/// whenever the user earns XP, levels up, or unlocks a badge.
class XpToastOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const XpToastOverlay({super.key, required this.child});

  @override
  ConsumerState<XpToastOverlay> createState() => _XpToastOverlayState();
}

class _XpToastOverlayState extends ConsumerState<XpToastOverlay>
    with TickerProviderStateMixin {
  final List<_ToastEntry> _toasts = [];
  ProviderSubscription<AsyncValue<GamificationResult>>? _sub;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set up only once — if already subscribed, do nothing.
    if (_sub != null) return;
    _sub = ref.listenManual(gamificationRewardStreamProvider, (_, next) {
      if (!mounted) return;
      next.whenData(_enqueue);
    }, fireImmediately: false);
  }

  @override
  void dispose() {
    _sub?.close();
    _sub = null;
    super.dispose();
  }

  void _enqueue(GamificationResult result) {
    if (!result.hasReward) return;
    if (!mounted) return;
    final entry = _ToastEntry(result: result);
    setState(() => _toasts.add(entry));
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _toasts.remove(entry));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._toasts.asMap().entries.map((e) {
          final idx = e.key;
          final entry = e.value;
          return Positioned(
            bottom: 80 + idx * 80.0,
            left: 16,
            right: 16,
            child: _XpToastCard(result: entry.result),
          );
        }),
      ],
    );
  }
}

class _ToastEntry {
  final GamificationResult result;
  _ToastEntry({required this.result});
}

class _XpToastCard extends StatelessWidget {
  final GamificationResult result;
  const _XpToastCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBadge = result.newBadgeIds.isNotEmpty;
    final badgeName = hasBadge
        ? BadgeModel.allBadges
              .where((b) => b.id == result.newBadgeIds.first)
              .map((b) => b.name)
              .firstOrNull
        : null;

    return Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+${result.xpAwarded} XP',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (result.leveledUp)
                        Text(
                          '🎉 Level ${result.newLevel}! ${result.streak.display}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (hasBadge)
                        Text(
                          '🏅 Badge unlocked: $badgeName',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          '⭐ Keep going!',
                          style: theme.textTheme.bodyMedium,
                        ),
                      if (result.streak.currentStreak >= 3)
                        Text(
                          '🔥 ${result.streak.currentStreak}-day streak  ×${result.streak.xpMultiplier.toStringAsFixed(1)} XP',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .slideY(begin: 0.3, end: 0, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak Banner
// ─────────────────────────────────────────────────────────────────────────────

/// A compact banner showing the current login streak with a flame icon.
class StreakBanner extends StatelessWidget {
  final int streak;
  final double xpMultiplier;

  const StreakBanner({
    super.key,
    required this.streak,
    required this.xpMultiplier,
  });

  @override
  Widget build(BuildContext context) {
    if (streak < 2) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B00), Color(0xFFFF9E1B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$streak-day streak',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (xpMultiplier > 1.0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '×${xpMultiplier.toStringAsFixed(1)} XP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds, color: Colors.white24);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// XP Activity Feed
// ─────────────────────────────────────────────────────────────────────────────

/// A scrollable list of recent [XpEvent] items for the profile screen.
class XpActivityFeed extends ConsumerWidget {
  const XpActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(xpEventsProvider);
    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (events) {
        if (events.isEmpty) {
          return const Center(
            child: Text('No activity yet. Start exploring! 🗺️'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: events.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, i) => _XpEventTile(event: events[i]),
        );
      },
    );
  }
}

class _XpEventTile extends StatelessWidget {
  final XpEvent event;
  const _XpEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Text(event.action.emoji, style: const TextStyle(fontSize: 22)),
      title: Text(event.action.label, style: theme.textTheme.bodyMedium),
      trailing: Text(
        '+${event.xpEarned} XP',
        style: theme.textTheme.labelMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        _formatDate(event.createdAt),
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
