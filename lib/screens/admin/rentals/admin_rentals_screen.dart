// lib/screens/admin/rentals/admin_rentals_screen.dart
//
// Admin panel for managing Equipment Rentals.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../../controllers/rental_controller.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/rental_models.dart';

class AdminRentalsScreen extends ConsumerWidget {
  const AdminRentalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rentalsAsync = ref.watch(allRentalsProvider);

    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        elevation: 0,
        title: Text(
          'Equipment Rentals',
          style: TextStyle(
            color: context.col.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add, color: AppColors.primary),
            tooltip: 'Add Rental',
            onPressed: () => context.push(AppRoutes.adminAddRental),
          ),
        ],
      ),
      body: rentalsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error loading rentals',
            style: TextStyle(color: context.col.textSecondary),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(
              onAdd: () => context.push(AppRoutes.adminAddRental),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _RentalTile(
              item: items[i],
              onEdit: () => context.push(
                AppRoutes.adminEditRentalPath(items[i].id),
              ),
              onDelete: () => _confirmDelete(ctx, ref, items[i]),
              onToggleAvailability: () => ref
                  .read(rentalServiceProvider)
                  .setAvailability(
                    items[i].id,
                    available: !items[i].isAvailable,
                  ),
              onToggleFeatured: () => ref
                  .read(rentalServiceProvider)
                  .setFeatured(
                    items[i].id,
                    featured: !items[i].isFeatured,
                  ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add),
        label: const Text('Add Rental'),
        onPressed: () => context.push(AppRoutes.adminAddRental),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RentalItem item,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Rental'),
        content: Text('Delete "${item.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(rentalServiceProvider).delete(item.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _RentalTile extends StatelessWidget {
  final RentalItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;
  final VoidCallback onToggleFeatured;

  const _RentalTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
    required this.onToggleFeatured,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.firstImageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.firstImageUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _Placeholder(),
                    )
                  : _Placeholder(),
            ),
            title: Text(
              item.name,
              style: TextStyle(
                color: context.col.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  item.category.label,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${item.pricePerDay.toStringAsFixed(0)}/day'
                  '${item.pricePerHour != null ? ' · ₹${item.pricePerHour!.toStringAsFixed(0)}/hr' : ''}',
                  style: TextStyle(
                    color: context.col.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Iconsax.edit, size: 18, color: AppColors.info),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(
                    Iconsax.trash,
                    size: 18,
                    color: AppColors.error,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.col.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                _StatusChip(
                  label: item.isAvailable ? 'Available' : 'Unavailable',
                  color:
                      item.isAvailable ? AppColors.success : AppColors.error,
                  onTap: onToggleAvailability,
                ),
                const SizedBox(width: 8),
                _StatusChip(
                  label: item.isFeatured ? 'Featured' : 'Not Featured',
                  color: item.isFeatured
                      ? AppColors.warning
                      : context.col.textMuted,
                  onTap: onToggleFeatured,
                ),
                const Spacer(),
                Text(
                  'Qty: ${item.quantityAvailable}',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.col.textSecondary,
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Iconsax.box, size: 24, color: AppColors.primary),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.box, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'No Equipment Rentals',
            style: TextStyle(
              color: context.col.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add rental items for visitors to hire.',
            style: TextStyle(color: context.col.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Iconsax.add),
            label: const Text('Add First Rental'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
