// lib/screens/admin/rentals/admin_rental_tracking_screen.dart
//
// Rental Tracking — tracks purchases, rent periods, and inventory for the
// super admin.  Three tabs: Active Rentals | History | Inventory.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../controllers/rental_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/rental_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AdminRentalTrackingScreen extends ConsumerStatefulWidget {
  const AdminRentalTrackingScreen({super.key});

  @override
  ConsumerState<AdminRentalTrackingScreen> createState() =>
      _AdminRentalTrackingScreenState();
}

class _AdminRentalTrackingScreenState
    extends ConsumerState<AdminRentalTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final allAsync = ref.watch(allBookingsProvider);
    final activeAsync = ref.watch(activeBookingsProvider);

    return Scaffold(
      backgroundColor: col.bg,
      appBar: AppBar(
        backgroundColor: col.bg,
        elevation: 0,
        title: Text(
          'Rental Tracking',
          style: TextStyle(
            color: col.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add_circle, color: AppColors.primary),
            tooltip: 'Log Booking',
            onPressed: () => _showAddBookingSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: col.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
            Tab(text: 'Inventory'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Stats bar ──────────────────────────────────────────────────────
          allAsync.when(
            loading: () => const _StatsBarShimmer(),
            error: (_, _) => const SizedBox.shrink(),
            data: (bookings) => _StatsBar(bookings: bookings),
          ),
          // ── Tab views ──────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                // ── Active Tab ────────────────────────────────────────────
                activeAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => _ErrorView(message: e.toString()),
                  data: (bookings) => _ActiveTab(bookings: bookings),
                ),
                // ── History Tab ───────────────────────────────────────────
                allAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => _ErrorView(message: e.toString()),
                  data: (bookings) {
                    final history = bookings
                        .where(
                          (b) =>
                              b.status != RentalBookingStatus.active,
                        )
                        .toList();
                    return _HistoryTab(bookings: history);
                  },
                ),
                // ── Inventory Tab ─────────────────────────────────────────
                allAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (e, _) => _ErrorView(message: e.toString()),
                  data: (bookings) => _InventoryTab(
                    allBookings: bookings,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.add),
        label: const Text('Log Booking'),
        onPressed: () => _showAddBookingSheet(context),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Add booking sheet
  // ─────────────────────────────────────────────────────────────────────────

  void _showAddBookingSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddBookingSheet(
        onSave: (booking) async {
          await ref.read(rentalServiceProvider).createBooking(booking);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats bar
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final List<RentalBooking> bookings;
  const _StatsBar({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final active = bookings
        .where((b) => b.status == RentalBookingStatus.active)
        .length;
    final overdue = bookings.where((b) => b.isEffectivelyOverdue).length;
    final returned = bookings
        .where((b) => b.status == RentalBookingStatus.returned)
        .length;
    final revenue = bookings
        .where((b) => b.status == RentalBookingStatus.returned)
        .fold<double>(0, (sum, b) => sum + b.totalAmount);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Row(
        children: [
          _StatCell(
            label: 'Active',
            value: '$active',
            color: AppColors.primary,
            icon: Iconsax.clock,
          ),
          _Vdivider(),
          _StatCell(
            label: 'Overdue',
            value: '$overdue',
            color: AppColors.error,
            icon: Iconsax.warning_2,
          ),
          _Vdivider(),
          _StatCell(
            label: 'Returned',
            value: '$returned',
            color: AppColors.success,
            icon: Iconsax.tick_circle,
          ),
          _Vdivider(),
          _StatCell(
            label: 'Revenue',
            value: '₹${_fmt(revenue)}',
            color: const Color(0xFF06B6D4),
            icon: Iconsax.money,
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _StatCell extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: context.col.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Vdivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: context.col.border);
}

class _StatsBarShimmer extends StatelessWidget {
  const _StatsBarShimmer();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      height: 72,
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active tab
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveTab extends ConsumerWidget {
  final List<RentalBooking> bookings;
  const _ActiveTab({required this.bookings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) {
      return _EmptyView(
        icon: Iconsax.clock,
        message: 'No active rentals',
        sub: 'Log a booking using the + button',
      );
    }

    // Put overdue first
    final sorted = [...bookings]..sort((a, b) {
        final ao = a.isEffectivelyOverdue ? 0 : 1;
        final bo = b.isEffectivelyOverdue ? 0 : 1;
        if (ao != bo) return ao - bo;
        return a.endDate.compareTo(b.endDate);
      });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _BookingCard(
        booking: sorted[i],
        onAction: (action) => _handleAction(ctx, ref, sorted[i], action),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    RentalBooking booking,
    _BookingAction action,
  ) async {
    final svc = ref.read(rentalServiceProvider);
    switch (action) {
      case _BookingAction.markReturned:
        await svc.markReturned(booking.id);
      case _BookingAction.markOverdue:
        await svc.markOverdue(booking.id);
      case _BookingAction.cancel:
        await svc.cancelBooking(booking.id);
      case _BookingAction.extend:
        if (context.mounted) {
          await _showExtendSheet(context, ref, booking);
        }
    }
  }

  Future<void> _showExtendSheet(
    BuildContext context,
    WidgetRef ref,
    RentalBooking booking,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.col.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ExtendSheet(
        booking: booking,
        onSave: (date) async {
          await ref.read(rentalServiceProvider).extendBooking(booking.id, date);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History tab
// ─────────────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<RentalBooking> bookings;
  const _HistoryTab({required this.bookings});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return _EmptyView(
        icon: Iconsax.document,
        message: 'No rental history yet',
        sub: 'Completed bookings will appear here',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) => _BookingCard(
        booking: bookings[i],
        onAction: null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inventory tab
// ─────────────────────────────────────────────────────────────────────────────

class _InventoryTab extends ConsumerWidget {
  final List<RentalBooking> allBookings;
  const _InventoryTab({required this.allBookings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(allRentalsProvider);

    return itemsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyView(
            icon: Iconsax.box,
            message: 'No rental items',
            sub: 'Add items from the Equipment Rentals screen',
          );
        }

        // Count currently active quantity per item
        final activeQtyByItem = <String, int>{};
        for (final b in allBookings) {
          if (b.status == RentalBookingStatus.active) {
            activeQtyByItem[b.itemId] =
                (activeQtyByItem[b.itemId] ?? 0) + b.quantityRented;
          }
        }

        // Count total bookings per item for sorting
        final totalBookingsByItem = <String, int>{};
        for (final b in allBookings) {
          totalBookingsByItem[b.itemId] =
              (totalBookingsByItem[b.itemId] ?? 0) + 1;
        }

        final sorted = [...items]..sort(
            (a, b) =>
                (totalBookingsByItem[b.id] ?? 0) -
                (totalBookingsByItem[a.id] ?? 0),
          );

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (ctx, i) {
            final item = sorted[i];
            final activeQty = activeQtyByItem[item.id] ?? 0;
            final available = (item.quantityAvailable - activeQty).clamp(
              0,
              item.quantityAvailable,
            );
            final total = totalBookingsByItem[item.id] ?? 0;
            return _InventoryCard(
              item: item,
              activeRented: activeQty,
              available: available,
              totalBookings: total,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking card
// ─────────────────────────────────────────────────────────────────────────────

enum _BookingAction { markReturned, markOverdue, cancel, extend }

class _BookingCard extends StatelessWidget {
  final RentalBooking booking;
  final void Function(_BookingAction)? onAction;

  const _BookingCard({required this.booking, required this.onAction});

  Color _statusColor(RentalBookingStatus s, bool overdue) {
    if (overdue) return AppColors.error;
    return switch (s) {
      RentalBookingStatus.active => AppColors.primary,
      RentalBookingStatus.returned => AppColors.success,
      RentalBookingStatus.overdue => AppColors.error,
      RentalBookingStatus.cancelled => const Color(0xFF94A3B8),
    };
  }

  String _statusLabel(RentalBookingStatus s, bool overdue) {
    if (overdue) return 'Overdue';
    return s.label;
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final overdue = booking.isEffectivelyOverdue;
    final statusColor = _statusColor(booking.status, overdue);
    final statusLabel = _statusLabel(booking.status, overdue);
    final fmt = DateFormat('dd MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: overdue
              ? AppColors.error.withValues(alpha: 0.4)
              : col.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: booking.itemImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: booking.itemImageUrl!,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _ImgPlaceholder(),
                        )
                      : _ImgPlaceholder(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.itemName,
                              style: TextStyle(
                                color: col.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Status chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        RentalCategory.fromString(booking.itemCategory).label,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ── Renter info ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: col.bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.user, size: 14, color: col.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.renterName.isEmpty
                          ? 'Unknown Renter'
                          : booking.renterName,
                      style: TextStyle(
                        color: col.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (booking.renterPhone.isNotEmpty) ...[
                    Icon(Iconsax.call, size: 13, color: col.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      booking.renterPhone,
                      style: TextStyle(color: col.textSecondary, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── Dates + financials ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(Iconsax.calendar, size: 14, color: col.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${fmt.format(booking.startDate)} → ${fmt.format(booking.endDate)}',
                  style: TextStyle(color: col.textSecondary, fontSize: 12),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${booking.rentalDays}d)',
                  style: TextStyle(
                    color: col.textMuted,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Icon(Iconsax.money, size: 14, color: AppColors.success),
                const SizedBox(width: 4),
                Text(
                  '₹${booking.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (booking.quantityRented > 1) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'Qty rented: ${booking.quantityRented}',
                style: TextStyle(color: col.textMuted, fontSize: 11),
              ),
            ),
          ],
          if (booking.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Iconsax.note, size: 13, color: col.textMuted),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      booking.notes,
                      style: TextStyle(
                        color: col.textMuted,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // ── Action buttons (only for active bookings) ────────────────────
          if (onAction != null) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: col.border),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              child: Row(
                children: [
                  _ActionBtn(
                    label: 'Returned',
                    icon: Iconsax.tick_circle,
                    color: AppColors.success,
                    onTap: () => onAction!(_BookingAction.markReturned),
                  ),
                  _ActionBtn(
                    label: 'Extend',
                    icon: Iconsax.calendar_add,
                    color: AppColors.info,
                    onTap: () => onAction!(_BookingAction.extend),
                  ),
                  _ActionBtn(
                    label: 'Overdue',
                    icon: Iconsax.warning_2,
                    color: AppColors.warning,
                    onTap: () => onAction!(_BookingAction.markOverdue),
                  ),
                  _ActionBtn(
                    label: 'Cancel',
                    icon: Iconsax.close_circle,
                    color: AppColors.error,
                    onTap: () => onAction!(_BookingAction.cancel),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inventory card
// ─────────────────────────────────────────────────────────────────────────────

class _InventoryCard extends StatelessWidget {
  final RentalItem item;
  final int activeRented;
  final int available;
  final int totalBookings;

  const _InventoryCard({
    required this.item,
    required this.activeRented,
    required this.available,
    required this.totalBookings,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final utilRate = item.quantityAvailable > 0
        ? activeRented / item.quantityAvailable
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: col.border),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.firstImageUrl != null
                ? CachedNetworkImage(
                    imageUrl: item.firstImageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _ImgPlaceholder(),
                  )
                : _ImgPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: col.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.category.label,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Utilisation bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: utilRate.clamp(0.0, 1.0),
                    backgroundColor: col.border,
                    color: utilRate >= 0.9
                        ? AppColors.error
                        : utilRate >= 0.6
                        ? AppColors.warning
                        : AppColors.primary,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _InventoryChip(
                      label: 'Total ${item.quantityAvailable}',
                      color: col.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    _InventoryChip(
                      label: 'Rented $activeRented',
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 6),
                    _InventoryChip(
                      label: 'Free $available',
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalBookings',
                style: TextStyle(
                  color: col.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'bookings',
                style: TextStyle(color: col.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _InventoryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Booking bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _AddBookingSheet extends ConsumerStatefulWidget {
  final Future<void> Function(RentalBooking) onSave;
  const _AddBookingSheet({required this.onSave});

  @override
  ConsumerState<_AddBookingSheet> createState() => _AddBookingSheetState();
}

class _AddBookingSheetState extends ConsumerState<_AddBookingSheet> {
  final _formKey = GlobalKey<FormState>();
  final _renterNameCtrl = TextEditingController();
  final _renterPhoneCtrl = TextEditingController();
  final _renterEmailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');

  RentalItem? _selectedItem;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;

  @override
  void dispose() {
    _renterNameCtrl.dispose();
    _renterPhoneCtrl.dispose();
    _renterEmailCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _recalcAmount() {
    if (_selectedItem == null) return;
    final days = _endDate.difference(_startDate).inDays.abs() + 1;
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    final total = _selectedItem!.pricePerDay * days * qty;
    _amountCtrl.text = total.toStringAsFixed(0);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final first = isStart ? DateTime.now() : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            surface: context.col.surface,
            onSurface: context.col.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      } else {
        _endDate = picked;
      }
      _recalcAmount();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rental item')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final booking = RentalBooking(
        id: '',
        itemId: _selectedItem!.id,
        itemName: _selectedItem!.name,
        itemCategory: _selectedItem!.category.value,
        itemImageUrl: _selectedItem!.firstImageUrl,
        pricePerDay: _selectedItem!.pricePerDay,
        pricePerHour: _selectedItem!.pricePerHour,
        renterName: _renterNameCtrl.text.trim(),
        renterPhone: _renterPhoneCtrl.text.trim(),
        renterEmail: _renterEmailCtrl.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        quantityRented: int.tryParse(_qtyCtrl.text.trim()) ?? 1,
        totalAmount:
            double.tryParse(_amountCtrl.text.trim()) ?? 0,
        notes: _notesCtrl.text.trim(),
      );
      await widget.onSave(booking);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking logged!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final itemsAsync = ref.watch(allRentalsProvider);
    final fmt = DateFormat('dd MMM yyyy');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: col.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Log New Booking',
              style: TextStyle(
                color: col.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 16),

            // Item selector
            _Label('Rental Item *'),
            const SizedBox(height: 6),
            itemsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Error loading items'),
              data: (items) => DropdownButtonFormField<RentalItem>(
                initialValue: _selectedItem,
                hint: Text(
                  'Select item',
                  style: TextStyle(color: col.textMuted, fontSize: 13),
                ),
                decoration: _inputDeco(col, ''),
                dropdownColor: col.surface,
                style: TextStyle(color: col.textPrimary, fontSize: 14),
                items: items
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          '${item.name} — ₹${item.pricePerDay.toStringAsFixed(0)}/day',
                          style: TextStyle(
                            color: col.textPrimary,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedItem = v;
                    _recalcAmount();
                  });
                },
                validator: (_) =>
                    _selectedItem == null ? 'Required' : null,
              ),
            ),
            const SizedBox(height: 14),

            // Renter details
            _Label('Renter Name *'),
            const SizedBox(height: 6),
            _Field(
              controller: _renterNameCtrl,
              hint: 'Full name',
              col: col,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            _Label('Phone *'),
            const SizedBox(height: 6),
            _Field(
              controller: _renterPhoneCtrl,
              hint: 'Contact number',
              col: col,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            _Label('Email (optional)'),
            const SizedBox(height: 6),
            _Field(
              controller: _renterEmailCtrl,
              hint: 'Email address',
              col: col,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            // Dates
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Start Date *'),
                      const SizedBox(height: 6),
                      _DateTile(
                        label: fmt.format(_startDate),
                        col: col,
                        onTap: () => _pickDate(isStart: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('End Date *'),
                      const SizedBox(height: 6),
                      _DateTile(
                        label: fmt.format(_endDate),
                        col: col,
                        onTap: () => _pickDate(isStart: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Quantity + total
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Quantity'),
                      const SizedBox(height: 6),
                      _Field(
                        controller: _qtyCtrl,
                        hint: '1',
                        col: col,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(_recalcAmount),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Label('Total Amount (₹) *'),
                      const SizedBox(height: 6),
                      _Field(
                        controller: _amountCtrl,
                        hint: 'Auto-calculated',
                        col: col,
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Notes
            _Label('Notes (optional)'),
            const SizedBox(height: 6),
            _Field(
              controller: _notesCtrl,
              hint: 'Any additional info…',
              col: col,
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Save Booking',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extend booking sheet
// ─────────────────────────────────────────────────────────────────────────────

class _ExtendSheet extends ConsumerStatefulWidget {
  final RentalBooking booking;
  final Future<void> Function(DateTime) onSave;

  const _ExtendSheet({required this.booking, required this.onSave});

  @override
  ConsumerState<_ExtendSheet> createState() => _ExtendSheetState();
}

class _ExtendSheetState extends ConsumerState<_ExtendSheet> {
  late DateTime _newEnd;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _newEnd = widget.booking.endDate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _newEnd,
      firstDate: widget.booking.endDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            surface: context.col.surface,
            onSurface: context.col.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _newEnd = picked);
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final fmt = DateFormat('dd MMM yyyy');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: col.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Extend Rental Period',
                  style: TextStyle(
                    color: col.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.booking.itemName,
                  style: TextStyle(
                    color: col.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: col.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: col.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current End',
                              style: TextStyle(
                                color: col.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fmt.format(widget.booking.endDate),
                              style: TextStyle(
                                color: col.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New End Date',
                                style: TextStyle(
                                  color: col.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                fmt.format(_newEnd),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            setState(() => _isSaving = true);
                            final navigator = Navigator.of(context);
                            try {
                              await widget.onSave(_newEnd);
                              if (mounted) navigator.pop();
                            } finally {
                              if (mounted) {
                                setState(() => _isSaving = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Confirm Extension',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ImgPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Iconsax.box, size: 22, color: AppColors.primary),
      );
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String message, sub;
  const _EmptyView({
    required this.icon,
    required this.message,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: context.col.textMuted),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              color: context.col.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(color: context.col.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          'Error: $message',
          style: TextStyle(color: context.col.textSecondary),
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.col.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final AppColorScheme col;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    required this.col,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: TextStyle(color: col.textPrimary, fontSize: 14),
      decoration: _inputDeco(col, hint),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final AppColorScheme col;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.col,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: col.border),
        ),
        child: Row(
          children: [
            Icon(Iconsax.calendar, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: col.textPrimary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDeco(AppColorScheme col, String hint) {
  return InputDecoration(
    hintText: hint.isEmpty ? null : hint,
    hintStyle: TextStyle(color: col.textMuted, fontSize: 13),
    filled: true,
    fillColor: col.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: col.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: col.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
  );
}
