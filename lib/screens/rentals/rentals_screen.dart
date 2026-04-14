// lib/screens/rentals/rentals_screen.dart
//
// Public "Equipment Rentals" listing screen.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../controllers/rental_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/rental_models.dart';

class RentalsScreen extends ConsumerStatefulWidget {
  const RentalsScreen({super.key});

  @override
  ConsumerState<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends ConsumerState<RentalsScreen> {
  RentalCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final rentalsAsync = _selectedCategory == null
        ? ref.watch(allRentalsProvider)
        : ref.watch(rentalsByCategoryProvider(_selectedCategory!));

    return Scaffold(
      backgroundColor: context.col.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: context.col.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Iconsax.arrow_left, color: context.col.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Equipment Rentals',
              style: TextStyle(
                color: context.col.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: _CategoryFilter(
                selected: _selectedCategory,
                onSelected: (cat) => setState(() => _selectedCategory = cat),
              ),
            ),
          ),
        ],
        body: rentalsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => _ErrorState(message: e.toString()),
          data: (items) {
            final available = items.where((i) => i.isAvailable).toList();
            if (available.isEmpty) {
              return const _EmptyState();
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: available.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (ctx, i) => RentalItemCard(item: available[i])
                  .animate()
                  .fadeIn(delay: (i * 40).ms, duration: 250.ms)
                  .slideY(begin: 0.08, end: 0),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category filter scroll row
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryFilter extends StatelessWidget {
  final RentalCategory? selected;
  final ValueChanged<RentalCategory?> onSelected;

  const _CategoryFilter({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          _FilterChip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          ...RentalCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: cat.label,
                selected: selected == cat,
                onTap: () =>
                    onSelected(selected == cat ? null : cat),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : context.col.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : context.col.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : context.col.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rental Item Card (shared — also used on home screen via import)
// ─────────────────────────────────────────────────────────────────────────────

class RentalItemCard extends StatelessWidget {
  final RentalItem item;

  const RentalItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.col.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ────────────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: item.firstImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.firstImageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _ImagePlaceholder(),
                      errorWidget: (_, _, _) => _ImagePlaceholder(),
                    )
                  : _ImagePlaceholder(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tags row ──────────────────────────────────────────────
                Row(
                  children: [
                    _Chip(
                      label: item.category.label,
                      color: AppColors.primary,
                    ),
                    if (item.isFeatured) ...[
                      const SizedBox(width: 6),
                      _Chip(label: 'Featured', color: AppColors.warning),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // ── Name ──────────────────────────────────────────────────
                Text(
                  item.name,
                  style: TextStyle(
                    color: context.col.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.col.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // ── Pricing row ───────────────────────────────────────────
                Row(
                  children: [
                    Icon(Iconsax.tag, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '₹${item.pricePerDay.toStringAsFixed(0)} / day',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (item.pricePerHour != null) ...[
                      Text(
                        '  ·  ₹${item.pricePerHour!.toStringAsFixed(0)} / hr',
                        style: TextStyle(
                          color: context.col.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // ── Location & quantity ───────────────────────────────────
                Row(
                  children: [
                    Icon(
                      Iconsax.location,
                      size: 13,
                      color: context.col.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [
                          if (item.location.isNotEmpty) item.location,
                          if (item.district.isNotEmpty) item.district,
                        ].join(', '),
                        style: TextStyle(
                          color: context.col.textMuted,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Iconsax.box, size: 13, color: context.col.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Qty: ${item.quantityAvailable}',
                      style: TextStyle(
                        color: context.col.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // ── Specs ────────────────────────────────────────────────
                if (item.specifications.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: item.specifications.entries
                        .take(4)
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: context.col.surfaceElevated,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: context.col.border),
                            ),
                            child: Text(
                              '${e.key}: ${e.value}',
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

                // ── Contact ──────────────────────────────────────────────
                if (item.contactPhone.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Iconsax.call,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.contactPhone,
                        style: TextStyle(
                          color: context.col.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (item.contactName.isNotEmpty) ...[
                        Text(
                          '  (${item.contactName})',
                          style: TextStyle(
                            color: context.col.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: const Center(
        child: Icon(Iconsax.box, size: 40, color: AppColors.primary),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.box, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'No Rentals Available',
            style: TextStyle(
              color: context.col.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for equipment rentals.',
            style: TextStyle(color: context.col.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error: $message',
        style: TextStyle(color: context.col.textSecondary),
      ),
    );
  }
}
