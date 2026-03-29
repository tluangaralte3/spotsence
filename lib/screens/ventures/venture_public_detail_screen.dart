// lib/screens/ventures/venture_public_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/tour_venture_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tour_venture_models.dart';
import 'booking_review_screen.dart';

class VenturePublicDetailScreen extends ConsumerWidget {
  final String ventureId;
  const VenturePublicDetailScreen({super.key, required this.ventureId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      ventureByIdProvider(ventureId).select((value) => value),
    );

    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Could not load venture: $e')),
      ),
      data: (data) {
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Not found')),
            body: const Center(child: Text('This venture no longer exists.')),
          );
        }
        return _VentureDetailBody(data: data);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _VentureDetailBody extends StatefulWidget {
  final Map<String, dynamic> data;
  const _VentureDetailBody({required this.data});

  @override
  State<_VentureDetailBody> createState() => _VentureDetailBodyState();
}

class _VentureDetailBodyState extends State<_VentureDetailBody> {
  // Map of add-on index → quantity (absent = not added)
  final Map<int, int> _selectedAddons = {};

  // Index of the selected pricing tier (null = none selected)
  int? _selectedTierIndex;

  // Number of people booking
  int _personCount = 1;

  Map<String, dynamic> get data => widget.data;

  String _str(String key, [String fallback = '']) {
    final v = data[key];
    if (v is String) return v;
    return fallback;
  }

  List<String> _strList(String key) {
    final v = data[key];
    if (v is List) {
      return v.whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    }
    if (v is String) {
      return v.split('\n').where((s) => s.trim().isNotEmpty).toList();
    }
    return [];
  }

  int _int(String key, [int fallback = 0]) {
    final v = data[key];
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  double _dbl(String key, [double fallback = 0.0]) {
    final v = data[key];
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }

  List<dynamic> _list(String key) {
    final v = data[key];
    return v is List ? v : [];
  }

  double _addonTotal(List<dynamic> addons) {
    double total = 0;
    for (final entry in _selectedAddons.entries) {
      final i = entry.key;
      final qty = entry.value;
      if (i < addons.length && addons[i] is Map) {
        total += (double.tryParse('${addons[i]['pricePerUnit']}') ?? 0) * qty;
      }
    }
    return total;
  }

  /// Price per person (tier or base) + add-ons, then multiplied by person count.
  double _totalBill(
      List<dynamic> tiers, double basePrice, List<dynamic> addons) {
    final perPerson =
        (_selectedTierIndex != null ? _tierPrice(tiers) : basePrice) +
            _addonTotal(addons);
    return perPerson * _personCount;
  }

  /// Price from the selected pricing tier, or 0 if none selected.
  double _tierPrice(List<dynamic> tiers) {
    if (_selectedTierIndex == null) return 0;
    final idx = _selectedTierIndex!;
    if (idx >= tiers.length || tiers[idx] is! Map) return 0;
    return double.tryParse('${tiers[idx]['pricePerPerson']}') ?? 0;
  }

  /// Label shown in the booking bar.
  String _bookingLabel(List<dynamic> tiers, double basePrice) {
    final peopleStr =
        '$_personCount person${_personCount > 1 ? 's' : ''}';
    if (_selectedTierIndex != null) {
      final t = tiers[_selectedTierIndex!];
      final name = (t is Map ? t['name'] as String? : null) ?? 'Package';
      final parts = <String>[
        name,
        if (_selectedAddons.isNotEmpty)
          '+ ${_selectedAddons.values.fold(0, (a, b) => a + b)} item${_selectedAddons.values.fold(0, (a, b) => a + b) > 1 ? 's' : ''}',
        '· $peopleStr',
      ];
      return parts.join(' ');
    }
    if (_selectedAddons.isNotEmpty) {
      final totalItems = _selectedAddons.values.fold(0, (a, b) => a + b);
      return '$totalItems add-on item${totalItems > 1 ? 's' : ''} · $peopleStr';
    }
    return 'Starting from · $peopleStr';
  }

  @override
  Widget build(BuildContext context) {
    // ── Extract data ────────────────────────────────────────────────────────
    final title = _str('title', 'Untitled');
    final tagline = _str('tagline');
    final description = _str('description');
    final location = _str('location');
    final district = _str('district');
    final category = _str('category');
    final difficulty = _str('difficulty');
    final durationDays = _int('durationDays', 1);
    final durationNights = _int('durationNights');
    final maxGroup = _int('maxGroupSize');
    final price = _dbl('startingPrice');
    final highlights = _strList('highlights');
    final expect = _strList('whatToExpect');
    final bring = _strList('whatToBring');
    final safety = _str('safetyNotes');
    final cancellation = _str('cancellationPolicy');
    final opName = _str('operatorName');
    final opPhone = _str('operatorPhone');
    final opEmail = _str('operatorEmail');
    final opWhatsapp = _str('operatorWhatsapp');
    final opVerified = data['operatorVerified'] == true;
    final meetingPoint = _str('meetingPoint');
    final seasons = _list('seasons');
    final pricingTiers = _list('pricingTiers');
    final addons = _list('addons');
    final scheduleSlots = _list('scheduleSlots');
    final challenges = _list('challenges');
    final medals = _list('medals');

    final images = _list('images').whereType<String>().toList();
    final imageUrl = _str('imageUrl');
    final allImages = [
      ...images,
      if (imageUrl.isNotEmpty && !images.contains(imageUrl)) imageUrl,
    ];

    final cat = PackageCategory.fromString(category);

    final locationFull = [
      location,
      district,
    ].where((s) => s.isNotEmpty).join(', ');

    Color diffColor() {
      switch (difficulty.toLowerCase()) {
        case 'easy':
          return const Color(0xFF22C55E);
        case 'hard':
        case 'extreme':
          return const Color(0xFFEF4444);
        default:
          return const Color(0xFFF59E0B);
      }
    }

    Color medalColor(String tier) {
      switch (tier.toLowerCase()) {
        case 'gold':
          return const Color(0xFFD97706);
        case 'silver':
          return const Color(0xFF94A3B8);
        case 'platinum':
          return const Color(0xFF7C3AED);
        default:
          return const Color(0xFF92400E);
      }
    }

    // ── Build ───────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        elevation: 0,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.col.textPrimary,
          ),
        ),
      ),

      // ── Booking bar ───────────────────────────────────────────────────────
      bottomNavigationBar: (price > 0 || _selectedTierIndex != null)
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                decoration: BoxDecoration(
                  color: context.col.surface,
                  border: Border(top: BorderSide(color: context.col.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bookingLabel(pricingTiers, price),
                            style: TextStyle(
                              fontSize: 11,
                              color: context.col.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${_totalBill(pricingTiers, price, addons).toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  'total',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.col.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_personCount > 1)
                            Text(
                              '₹${((_selectedTierIndex != null ? _tierPrice(pricingTiers) : price) + _addonTotal(addons)).toStringAsFixed(0)} × $_personCount people',
                              style: TextStyle(
                                fontSize: 10,
                                color: context.col.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        final ventureId = _str('id');
                        // Build add-ons list from selected map
                        final addonsList = _selectedAddons.entries
                            .where((e) =>
                                e.key < addons.length &&
                                addons[e.key] is Map)
                            .map((e) {
                              final a = addons[e.key] as Map;
                              return <String, dynamic>{
                                'name': a['name'] ?? '',
                                'emoji': a['emoji'] ?? '🎒',
                                'pricePerUnit': double.tryParse(
                                        '${a['pricePerUnit']}') ??
                                    0.0,
                                'unit': a['unit'] ?? 'per person',
                                'qty': e.value,
                              };
                            })
                            .toList();

                        final selectedTier = _selectedTierIndex != null &&
                                _selectedTierIndex! < pricingTiers.length
                            ? pricingTiers[_selectedTierIndex!] as Map?
                            : null;

                        final args = BookingReviewArgs(
                          ventureId: ventureId,
                          ventureTitle: title,
                          heroImage:
                              allImages.isNotEmpty ? allImages.first : '',
                          category: category,
                          location: locationFull,
                          operatorName: opName,
                          operatorPhone: opPhone,
                          operatorWhatsapp: opWhatsapp,
                          operatorEmail: opEmail,
                          selectedPackageName:
                              selectedTier?['name'] as String?,
                          selectedPackageDesc:
                              selectedTier?['description'] as String?,
                          pricePerPerson: _selectedTierIndex != null
                              ? _tierPrice(pricingTiers)
                              : price,
                          personCount: _personCount,
                          selectedAddons: addonsList,
                        );
                        context.push(
                          AppRoutes.bookingReviewPath(ventureId),
                          extra: args,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,

      // ── Scrollable body ───────────────────────────────────────────────────
      body: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero image
              if (allImages.isNotEmpty)
                SizedBox(
                  height: 240,
                  child: PageView.builder(
                    key: ValueKey(allImages.length),
                    itemCount: allImages.length,
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: allImages[i],
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          _imgPlaceholder(cat.emoji),
                    ),
                  ),
                )
              else
                _imgPlaceholder(cat.emoji),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + tagline
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: context.col.textPrimary,
                      ),
                    ),
                    if (tagline.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        tagline,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.col.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Info chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (cat.label.isNotEmpty)
                          _chip(cat.emoji, cat.label, AppColors.primary),
                        if (difficulty.isNotEmpty)
                          _chip('🎯', difficulty, diffColor()),
                        _chip(
                          '📅',
                          durationNights > 0
                              ? '${durationDays}D/${durationNights}N'
                              : '$durationDays Day${durationDays != 1 ? 's' : ''}',
                          const Color(0xFF6366F1),
                        ),
                        if (maxGroup > 0)
                          _chip('👥', 'Max $maxGroup', const Color(0xFF0EA5E9)),
                        if (seasons.isNotEmpty)
                          _chip(
                            '🌤',
                            seasons.join(', '),
                            const Color(0xFFF59E0B),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Location rows
                    if (locationFull.isNotEmpty)
                      _iconRow(
                        Icons.location_on_rounded,
                        locationFull,
                        const Color(0xFFEF4444),
                        context,
                      ),
                    if (meetingPoint.isNotEmpty)
                      _iconRow(
                        Icons.flag_rounded,
                        'Meeting point: $meetingPoint',
                        AppColors.primary,
                        context,
                      ),

                    // Description
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionHeader('About', context),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.col.textSecondary,
                          height: 1.6,
                        ),
                      ),
                    ],

                    // Highlights
                    if (highlights.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionHeader('Highlights', context),
                      const SizedBox(height: 8),
                      ...highlights.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✨ '),
                              Expanded(
                                child: Text(
                                  line.trim(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.col.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // ── Number of people stepper ─────────────────────────
                    const SizedBox(height: 20),
                    _sectionHeader('Number of People', context),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: context.col.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.col.border),
                      ),
                      child: Row(
                        children: [
                          // Decrement
                          Material(
                            color: _personCount > 1
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : context.col.border.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: _personCount > 1
                                  ? () =>
                                      setState(() => _personCount--)
                                  : null,
                              child: Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.remove_rounded,
                                  size: 18,
                                  color: _personCount > 1
                                      ? AppColors.primary
                                      : context.col.textMuted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '$_personCount',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: context.col.textPrimary,
                                  ),
                                ),
                                Text(
                                  _personCount == 1 ? 'person' : 'people',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.col.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Increment
                          Material(
                            color: (maxGroup == 0 || _personCount < maxGroup)
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : context.col.border.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap:
                                  (maxGroup == 0 || _personCount < maxGroup)
                                      ? () =>
                                          setState(() => _personCount++)
                                      : null,
                              child: Container(
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color:
                                      (maxGroup == 0 ||
                                              _personCount < maxGroup)
                                          ? AppColors.primary
                                          : context.col.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (maxGroup > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Max group size: $maxGroup',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.col.textMuted,
                          ),
                        ),
                      ),

                    // Pricing tiers
                    if (pricingTiers.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _sectionHeader('Pricing Packages', context),
                          ),
                          if (_selectedTierIndex != null)
                            Text(
                              '₹${_tierPrice(pricingTiers).toStringAsFixed(0)} / person',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap a package to select it',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.col.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...pricingTiers.asMap().entries.map((entry) {
                        final tierIdx = entry.key;
                        final t = entry.value;
                        if (t is! Map) return const SizedBox.shrink();
                        final tierName = t['name'] as String? ?? 'Standard';
                        final tierPrice =
                            double.tryParse('${t['pricePerPerson']}') ?? 0;
                        final tierDesc = t['description'] as String? ?? '';
                        final isPopular = t['isPopular'] == true;
                        final isAvailable = t['isAvailable'] != false;
                        final minPersons = t['minPersons'];
                        final maxPersons = t['maxPersons'];
                        final includes = (t['includes'] is List)
                            ? (t['includes'] as List)
                                  .whereType<String>()
                                  .toList()
                            : <String>[];
                        final excludes = (t['excludes'] is List)
                            ? (t['excludes'] as List)
                                  .whereType<String>()
                                  .toList()
                            : <String>[];

                        final isSelected = _selectedTierIndex == tierIdx;

                        return Opacity(
                          opacity: isAvailable ? 1.0 : 0.5,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: isAvailable
                                  ? () => setState(() {
                                        _selectedTierIndex =
                                            isSelected ? null : tierIdx;
                                      })
                                  : null,
                              child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.10)
                                    : isPopular
                                        ? AppColors.primary
                                              .withValues(alpha: 0.06)
                                        : context.col.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : isPopular
                                          ? AppColors.primary
                                                .withValues(alpha: 0.5)
                                          : context.col.border,
                                  width:
                                      isSelected ? 2 : (isPopular ? 1.5 : 1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Top row: name + price ──────────────
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      14, 14, 14, 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  AnimatedContainer(
                                                    duration: const Duration(milliseconds: 200),
                                                    width: 22,
                                                    height: 22,
                                                    margin: const EdgeInsets.only(right: 8),
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isSelected
                                                          ? AppColors.primary
                                                          : Colors.transparent,
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? AppColors.primary
                                                            : context.col.border,
                                                        width: isSelected ? 0 : 1.5,
                                                      ),
                                                    ),
                                                    child: isSelected
                                                        ? const Center(
                                                            child: Icon(
                                                              Icons.check,
                                                              size: 13,
                                                              color: Colors.black,
                                                            ),
                                                          )
                                                        : null,
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      tierName,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 15,
                                                        color: isSelected
                                                            ? AppColors.primary
                                                            : context.col
                                                                  .textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isPopular) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: const Text(
                                                        '\u2b50 Popular',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                  if (!isAvailable) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            context.col.border,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Text(
                                                        'Unavailable',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: context
                                                              .col.textMuted,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (tierDesc.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  tierDesc,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: context
                                                        .col.textSecondary,
                                                  ),
                                                ),
                                              ],
                                              if (minPersons != null ||
                                                  maxPersons != null) ...[
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.people_alt_outlined,
                                                      size: 13,
                                                      color:
                                                          context.col.textMuted,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${minPersons ?? 1}\u2013${maxPersons ?? '\u221e'} persons',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: context
                                                            .col.textMuted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '\u20b9${tierPrice.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 22,
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

                                  // ── Includes ───────────────────────────
                                  if (includes.isNotEmpty) ...[
                                    Divider(
                                        height: 1,
                                        color: context.col.border),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 10, 14, 10),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '\u2705  Included',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: context.col.textMuted,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: includes
                                                .map(
                                                  (inc) => Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 9,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFF22C55E,
                                                      ).withValues(alpha: 0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFF22C55E,
                                                        ).withValues(
                                                            alpha: 0.35),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      inc,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Color(0xFF16A34A),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // ── Excludes ───────────────────────────
                                  if (excludes.isNotEmpty) ...[
                                    Divider(
                                        height: 1,
                                        color: context.col.border),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 10, 14, 14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '\u274c  Not included',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: context.col.textMuted,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: excludes
                                                .map(
                                                  (exc) => Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 9,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFEF4444,
                                                      ).withValues(alpha: 0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFFEF4444,
                                                        ).withValues(
                                                            alpha: 0.3),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      exc,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Color(0xFFDC2626),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else
                                    const SizedBox(height: 14),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                  }),
                ],

                // Schedule slots
                    if (scheduleSlots.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionHeader('Available Dates', context),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: scheduleSlots.map((s) {
                          if (s is! Map) return const SizedBox.shrink();
                          final date = s['date'] as String? ?? '';
                          final slots = s['availableSlots'];
                          final label = slots != null
                              ? '$date ($slots slots)'
                              : date;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: context.col.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.col.border),
                            ),
                            child: Text(
                              '📅 $label',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.col.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Add-ons
                    if (addons.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _sectionHeader('Gear & Add-ons', context),
                          ),
                          if (_selectedAddons.isNotEmpty)
                            Text(
                              '+₹${_addonTotal(addons).toStringAsFixed(0)}  (${_selectedAddons.values.fold(0, (a, b) => a + b)} items)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to add to your booking',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.col.textMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(addons.length, (i) {
                          final a = addons[i];
                          if (a is! Map) return const SizedBox.shrink();
                          final emoji = a['emoji'] as String? ?? '🎒';
                          final name = a['name'] as String? ?? '';
                          final addonPrice =
                              double.tryParse('${a['pricePerUnit']}') ?? 0;
                          final unit = a['unit'] as String? ?? 'per person';
                          final addonDesc = a['description'] as String? ?? '';
                          final qty = _selectedAddons[i] ?? 0;
                          final selected = qty > 0;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: (MediaQuery.of(context).size.width - 60) / 2,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : context.col.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : context.col.border,
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Name row ────────────────────────────
                                Row(
                                  children: [
                                    Text(emoji,
                                        style:
                                            const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: selected
                                                  ? AppColors.primary
                                                  : context.col.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (addonPrice > 0)
                                            Text(
                                              '+₹${addonPrice.toStringAsFixed(0)} / $unit',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          if (addonDesc.isNotEmpty)
                                            Text(
                                              addonDesc,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color:
                                                    context.col.textMuted,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // ── Quantity stepper ─────────────────────
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (selected && addonPrice > 0)
                                      Text(
                                        '₹${(addonPrice * qty).toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // − button
                                        GestureDetector(
                                          onTap: selected
                                              ? () => setState(() {
                                                    if (qty <= 1) {
                                                      _selectedAddons.remove(i);
                                                    } else {
                                                      _selectedAddons[i] = qty - 1;
                                                    }
                                                  })
                                              : null,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 150),
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? AppColors.primary
                                                      .withValues(alpha: 0.15)
                                                  : context.col.border
                                                      .withValues(alpha: 0.4),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.remove_rounded,
                                              size: 14,
                                              color: selected
                                                  ? AppColors.primary
                                                  : context.col.textMuted,
                                            ),
                                          ),
                                        ),
                                        // Qty
                                        SizedBox(
                                          width: 30,
                                          child: Text(
                                            '$qty',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: selected
                                                  ? AppColors.primary
                                                  : context.col.textMuted,
                                            ),
                                          ),
                                        ),
                                        // + button
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            _selectedAddons[i] = qty + 1;
                                          }),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.add_rounded,
                                              size: 14,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                    }),
                  ),
                ],

                // Challenges
                    if (challenges.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionHeader('🏆 Challenges', context),
                      const SizedBox(height: 10),
                      ...challenges.map((c) {
                        if (c is! Map) return const SizedBox.shrink();
                        final name = c['name'] as String? ?? '';
                        final desc = c['description'] as String? ?? '';
                        final pts = c['points'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.col.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.col.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: context.col.textPrimary,
                                      ),
                                    ),
                                    if (desc.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.col.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (pts != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '+$pts pts',
                                    style: const TextStyle(
                                      color: Color(0xFFF59E0B),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],

                    // Medals
                    if (medals.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionHeader('🥇 Medals', context),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: medals.map((m) {
                          if (m is! Map) return const SizedBox.shrink();
                          final name = m['name'] as String? ?? '';
                          final tier = m['tier'] as String? ?? 'bronze';
                          final color = medalColor(tier);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: color.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              '🏅 $name',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Preparation & Policies
                    if (expect.isNotEmpty ||
                        bring.isNotEmpty ||
                        safety.isNotEmpty ||
                        cancellation.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionHeader('Preparation & Policies', context),
                      const SizedBox(height: 10),
                      if (expect.isNotEmpty)
                        _noteCard('👁 What to Expect', expect, context),
                      if (bring.isNotEmpty)
                        _noteCard('🎒 What to Bring', bring, context),
                      if (safety.isNotEmpty)
                        _noteCard('🛡 Safety Notes', [safety], context),
                      if (cancellation.isNotEmpty)
                        _noteCard('📋 Cancellation Policy', [
                          cancellation,
                        ], context),
                    ],

                    // Operator
                    if (opName.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionHeader('Operator', context),
                      const SizedBox(height: 10),
                      Container(
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
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Text(
                                    opName.characters.first.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            opName,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: context.col.textPrimary,
                                            ),
                                          ),
                                          if (opVerified) ...[
                                            const SizedBox(width: 6),
                                            const Icon(
                                              Icons.verified_rounded,
                                              size: 16,
                                              color: Color(0xFF3B82F6),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (locationFull.isNotEmpty)
                                        Text(
                                          locationFull,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.col.textSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                if (opPhone.isNotEmpty)
                                  _contactBtn(
                                    Icons.call_rounded,
                                    'Call',
                                    const Color(0xFF22C55E),
                                    () => _launch('tel:$opPhone'),
                                    context,
                                  ),
                                if (opWhatsapp.isNotEmpty)
                                  _contactBtn(
                                    Icons.chat_rounded,
                                    'WhatsApp',
                                    const Color(0xFF25D366),
                                    () => _launch(
                                      'https://wa.me/${opWhatsapp.replaceAll(RegExp(r'\D'), '')}',
                                    ),
                                    context,
                                  ),
                                if (opEmail.isNotEmpty)
                                  _contactBtn(
                                    Icons.email_rounded,
                                    'Email',
                                    const Color(0xFF6366F1),
                                    () => _launch('mailto:$opEmail'),
                                    context,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _imgPlaceholder(String emoji) => Container(
    height: 240,
    color: AppColors.primary.withValues(alpha: 0.1),
    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 64))),
  );

  Widget _chip(String icon, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$icon $label',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Widget _iconRow(
    IconData icon,
    String text,
    Color color,
    BuildContext context,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: context.col.textSecondary),
          ),
        ),
      ],
    ),
  );

  Widget _sectionHeader(String title, BuildContext context) => Text(
    title,
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: context.col.textPrimary,
    ),
  );

  Widget _noteCard(String title, List<String> lines, BuildContext context) =>
      Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.col.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.col.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.col.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${l.trim()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.col.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _contactBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
