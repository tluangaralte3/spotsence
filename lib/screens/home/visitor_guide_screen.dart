// lib/screens/home/visitor_guide_screen.dart
//
// Visitor Guide — Dos & Don'ts per NE Indian state.
// Accessed from the Home screen's "Visitor Guide" card.
// Content is loaded from the `visitor_guides` collection.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../controllers/visitor_guide_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/visitor_guide_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _guideDocKeyFor(String stateName) {
  return stateName == 'Arunachal Pradesh' ? 'Arunachal' : stateName;
}

IconData _factIconFor(String iconName) {
  switch (iconName.toLowerCase()) {
    case 'population':
    case 'people':
      return Iconsax.people;
    case 'language':
    case 'globe':
      return Iconsax.global;
    case 'weather':
    case 'season':
    case 'besttime':
      return Iconsax.sun_1;
    case 'permit':
    case 'ilp':
      return Iconsax.card;
    case 'location':
      return Iconsax.location;
    case 'time':
      return Iconsax.clock;
    default:
      return Iconsax.info_circle;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class VisitorGuideScreen extends ConsumerWidget {
  final String stateName;
  const VisitorGuideScreen({super.key, required this.stateName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideAsync = ref.watch(visitorGuideProvider(_guideDocKeyFor(stateName)));

    return guideAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.col.bg,
        appBar: AppBar(
          backgroundColor: context.col.bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Iconsax.arrow_left, color: context.col.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stackTrace) => _ComingSoonScreen(stateName: stateName),
      data: (guide) {
        if (guide == null) {
          return _ComingSoonScreen(stateName: stateName);
        }

        return Scaffold(
          backgroundColor: context.col.bg,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: context.col.bg,
                leading: IconButton(
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.24),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.arrow_left,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _GuideHero(guide: guide),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (guide.facts.isNotEmpty)
                      _QuickFactsRow(facts: guide.facts)
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.1, end: 0),
                    if (guide.facts.isNotEmpty) const SizedBox(height: 20),
                    if (guide.about.trim().isNotEmpty)
                      _GuideCard(
                        icon: Iconsax.info_circle,
                        iconColor: AppColors.info,
                        title: 'About ${guide.stateName}',
                        child: Text(
                          guide.about,
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 14,
                            height: 1.65,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 80.ms, duration: 300.ms)
                          .slideY(begin: 0.1, end: 0),
                    if (guide.about.trim().isNotEmpty) const SizedBox(height: 16),
                    if (guide.dos.isNotEmpty)
                      _GuideCard(
                        icon: Iconsax.tick_circle,
                        iconColor: AppColors.success,
                        title: 'What To Do',
                        child: _BulletList(
                          items: guide.dos,
                          color: AppColors.success,
                          icon: Iconsax.tick_circle,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 160.ms, duration: 300.ms)
                          .slideY(begin: 0.1, end: 0),
                    if (guide.dos.isNotEmpty) const SizedBox(height: 16),
                    if (guide.donts.isNotEmpty)
                      _GuideCard(
                        icon: Iconsax.close_circle,
                        iconColor: AppColors.error,
                        title: 'What Not To Do',
                        child: _BulletList(
                          items: guide.donts,
                          color: AppColors.error,
                          icon: Iconsax.close_circle,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 240.ms, duration: 300.ms)
                          .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Iconsax.lamp_on,
                              color: AppColors.accent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Always check the latest travel advisories and permit requirements '
                              'before your trip. Local rules may vary by district and season.',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 320.ms, duration: 300.ms),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuideHero extends StatelessWidget {
  final VisitorGuideModel guide;

  const _GuideHero({required this.guide});

  @override
  Widget build(BuildContext context) {
    final hasBanner = guide.bannerImageUrl.trim().isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasBanner)
          CachedNetworkImage(
            imageUrl: guide.bannerImageUrl,
            fit: BoxFit.cover,
            errorWidget: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasBanner
                  ? [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.38),
                      context.col.bg,
                    ]
                  : [
                      AppColors.secondary.withValues(alpha: 0.25),
                      AppColors.primary.withValues(alpha: 0.15),
                      context.col.bg,
                    ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 52),
                const Icon(Iconsax.map_1, size: 40, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  guide.stateName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                if (guide.tagline.trim().isNotEmpty)
                  Text(
                    guide.tagline,
                    style: const TextStyle(
                      color: Color(0xFFFDE68A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coming soon screen for states without content yet
// ─────────────────────────────────────────────────────────────────────────────

class _ComingSoonScreen extends StatelessWidget {
  final String stateName;
  const _ComingSoonScreen({required this.stateName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        title: Text(
          stateName,
          style: TextStyle(
            color: context.col.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: context.col.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.map_1, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Guide Coming Soon',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'re working on the visitor guide\nfor $stateName. Check back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.col.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _QuickFactsRow extends StatelessWidget {
  final List<GuideQuickFact> facts;
  const _QuickFactsRow({required this.facts});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: facts.map((f) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: context.col.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.col.border),
            ),
            child: Column(
              children: [
                Icon(_factIconFor(f.iconName), color: AppColors.primary, size: 18),
                const SizedBox(height: 6),
                Text(
                  f.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  f.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _GuideCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: context.col.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  final Color color;
  final IconData icon;

  const _BulletList({
    required this.items,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final isLast = entry.key == items.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: context.col.textSecondary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
