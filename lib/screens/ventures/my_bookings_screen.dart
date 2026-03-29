// lib/screens/ventures/my_bookings_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/booking_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';

// ─────────────────────────────────────────────────────────────────────────────

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: context.col.bg,
          title: const Text('My Bookings'),
        ),
        body: const Center(
          child: Text('Please sign in to view your bookings.'),
        ),
      );
    }

    final bookingsAsync = ref.watch(userBookingsProvider(user.id));

    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        elevation: 0,
        title: Text(
          'My Bookings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.col.textPrimary,
          ),
        ),
      ),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load bookings: $e',
              style: TextStyle(color: context.col.textMuted)),
        ),
        data: (bookings) {
          if (bookings.isEmpty) return const _EmptyState();

          final pending =
              bookings.where((b) => b.status == BookingStatus.pending).length;
          final confirmed =
              bookings.where((b) => b.status == BookingStatus.confirmed).length;
          final completed =
              bookings.where((b) => b.status == BookingStatus.completed).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // ── Summary banner ──────────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: context.col.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.col.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryChip(
                        '${bookings.length}', 'Total', context.col.textPrimary),
                    _SummaryChip('$pending', 'Pending', const Color(0xFFF59E0B)),
                    _SummaryChip(
                        '$confirmed', 'Confirmed', const Color(0xFF22C55E)),
                    _SummaryChip(
                        '$completed', 'Completed', const Color(0xFF3B82F6)),
                  ],
                ),
              ),

              // ── Booking cards ───────────────────────────────────────────
              ...bookings.map((b) => _BookingCard(booking: b)),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary chip
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _SummaryChip(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.col.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking card
// ─────────────────────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final VentureBooking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);
    final dateStr = _fmtDate(booking.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status colour strip ───────────────────────────────────────
          Container(
            height: 4,
            color: statusColor,
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero + title + status badge ─────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: booking.heroImage.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: booking.heroImage,
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _imgPlaceholder(statusColor),
                            )
                          : _imgPlaceholder(statusColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.ventureTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.col.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (booking.location.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    size: 11,
                                    color: context.col.textMuted),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    booking.location,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.col.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        booking.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: context.col.border),
                const SizedBox(height: 10),

                // ── Package + guests + total ─────────────────────────
                Row(
                  children: [
                    if (booking.selectedPackageName != null) ...[
                      Icon(Iconsax.receipt_1,
                          size: 13, color: context.col.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          booking.selectedPackageName!,
                          style: TextStyle(
                              fontSize: 12,
                              color: context.col.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(Iconsax.people,
                        size: 13, color: context.col.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${booking.personCount} '
                      'person${booking.personCount > 1 ? 's' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: context.col.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      '₹${_fmt(booking.grandTotal)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),
                Text(
                  'Requested on $dateStr',
                  style:
                      TextStyle(fontSize: 11, color: context.col.textMuted),
                ),

                // ── Admin note ────────────────────────────────────────
                if (booking.adminNote != null &&
                    booking.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Iconsax.message_2, size: 13, color: statusColor),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            booking.adminNote!,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.col.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── View venture button ───────────────────────────────
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context
                      .push(AppRoutes.ventureDetailPath(booking.ventureId)),
                  child: Text(
                    'View venture →',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder(Color color) => Container(
        width: 58,
        height: 58,
        color: color.withValues(alpha: 0.12),
        alignment: Alignment.center,
        child:
            Icon(Icons.landscape_rounded, color: color.withValues(alpha: 0.6), size: 22),
      );

  Color _statusColor(BookingStatus s) => switch (s) {
        BookingStatus.confirmed => const Color(0xFF22C55E),
        BookingStatus.cancelled => const Color(0xFFEF4444),
        BookingStatus.completed => const Color(0xFF3B82F6),
        BookingStatus.pending => const Color(0xFFF59E0B),
      };

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} ${_months[dt.month - 1]} ${dt.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Iconsax.ticket, size: 38, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.col.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you request a booking, it will appear\nhere so you can track its status.',
              style: TextStyle(
                  fontSize: 13, color: context.col.textMuted, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.explore_rounded, size: 16),
              label: const Text('Explore Ventures'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
