// lib/screens/packages/tour_packages_screen.dart
//
// Dare & Venture — activity & adventure packages listing screen.
// Includes category filter chips, season selector, difficulty filter,
// and a search bar — all client-side on top of a Firestore stream.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/tour_venture_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tour_venture_models.dart';
import '../../widgets/shared_widgets.dart';

class TourPackagesScreen extends ConsumerStatefulWidget {
  const TourPackagesScreen({super.key});

  @override
  ConsumerState<TourPackagesScreen> createState() => _TourPackagesScreenState();
}

class _TourPackagesScreenState extends ConsumerState<TourPackagesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(packageFilterProvider);
    final packagesAsync = ref.watch(filteredPackagesProvider);

    return Scaffold(
      backgroundColor: context.col.bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            pinned: false,
            backgroundColor: context.col.bg,
            titleSpacing: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: context.col.textPrimary,
              onPressed: () => context.pop(),
            ),
            title: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Text(
                    '⚡ Dare & Venture',
                    style: TextStyle(
                      color: context.col.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.secondary, AppColors.primary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Exclusive',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _SearchBar(
                  controller: _searchCtrl,
                  onChanged: (q) =>
                      ref.read(packageFilterProvider.notifier).setSearch(q),
                ),
              ),
            ),
          ),

          // ── Category chips ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _CategoryChips(
              selected: filter.category,
              onSelect: (c) =>
                  ref.read(packageFilterProvider.notifier).setCategory(c),
            ),
          ),

          // ── Season + Difficulty filter row ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _SeasonDropdown(
                    selected: filter.season,
                    onSelect: (s) =>
                        ref.read(packageFilterProvider.notifier).setSeason(s),
                  ),
                  const SizedBox(width: 10),
                  _DifficultyDropdown(
                    selected: filter.difficulty,
                    onSelect: (d) => ref
                        .read(packageFilterProvider.notifier)
                        .setDifficulty(d),
                  ),
                  const Spacer(),
                  if (filter.category != null ||
                      filter.season != null ||
                      filter.difficulty != null ||
                      filter.searchQuery.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        ref.read(packageFilterProvider.notifier).clearAll();
                        _searchCtrl.clear();
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(color: context.col.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Package grid ─────────────────────────────────────────────
          packagesAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const ShimmerBox(
                    width: double.infinity,
                    height: 280,
                    radius: 16,
                  ),
                  childCount: 4,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.55,
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: EmptyState(
                  emoji: '😕',
                  title: 'Could not load packages',
                  subtitle: e.toString(),
                ),
              ),
            ),
            data: (packages) {
              if (packages.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: EmptyState(
                      emoji: '⚡',
                      title: 'No ventures found',
                      subtitle: 'Try clearing your filters',
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PackageCard(
                        package: packages[i],
                        onTap: () => ctx.push(
                          AppRoutes.packageDetailPath(packages[i].id),
                        ),
                      ),
                    ),
                    childCount: packages.length,
                  ),
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
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: context.col.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search activities, locations...',
        hintStyle: TextStyle(color: context.col.textMuted, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: context.col.textMuted, size: 20),
        filled: true,
        fillColor: context.col.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.col.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.col.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category chips
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  final PackageCategory? selected;
  final ValueChanged<PackageCategory?> onSelect;

  const _CategoryChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Chip(
              label: '🗺️  All',
              selected: selected == null,
              onTap: () => onSelect(null),
            ),
          ),
          ...PackageCategory.values.map(
            (c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: '${c.emoji}  ${c.label}',
                selected: selected == c,
                onTap: () => onSelect(selected == c ? null : c),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : context.col.surfaceElevated,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primary : context.col.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.black : context.col.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Season dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _SeasonDropdown extends StatelessWidget {
  final PackageSeason? selected;
  final ValueChanged<PackageSeason?> onSelect;

  const _SeasonDropdown({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected != null
              ? AppColors.secondary.withOpacity(0.15)
              : context.col.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected != null ? AppColors.secondary : context.col.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected != null ? selected!.emoji : '📅',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              selected != null ? selected!.label.split(' ').first : 'Season',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected != null
                    ? AppColors.secondary
                    : context.col.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: selected != null
                  ? AppColors.secondary
                  : context.col.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SeasonSheet(
        selected: selected,
        onSelect: (s) {
          Navigator.pop(context);
          onSelect(s);
        },
      ),
    );
  }
}

class _SeasonSheet extends StatelessWidget {
  final PackageSeason? selected;
  final ValueChanged<PackageSeason?> onSelect;

  const _SeasonSheet({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 16),
          Text(
            'Filter by Season',
            style: TextStyle(
              color: context.col.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(
                label: '🗺️  All Seasons',
                selected: selected == null,
                onTap: () => onSelect(null),
              ),
              ...PackageSeason.values.map(
                (s) => _Chip(
                  label: '${s.emoji}  ${s.label.split(' ').first}',
                  selected: selected == s,
                  onTap: () => onSelect(s),
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
// Difficulty dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _DifficultyDropdown extends StatelessWidget {
  final DifficultyLevel? selected;
  final ValueChanged<DifficultyLevel?> onSelect;

  const _DifficultyDropdown({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected != null
              ? Color(selected!.colorHex).withOpacity(0.15)
              : context.col.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected != null
                ? Color(selected!.colorHex)
                : context.col.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected != null ? '🏋️' : '🎯',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              selected?.label ?? 'Difficulty',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: selected != null
                    ? Color(selected!.colorHex)
                    : context.col.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: context.col.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: context.col.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text(
              'Filter by Difficulty',
              style: TextStyle(
                color: context.col.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(
                  label: '🎯  All Levels',
                  selected: selected == null,
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(null);
                  },
                ),
                ...DifficultyLevel.values.map(
                  (d) => _Chip(
                    label: d.label,
                    selected: selected == d,
                    onTap: () {
                      Navigator.pop(context);
                      onSelect(d);
                    },
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
// Package card (reusable — used on listings + home section)
// ─────────────────────────────────────────────────────────────────────────────

class PackageCard extends StatelessWidget {
  final TourVentureModel package;
  final VoidCallback onTap;

  const PackageCard({super.key, required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.col.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero image ──────────────────────────────────────────────
            Stack(
              children: [
                SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: package.heroImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: package.heroImage,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              _ImagePlaceholder(category: package.category),
                          errorWidget: (_, __, ___) =>
                              _ImagePlaceholder(category: package.category),
                        )
                      : _ImagePlaceholder(category: package.category),
                ),

                // Category badge top-left
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${package.category.emoji}  ${package.category.label}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Featured badge top-right
                if (package.isFeatured)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '⭐ Featured',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                // Duration badge bottom-left
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🕐 ${package.durationLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Difficulty badge bottom-right
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(
                        package.difficulty.colorHex,
                      ).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      package.difficulty.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Content ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          package.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.col.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (package.averageRating > 0) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: Color(0xFFFBBF24),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              package.averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.col.textPrimary,
                              ),
                            ),
                            Text(
                              ' (${package.ratingsCount})',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.col.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 13,
                        color: context.col.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          package.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.col.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    package.tagline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.col.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Season chips
                  if (package.seasons.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: package.seasons.take(3).map((s) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${s.emoji} ${s.label.split(' ').first}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 10),
                  Divider(height: 1, color: context.col.border),
                  const SizedBox(height: 10),

                  // Price + CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Starting from',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.col.textMuted,
                            ),
                          ),
                          Text(
                            '₹${package.startingPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'per person',
                            style: TextStyle(
                              fontSize: 10,
                              color: context.col.textMuted,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
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

class _ImagePlaceholder extends StatelessWidget {
  final PackageCategory category;
  const _ImagePlaceholder({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.col.surfaceElevated,
      child: Center(
        child: Text(category.emoji, style: const TextStyle(fontSize: 48)),
      ),
    );
  }
}
