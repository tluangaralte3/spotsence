// lib/screens/ventures/venture_public_detail_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/tour_venture_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tour_venture_models.dart';

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

class _VentureDetailBody extends StatelessWidget {
  final Map<String, dynamic> data;
  const _VentureDetailBody({required this.data});

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
      bottomNavigationBar: price > 0
          ? SafeArea(
              child: Container(
                height: 80,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                decoration: BoxDecoration(
                  color: context.col.surface,
                  border: Border(top: BorderSide(color: context.col.border)),
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Starting from',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.col.textMuted,
                          ),
                        ),
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ person',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.col.textMuted,
                      ),
                    ),
                    const Spacer(),
                    // ElevatedButton(
                    //   onPressed: () => _contact(opPhone, opWhatsapp),
                    //   style: ElevatedButton.styleFrom(
                    //     backgroundColor: AppColors.primary,
                    //     foregroundColor: Colors.black,
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 24,
                    //       vertical: 12,
                    //     ),
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(12),
                    //     ),
                    //   ),
                    //   child: const Text(
                    //     'Book Now',
                    //     style: TextStyle(fontWeight: FontWeight.w800),
                    //   ),
                    // ),
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

                    // Pricing tiers
                    if (pricingTiers.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _sectionHeader('Pricing', context),
                      const SizedBox(height: 10),
                      ...pricingTiers.map((t) {
                        if (t is! Map) return const SizedBox.shrink();
                        final tierName = t['name'] as String? ?? 'Standard';
                        final tierPrice = double.tryParse('${t['price']}') ?? 0;
                        final tierDesc = t['description'] as String? ?? '';
                        final isPopular = t['isPopular'] == true;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isPopular
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : context.col.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isPopular
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : context.col.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          tierName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: context.col.textPrimary,
                                          ),
                                        ),
                                        if (isPopular) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              'Popular',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black,
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
                                          color: context.col.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                '₹${tierPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
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
                      _sectionHeader('Gear & Add-ons', context),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: addons.map((a) {
                          if (a is! Map) return const SizedBox.shrink();
                          final emoji = a['emoji'] as String? ?? '🎒';
                          final name = a['name'] as String? ?? '';
                          final addonPrice =
                              double.tryParse('${a['price']}') ?? 0;
                          return Container(
                            width: (MediaQuery.of(context).size.width - 60) / 2,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.col.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.col.border),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
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
                                          color: context.col.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (addonPrice > 0)
                                        Text(
                                          '₹${addonPrice.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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

  void _contact(String phone, String whatsapp) {
    if (whatsapp.isNotEmpty) {
      _launch('https://wa.me/${whatsapp.replaceAll(RegExp(r'\D'), '')}');
    } else if (phone.isNotEmpty) {
      _launch('tel:$phone');
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
