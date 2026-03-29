// lib/screens/ventures/my_bookings_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/booking_controller.dart';
import '../../controllers/feedback_controller.dart';
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

class _BookingCard extends ConsumerWidget {
  final VentureBooking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

                // ── Message from Operator ──────────────────────────
                if (booking.adminNote != null &&
                    booking.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(9)),
                          ),
                          child: Row(
                            children: [
                              Icon(Iconsax.message_text_1,
                                  size: 12, color: statusColor),
                              const SizedBox(width: 6),
                              Text(
                                'Message from Operator',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Note body
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            booking.adminNote!,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.col.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Bottom action row ────────────────────────────────
                const SizedBox(height: 10),
                Divider(height: 1, color: context.col.border),
                const SizedBox(height: 2),
                TextButton.icon(
                  onPressed: () => _showDetailSheet(context, ref),
                  icon: Icon(Iconsax.document_text,
                      size: 13, color: AppColors.primary),
                  label: Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(
        booking: booking,
        onFeedbackSubmit: (rating, comment) async {
          await ref.read(feedbackServiceProvider).submitFeedback(
                ventureId: booking.ventureId,
                ventureTitle: booking.ventureTitle,
                bookingId: booking.id,
                selectedPackageName: booking.selectedPackageName,
                rating: rating,
                comment: comment,
              );
        },
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

// ─────────────────────────────────────────────────────────────────────────────
// Feedback sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FeedbackSheet extends StatefulWidget {
  final VentureBooking booking;
  final Future<void> Function(int rating, String comment) onSubmit;

  const _FeedbackSheet({required this.booking, required this.onSubmit});

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_rating, _commentCtrl.text.trim());
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _submitted = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: col.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          if (_submitted) ...[
            // ── Success state ────────────────────────────────────────
            const SizedBox(height: 20),
            const Icon(Icons.verified_rounded,
                size: 56, color: Color(0xFF22C55E)),
            const SizedBox(height: 12),
            Text(
              'Thanks for your feedback!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: col.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your experience helps others discover great adventures.',
              style: TextStyle(fontSize: 13, color: col.textMuted, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
          ] else ...[
            // ── Header ───────────────────────────────────────────────
            Text(
              'Rate Your Experience',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: col.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              widget.booking.ventureTitle,
              style: TextStyle(fontSize: 13, color: col.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),

            // ── Star selector ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _rating = i + 1);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 42,
                      color: filled
                          ? const Color(0xFFF59E0B)
                          : col.textMuted.withValues(alpha: 0.4),
                    ),
                  ),
                );
              }),
            ),

            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Text(
                _ratingLabel(_rating),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _ratingColor(_rating),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Comment field ────────────────────────────────────────
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(fontSize: 14, color: col.textPrimary),
              decoration: InputDecoration(
                hintText:
                    'Share your experience — what did you enjoy, what could be better?',
                hintMaxLines: 2,
                hintStyle:
                    TextStyle(fontSize: 13, color: col.textMuted),
                filled: true,
                fillColor: col.bg,
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
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),

            const SizedBox(height: 16),

            // ── Submit button ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'Submit Feedback',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _ratingLabel(int r) => switch (r) {
        1 => 'Poor',
        2 => 'Fair',
        3 => 'Good',
        4 => 'Great',
        5 => 'Excellent!',
        _ => '',
      };

  Color _ratingColor(int r) => switch (r) {
        1 || 2 => AppColors.error,
        3 => const Color(0xFFF59E0B),
        _ => const Color(0xFF22C55E),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking detail sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BookingDetailSheet extends ConsumerStatefulWidget {
  final VentureBooking booking;
  final Future<void> Function(int rating, String comment) onFeedbackSubmit;

  const _BookingDetailSheet({
    required this.booking,
    required this.onFeedbackSubmit,
  });

  @override
  ConsumerState<_BookingDetailSheet> createState() =>
      _BookingDetailSheetState();
}

class _BookingDetailSheetState extends ConsumerState<_BookingDetailSheet> {
  // feedback state
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  VentureBooking get b => widget.booking;

  bool get _canFeedback =>
      b.status == BookingStatus.completed ||
      b.status == BookingStatus.confirmed;

  Color _statusColor(BookingStatus s) => switch (s) {
        BookingStatus.confirmed => const Color(0xFF22C55E),
        BookingStatus.cancelled => const Color(0xFFEF4444),
        BookingStatus.completed => const Color(0xFF3B82F6),
        BookingStatus.pending => const Color(0xFFF59E0B),
      };

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')} ${_months[dt.month - 1]} ${dt.year}';

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onFeedbackSubmit(_rating, _commentCtrl.text.trim());
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: \$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final statusColor = _statusColor(b.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Drag handle ──────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: col.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),

            // ── Header bar ───────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: col.textPrimary,
                      ),
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      b.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded,
                        size: 20, color: col.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: col.border),

            // ── Scrollable body ──────────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [

                  // ── Venture info card ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: col.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: col.border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: b.heroImage.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: b.heroImage,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 56,
                                    height: 56,
                                    color: statusColor
                                        .withValues(alpha: 0.12),
                                    child: Icon(
                                        Icons.landscape_rounded,
                                        color: statusColor
                                            .withValues(alpha: 0.5),
                                        size: 20),
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  color:
                                      statusColor.withValues(alpha: 0.12),
                                  child: Icon(Icons.landscape_rounded,
                                      color: statusColor
                                          .withValues(alpha: 0.5),
                                      size: 20),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.ventureTitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: col.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (b.location.isNotEmpty) ...[  
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded,
                                        size: 11, color: col.textMuted),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        b.location,
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: col.textMuted),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Booking summary rows ──────────────────────────
                  _DetailSection(
                    title: 'Booking Summary',
                    child: Column(
                      children: [
                        if (b.selectedPackageName != null)
                          _DetailRow(
                            icon: Iconsax.receipt_1,
                            label: 'Package',
                            value: b.selectedPackageName!,
                          ),
                        _DetailRow(
                          icon: Iconsax.people,
                          label: 'Persons',
                          value:
                              '${b.personCount} person${b.personCount > 1 ? 's' : ''}',
                        ),
                        if (b.pricePerPerson != null)
                          _DetailRow(
                            icon: Iconsax.money,
                            label: 'Price/person',
                            value: '₹${_fmt(b.pricePerPerson!)}',
                          ),
                        if (b.selectedAddons.isNotEmpty)
                          _DetailRow(
                            icon: Iconsax.add_circle,
                            label: 'Add-ons',
                            value: '+₹${_fmt(b.addonSubtotal)}',
                          ),
                        _DetailRow(
                          icon: Iconsax.wallet,
                          label: 'Total',
                          value: '₹${_fmt(b.grandTotal)}',
                          highlight: true,
                        ),
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Requested on',
                          value: _fmtDate(b.createdAt),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Operator info ─────────────────────────────────
                  if (b.operatorName.isNotEmpty)
                    _DetailSection(
                      title: 'Operator',
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Iconsax.user,
                            label: 'Name',
                            value: b.operatorName,
                          ),
                          if (b.operatorPhone.isNotEmpty)
                            _DetailRow(
                              icon: Iconsax.call,
                              label: 'Phone',
                              value: b.operatorPhone,
                            ),
                        ],
                      ),
                    ),
                  if (b.operatorName.isNotEmpty) const SizedBox(height: 14),

                  // ── Message from Operator ─────────────────────────
                  _DetailSection(
                    title: 'Message from Operator',
                    titleIcon: Iconsax.message_text_1,
                    titleColor: statusColor,
                    child: b.adminNote != null && b.adminNote!.isNotEmpty
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              b.adminNote!,
                              style: TextStyle(
                                fontSize: 13,
                                color: col.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: col.bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: col.border,
                                  style: BorderStyle.solid),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Iconsax.clock,
                                    size: 14, color: col.textMuted),
                                const SizedBox(width: 6),
                                Text(
                                  'The operator will add a note once\nyour booking is reviewed.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: col.textMuted,
                                      height: 1.4),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),

                  // ── Feedback section ──────────────────────────────
                  if (_canFeedback)
                    _DetailSection(
                      title: 'Your Experience',
                      titleIcon: Icons.star_rounded,
                      titleColor: const Color(0xFFF59E0B),
                      child: _submitted || b.hasFeedback
                          ? Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFF22C55E)
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.verified_rounded,
                                      size: 20,
                                      color: Color(0xFF22C55E)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Feedback submitted — thank you!',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF22C55E),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Star row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: List.generate(5, (i) {
                                    final filled = i < _rating;
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        setState(
                                            () => _rating = i + 1);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5),
                                        child: Icon(
                                          filled
                                              ? Icons.star_rounded
                                              : Icons.star_border_rounded,
                                          size: 38,
                                          color: filled
                                              ? const Color(0xFFF59E0B)
                                              : col.textMuted
                                                  .withValues(alpha: 0.35),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                if (_rating > 0) ...[  
                                  const SizedBox(height: 6),
                                  Center(
                                    child: Text(
                                      _ratingLabel(_rating),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _ratingColor(_rating),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                // Comment field
                                TextField(
                                  controller: _commentCtrl,
                                  maxLines: 3,
                                  maxLength: 500,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: TextStyle(
                                      fontSize: 13, color: col.textPrimary),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Share what you enjoyed or what could be better…',
                                    hintStyle: TextStyle(
                                        fontSize: 12, color: col.textMuted),
                                    filled: true,
                                    fillColor: col.bg,
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide:
                                          BorderSide(color: col.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide:
                                          BorderSide(color: col.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.all(12),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _submitting
                                        ? null
                                        : _submitFeedback,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                    child: _submitting
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black,
                                            ),
                                          )
                                        : const Text(
                                            'Submit Feedback',
                                            style: TextStyle(
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w700),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) => switch (r) {
        1 => 'Poor',
        2 => 'Fair',
        3 => 'Good',
        4 => 'Great',
        5 => 'Excellent!',
        _ => '',
      };

  Color _ratingColor(int r) => switch (r) {
        1 || 2 => AppColors.error,
        3 => const Color(0xFFF59E0B),
        _ => const Color(0xFF22C55E),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail sheet helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData? titleIcon;
  final Color? titleColor;
  final Widget child;

  const _DetailSection({
    required this.title,
    required this.child,
    this.titleIcon,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    final color = titleColor ?? col.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (titleIcon != null) ...[  
              Icon(titleIcon, size: 13, color: color),
              const SizedBox(width: 5),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String value;
  final bool highlight;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.col;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon as IconData, size: 13, color: col.textMuted),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: col.textMuted),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  highlight ? FontWeight.w800 : FontWeight.w500,
              color: highlight ? AppColors.primary : col.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
