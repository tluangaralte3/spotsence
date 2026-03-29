// lib/screens/ventures/booking_review_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/booking_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data class passed from VenturePublicDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class BookingReviewArgs {
  final String ventureId;
  final String ventureTitle;
  final String heroImage;
  final String category;
  final String location;
  final String operatorName;
  final String operatorPhone;
  final String operatorWhatsapp;
  final String operatorEmail;

  // Package
  final String? selectedPackageName;
  final String? selectedPackageDesc;
  final double? pricePerPerson;

  // People
  final int personCount;

  // Add-ons: list of {name, emoji, pricePerUnit, unit, qty}
  final List<Map<String, dynamic>> selectedAddons;

  const BookingReviewArgs({
    required this.ventureId,
    required this.ventureTitle,
    required this.heroImage,
    required this.category,
    required this.location,
    required this.operatorName,
    required this.operatorPhone,
    required this.operatorWhatsapp,
    required this.operatorEmail,
    this.selectedPackageName,
    this.selectedPackageDesc,
    this.pricePerPerson,
    required this.personCount,
    required this.selectedAddons,
  });

  double get addonSubtotal => selectedAddons.fold(
        0,
        (sum, a) =>
            sum +
            ((double.tryParse('${a['pricePerUnit']}') ?? 0) *
                ((a['qty'] as int? ?? 1))),
      );

  double get totalPerPerson => (pricePerPerson ?? 0) + addonSubtotal;

  double get grandTotal => totalPerPerson * personCount;
}

// ─────────────────────────────────────────────────────────────────────────────
// BookingReviewScreen
// ─────────────────────────────────────────────────────────────────────────────

class BookingReviewScreen extends ConsumerStatefulWidget {
  final BookingReviewArgs args;
  const BookingReviewScreen({super.key, required this.args});

  @override
  ConsumerState<BookingReviewScreen> createState() =>
      _BookingReviewScreenState();
}

class _BookingReviewScreenState extends ConsumerState<BookingReviewScreen> {
  bool _submitting = false;
  final _primaryPhoneCtrl = TextEditingController();
  final _secondaryPhoneCtrl = TextEditingController();
  // Tracks whether the user has tried to submit (to show validation errors)
  bool _triedSubmit = false;

  @override
  void dispose() {
    _primaryPhoneCtrl.dispose();
    _secondaryPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final args = widget.args;

    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        elevation: 0,
        title: Text(
          'Review Booking',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.col.textPrimary,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
            color: context.col.surface,
            border: Border(top: BorderSide(color: context.col.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Grand total row ──────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.col.textMuted,
                          ),
                        ),
                        Text(
                          '₹${_fmt(args.grandTotal)}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                        if (args.personCount > 1)
                          Text(
                            '₹${_fmt(args.totalPerPerson)} × ${args.personCount} people',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.col.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),                  // WhatsApp secondary option
                  if (args.operatorWhatsapp.isNotEmpty ||
                      args.operatorPhone.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _launchWhatsapp(
                        args.operatorWhatsapp.isNotEmpty
                            ? args.operatorWhatsapp
                            : args.operatorPhone,
                        args,
                        user?.displayName,
                        primaryPhone: _primaryPhoneCtrl.text.trim(),
                        secondaryPhone: _secondaryPhoneCtrl.text.trim(),
                      ),
                      icon: const Icon(
                        Iconsax.message,
                        size: 15,
                        color: Color(0xFF25D366),
                      ),
                      label: const Text(
                        'WhatsApp',
                        style: TextStyle(
                          color: Color(0xFF25D366),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF25D366), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                    ),                ],
              ),
              const SizedBox(height: 12),
              // ── Primary CTA ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting
                      ? null
                      : () {
                          setState(() => _triedSubmit = true);
                          final primary = _primaryPhoneCtrl.text.trim();
                          if (primary.isEmpty) {
                            _showTopToast(
                              context,
                              'Please enter your primary phone number to continue.',
                              isError: true,
                            );
                            return;
                          }
                          if (!_isValidPhone(primary)) {
                            _showTopToast(
                              context,
                              'Enter a valid phone number (e.g. +91 98765 43210).',
                              isError: true,
                            );
                            return;
                          }
                          _confirmBooking(
                            context,
                            userId: user?.id,
                            userName: user?.displayName,
                            userEmail: user?.email,
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.black),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.confirmation_num_outlined,
                                size: 18, color: Colors.black),
                            SizedBox(width: 8),
                            Text(
                              'Confirm Booking Request',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          // ── Hero card ────────────────────────────────────────────────
          _SectionCard(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: args.heroImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: args.heroImage,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _imgBox(const Color(0xFF4CAF50)),
                        )
                      : _imgBox(AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        args.ventureTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.col.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (args.location.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 12,
                                color: context.col.textMuted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                args.location,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.col.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      if (args.operatorName.isNotEmpty)
                        Text(
                          'by ${args.operatorName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Your details ─────────────────────────────────────────────
          _SectionHeader(
            icon: Iconsax.user,
            title: 'Your Details',
            color: AppColors.secondary,
          ),
          const SizedBox(height: 8),
          _SectionCard(
            child: user == null
                ? Text(
                    'Not signed in — please log in to proceed.',
                    style: TextStyle(
                      color: context.col.textMuted,
                      fontSize: 13,
                    ),
                  )
                : Column(
                    children: [
                      _InfoRow(
                        icon: Iconsax.user,
                        label: 'Name',
                        value: user.displayName,
                      ),
                      _InfoRow(
                        icon: Iconsax.sms,
                        label: 'Email',
                        value: user.email,
                      ),
                      if (user.location != null &&
                          user.location!.isNotEmpty)
                        _InfoRow(
                          icon: Iconsax.location,
                          label: 'Location',
                          value: user.location!,
                          isLast: true,
                        )
                      else
                        _InfoRow(
                          icon: Iconsax.people,
                          label: 'People',
                          value:
                              '${args.personCount} person${args.personCount > 1 ? 's' : ''}',
                          isLast: true,
                        ),
                    ],
                  ),
          ),

          const SizedBox(height: 14),

          // ── People count ─────────────────────────────────────────────
          _SectionHeader(
            icon: Iconsax.people,
            title: 'Number of Guests',
            color: const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 8),
          _SectionCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Iconsax.people,
                      color: Color(0xFF0EA5E9), size: 20),
                ),
                const SizedBox(width: 14),
                Text(
                  '${args.personCount}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  args.personCount == 1 ? 'person' : 'people',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.col.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Selected package ─────────────────────────────────────────
          _SectionHeader(
            icon: Iconsax.receipt_1,
            title: 'Pricing Package',
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          _SectionCard(
            child: args.selectedPackageName == null
                ? Text(
                    'No package selected — base starting price applies.',
                    style: TextStyle(
                      color: context.col.textMuted,
                      fontSize: 13,
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              args.selectedPackageName!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.col.textPrimary,
                              ),
                            ),
                            if (args.selectedPackageDesc != null &&
                                args.selectedPackageDesc!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                args.selectedPackageDesc!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.col.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${_fmt(args.pricePerPerson ?? 0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            '/ person',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.col.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          // ── Add-ons ──────────────────────────────────────────────────
          if (args.selectedAddons.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionHeader(
              icon: Iconsax.bag_2,
              title: 'Gear & Add-ons',
              color: const Color(0xFF9C27B0),
              trailing: '+₹${_fmt(args.addonSubtotal)}',
            ),
            const SizedBox(height: 8),
            _SectionCard(
              child: Column(
                children: args.selectedAddons.asMap().entries.map((e) {
                  final i = e.key;
                  final a = e.value;
                  final name = a['name'] as String? ?? '';
                  final emoji = a['emoji'] as String? ?? '🎒';
                  final price =
                      double.tryParse('${a['pricePerUnit']}') ?? 0;
                  final unit = a['unit'] as String? ?? 'per person';
                  final qty = a['qty'] as int? ?? 1;
                  final isLast = i == args.selectedAddons.length - 1;
                  return Container(
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : Border(
                              bottom: BorderSide(
                                  color: context.col.border)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Text(emoji,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.col.textPrimary,
                                ),
                              ),
                              Text(
                                '₹${_fmt(price)} / $unit',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.col.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9C27B0)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '× $qty',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF9C27B0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${_fmt(price * qty)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Bill breakdown ───────────────────────────────────────────
          _SectionHeader(
            icon: Iconsax.document_text,
            title: 'Bill Breakdown',
            color: AppColors.accent,
          ),
          const SizedBox(height: 8),
          _SectionCard(
            child: Column(
              children: [
                if (args.pricePerPerson != null && args.pricePerPerson! > 0)
                  _BillRow(
                    label:
                        '${args.selectedPackageName ?? 'Base price'} × ${args.personCount}',
                    amount:
                        (args.pricePerPerson ?? 0) * args.personCount,
                  ),
                if (args.selectedAddons.isNotEmpty)
                  _BillRow(
                    label:
                        'Add-ons (${args.selectedAddons.fold(0, (s, a) => s + (a['qty'] as int? ?? 1))} items)',
                    amount: args.addonSubtotal,
                  ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Grand Total',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      '₹${_fmt(args.grandTotal)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Operator ─────────────────────────────────────────────────
          if (args.operatorName.isNotEmpty) ...[
            _SectionHeader(
              icon: Iconsax.profile_2user,
              title: 'Operator',
              color: AppColors.info,
            ),
            const SizedBox(height: 8),
            _SectionCard(
              child: Column(
                children: [
                  _InfoRow(
                    icon: Iconsax.user,
                    label: 'Name',
                    value: args.operatorName,
                  ),
                  if (args.operatorPhone.isNotEmpty)
                    _InfoRow(
                      icon: Iconsax.call,
                      label: 'Phone',
                      value: args.operatorPhone,
                    ),
                  if (args.operatorEmail.isNotEmpty)
                    _InfoRow(
                      icon: Iconsax.sms,
                      label: 'Email',
                      value: args.operatorEmail,
                      isLast: true,
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // ── Your Contact Details ─────────────────────────────────────
          _SectionHeader(
            icon: Iconsax.call,
            title: 'Your Contact Details',
            color: const Color(0xFF22C55E),
          ),
          const SizedBox(height: 8),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Primary phone
                TextField(
                  controller: _primaryPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 15,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Primary Phone Number *',
                    hintText: 'e.g. +91 98765 43210',
                    prefixIcon: const Icon(Iconsax.call, size: 18),
                    counterText: '',
                    errorText: _triedSubmit && _primaryPhoneCtrl.text.trim().isEmpty
                        ? 'Primary phone number is required'
                        : _triedSubmit &&
                                !_isValidPhone(_primaryPhoneCtrl.text.trim())
                            ? 'Enter a valid phone number'
                            : null,
                    filled: true,
                    fillColor: context.col.bg,
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
                      borderSide: const BorderSide(
                          color: Color(0xFF22C55E), width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.error),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Secondary phone
                TextField(
                  controller: _secondaryPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 15,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Secondary Phone Number (optional)',
                    hintText: 'Alternate contact number',
                    prefixIcon: const Icon(Iconsax.call_calling, size: 18),
                    counterText: '',
                    errorText: _secondaryPhoneCtrl.text.trim().isNotEmpty &&
                            !_isValidPhone(_secondaryPhoneCtrl.text.trim())
                        ? 'Enter a valid phone number'
                        : null,
                    filled: true,
                    fillColor: context.col.bg,
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
                      borderSide: const BorderSide(
                          color: Color(0xFF22C55E), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The operator will use these numbers to confirm your booking.',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.col.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Note ─────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.info.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Iconsax.info_circle, size: 16, color: AppColors.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is a booking enquiry summary. Tap WhatsApp or Call to confirm directly with the operator.',
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

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Shows a prominent overlay toast pinned to the top of the screen.
  void _showTopToast(BuildContext context, String message,
      {bool isError = true}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopToast(
        message: message,
        isError: isError,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  bool _isValidPhone(String phone) {
    // Accepts optional + prefix, then 7-15 digits (spaces/dashes ignored)
    final digits = phone.replaceAll(RegExp(r'[\s\-()]'), '');
    return RegExp(r'^\+?[0-9]{7,15}$').hasMatch(digits);
  }

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      if (i > 0 && pos % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  /// Primary CTA: saves booking to Firestore, shows success sheet.
  Future<void> _confirmBooking(
    BuildContext context, {
    String? userId,
    String? userName,
    String? userEmail,
  }) async {
    final args = widget.args;
    setState(() => _submitting = true);
    try {
      await ref.read(bookingServiceProvider).createBooking({
        'userId': userId ?? '',
        'userName': userName ?? '',
        'userEmail': userEmail ?? '',
        'ventureId': args.ventureId,
        'ventureTitle': args.ventureTitle,
        'heroImage': args.heroImage,
        'category': args.category,
        'location': args.location,
        'operatorName': args.operatorName,
        'operatorPhone': args.operatorPhone,
        'operatorWhatsapp': args.operatorWhatsapp,
        'operatorEmail': args.operatorEmail,
        if (args.selectedPackageName != null)
          'selectedPackageName': args.selectedPackageName,
        if (args.selectedPackageDesc != null)
          'selectedPackageDesc': args.selectedPackageDesc,
        if (args.pricePerPerson != null) 'pricePerPerson': args.pricePerPerson,
        'personCount': args.personCount,
        'selectedAddons': args.selectedAddons,
        'addonSubtotal': args.addonSubtotal,
        'grandTotal': args.grandTotal,
        'contactPrimaryPhone': _primaryPhoneCtrl.text.trim(),
        if (_secondaryPhoneCtrl.text.trim().isNotEmpty)
          'contactSecondaryPhone': _secondaryPhoneCtrl.text.trim(),
        'status': 'pending',
      });
      if (!context.mounted) return;
      HapticFeedback.lightImpact();
      if (!context.mounted) return;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        backgroundColor: Colors.transparent,
        builder: (_) => _BookingSuccessSheet(
          args: args,
          onWhatsApp: () => _launchWhatsapp(
            args.operatorWhatsapp.isNotEmpty
                ? args.operatorWhatsapp
                : args.operatorPhone,
            args,
            userName,
            primaryPhone: _primaryPhoneCtrl.text.trim(),
            secondaryPhone: _secondaryPhoneCtrl.text.trim(),
          ),
          // context.go replaces the full stack — removes the booking-review
          // route (with its unserializable BookingReviewArgs extra) cleanly.
          onViewBookings: () => context.go(AppRoutes.myBookings),
        ),
      );
      // Auto-navigate after the sheet closes (user dismissed without tapping)
      if (context.mounted) context.go(AppRoutes.myBookings);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit booking: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Secondary: launch WhatsApp with pre-filled booking details.
  Future<void> _launchWhatsapp(
    String phone,
    BookingReviewArgs a,
    String? userName, {
    String primaryPhone = '',
    String secondaryPhone = '',
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final packageLine = a.selectedPackageName != null
        ? 'Package: ${a.selectedPackageName} (₹${_fmt(a.pricePerPerson ?? 0)}/person)'
        : '';
    final addonLine = a.selectedAddons.isNotEmpty
        ? 'Add-ons: ${a.selectedAddons.map((x) => '${x['name']} ×${x['qty']}').join(', ')}'
        : '';
    final msg = [
      'Hi! I would like to book *${a.ventureTitle}*',
      if (userName != null && userName.isNotEmpty) 'Name: $userName',
      if (primaryPhone.isNotEmpty) 'My contact: $primaryPhone',
      if (secondaryPhone.isNotEmpty) 'Alt contact: $secondaryPhone',
      'Guests: ${a.personCount} person${a.personCount > 1 ? 's' : ''}',
      if (packageLine.isNotEmpty) packageLine,
      if (addonLine.isNotEmpty) addonLine,
      'Total: ₹${_fmt(a.grandTotal)}',
    ].join('\n');
    final uri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

}

// ─────────────────────────────────────────────────────────────────────────────
// Booking Success Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _BookingSuccessSheet extends StatefulWidget {
  final BookingReviewArgs args;
  final VoidCallback onWhatsApp;
  final VoidCallback onViewBookings;

  const _BookingSuccessSheet({
    required this.args,
    required this.onWhatsApp,
    required this.onViewBookings,
  });

  @override
  State<_BookingSuccessSheet> createState() => _BookingSuccessSheetState();
}

class _BookingSuccessSheetState extends State<_BookingSuccessSheet> {
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown > 0) {
        _tick();
      } else {
        widget.onViewBookings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.col.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Success icon
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF22C55E),
              size: 44,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Booking Request Sent!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'The operator will contact you within 1 hour\nto confirm your booking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: context.col.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Booking summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.col.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.col.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.args.ventureTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  icon: Icons.people_outline_rounded,
                  label: '${widget.args.personCount} guest${widget.args.personCount > 1 ? 's' : ''}',
                ),
                if (widget.args.selectedPackageName != null)
                  _SummaryRow(
                    icon: Icons.inventory_2_outlined,
                    label: widget.args.selectedPackageName!,
                  ),
                _SummaryRow(
                  icon: Icons.currency_rupee_rounded,
                  label: '₹${_fmtAmount(widget.args.grandTotal)} total',
                  bold: true,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Track bookings CTA
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onViewBookings,
              icon: const Icon(Iconsax.activity, size: 18),
              label: Text(
                _countdown > 0
                    ? 'Track My Bookings ($_countdown)'
                    : 'Track My Bookings',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // WhatsApp secondary
          if (widget.args.operatorWhatsapp.isNotEmpty ||
              widget.args.operatorPhone.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onWhatsApp,
                icon: const Icon(Iconsax.message, size: 16,
                    color: Color(0xFF25D366)),
                label: const Text(
                  'Also message on WhatsApp',
                  style: TextStyle(
                    color: Color(0xFF25D366),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                      color: Color(0xFF25D366), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmtAmount(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      if (i > 0 && pos % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool bold;
  final Color? color;
  const _SummaryRow(
      {required this.icon,
      required this.label,
      this.bold = false,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? context.col.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? context.col.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final String? trailing;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.col.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          Text(
            trailing!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.col.border),
      ),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: context.col.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 15, color: context.col.textMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.col.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.col.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final double amount;
  const _BillRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: context.col.textSecondary,
              ),
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.col.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}



Widget _imgBox(Color color) => Container(
      width: 72,
      height: 72,
      color: color.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Icon(Icons.landscape_rounded, color: color, size: 28),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Top Toast Overlay
// ─────────────────────────────────────────────────────────────────────────────

class _TopToast extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _TopToast({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    // Auto-dismiss after 3 s
    Future.delayed(const Duration(seconds: 3), _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E);
    final icon = widget.isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
