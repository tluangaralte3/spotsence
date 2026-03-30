import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/listing_models.dart';
import '../../services/listings_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider — fetches the detail JSON from /api/listings/:type/:id
// ─────────────────────────────────────────────────────────────────────────────

final _detailProvider =
    FutureProvider.family<Map<String, dynamic>, ({String type, String id})>(
      (ref, args) => ref
          .watch(listingsServiceProvider)
          .getListingDetail(args.type, args.id)
          .then((r) => r.when(ok: (d) => d, err: (e) => throw Exception(e))),
    );

// ─────────────────────────────────────────────────────────────────────────────
// ListingDetailScreen
// ─────────────────────────────────────────────────────────────────────────────

class ListingDetailScreen extends ConsumerWidget {
  final String type;
  final String id;

  const ListingDetailScreen({super.key, required this.type, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_detailProvider((type: type, id: id)));

    return async.when(
      loading: () => const _LoadingScaffold(),
      error: (e, _) => _ErrorScaffold(error: e.toString()),
      data: (json) => _buildDetail(context, json),
    );
  }

  Widget _buildDetail(BuildContext context, Map<String, dynamic> json) {
    switch (type) {
      case 'restaurants':
        return _RestaurantDetail(restaurant: RestaurantModel.fromJson(json));
      case 'hotels':
        return _HotelDetail(hotel: HotelModel.fromJson(json));
      case 'cafes':
        return _CafeDetail(cafe: CafeModel.fromJson(json));
      case 'homestays':
        return _HomestayDetail(homestay: HomestayModel.fromJson(json));
      case 'adventure-spots':
        return _AdventureDetail(adventure: AdventureSpotModel.fromJson(json));
      case 'shopping-areas':
        return _ShoppingDetail(area: ShoppingAreaModel.fromJson(json));
      case 'events':
        return _EventDetail(event: EventModel.fromJson(json));
      default:
        return _GenericDetail(json: json, type: type);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared detail scaffold helpers
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.col.bg,
    appBar: AppBar(backgroundColor: context.col.bg),
    body: const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
  );
}

class _ErrorScaffold extends StatelessWidget {
  final String error;
  const _ErrorScaffold({required this.error});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.col.bg,
    appBar: AppBar(backgroundColor: context.col.bg),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(color: context.col.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

/// Full-screen image gallery with sliver header.
class _DetailScaffold extends StatelessWidget {
  final List<String> images;
  final String title;
  final double rating;
  final String location;
  final String description;
  final List<Widget> badges;
  final List<Widget> infoRows;
  final List<Widget> chips;
  final Widget? actions;

  const _DetailScaffold({
    required this.images,
    required this.title,
    required this.rating,
    required this.location,
    required this.description,
    this.badges = const [],
    this.infoRows = const [],
    this.chips = const [],
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final heroUrl = images.isNotEmpty ? images.first : '';

    return Scaffold(
      backgroundColor: context.col.bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero image + back button ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: context.col.bg,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.col.surface.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: context.col.textPrimary,
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: heroUrl.isEmpty
                  ? Container(color: context.col.surfaceElevated)
                  : CachedNetworkImage(
                      imageUrl: heroUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          Container(color: context.col.surfaceElevated),
                      errorWidget: (_, _, _) =>
                          Container(color: context.col.surfaceElevated),
                    ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + rating row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: context.col.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _RatingPill(rating: rating),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: context.col.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Badges
                  if (badges.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 6, children: badges),
                  ],
                  // Chips
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 6, children: chips),
                  ],
                  // Description
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'About',
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        color: context.col.textSecondary,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ],
                  // Info rows
                  if (infoRows.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const _Divider(),
                    const SizedBox(height: 16),
                    ...infoRows,
                  ],
                  // Image gallery strip
                  if (images.length > 1) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Gallery',
                      style: TextStyle(
                        color: context.col.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ImageGallery(images: images),
                  ],
                  // Bottom actions
                  if (actions != null) ...[
                    const SizedBox(height: 24),
                    actions!,
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;
  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.star.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.star.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: AppColors.star,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Divider(color: context.col.border, height: 1);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: context.col.textSecondary, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? context.col.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _badgeChip(String label, Color bg, Color fg) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
  child: Text(
    label,
    style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
  ),
);

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  const _ImageGallery({required this.images});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 90,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: images.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: images[i],
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          placeholder: (_, _) =>
              Container(color: context.col.surfaceElevated, width: 90),
          errorWidget: (_, _, _) =>
              Container(color: context.col.surfaceElevated, width: 90),
        ),
      ),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: context.col.bg,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}

Future<void> _launchPhone(String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

// ─────────────────────────────────────────────────────────────────────────────
// Restaurant detail
// ─────────────────────────────────────────────────────────────────────────────

class _RestaurantDetail extends StatelessWidget {
  final RestaurantModel restaurant;
  const _RestaurantDetail({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    return _DetailScaffold(
      images: r.images,
      title: r.name,
      rating: r.rating,
      location: r.location,
      description: r.description,
      badges: [
        _badgeChip(
          r.priceRange,
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.primary,
        ),
        if (r.hasDelivery)
          _badgeChip(
            '🛵 Delivery',
            AppColors.success.withValues(alpha: 0.15),
            AppColors.success,
          ),
        if (r.hasReservation)
          _badgeChip(
            '📅 Reservations',
            AppColors.info.withValues(alpha: 0.15),
            AppColors.info,
          ),
      ],
      chips: r.cuisineTypes.map((c) => _ChipWidget(label: c)).toList(),
      infoRows: [
        if (r.openingHours.isNotEmpty)
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Opening Hours',
            value: r.openingHours,
          ),
        if (r.district.isNotEmpty)
          _InfoRow(
            icon: Icons.map_outlined,
            label: 'District',
            value: r.district,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hotel detail
// ─────────────────────────────────────────────────────────────────────────────

class _HotelDetail extends StatelessWidget {
  final HotelModel hotel;
  const _HotelDetail({required this.hotel});

  @override
  Widget build(BuildContext context) {
    final h = hotel;
    return _DetailScaffold(
      images: h.images,
      title: h.name,
      rating: h.rating,
      location: h.location,
      description: h.description,
      badges: [
        _badgeChip(
          h.priceRange,
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.primary,
        ),
        if (h.hasWifi)
          _badgeChip(
            '📶 WiFi',
            AppColors.info.withValues(alpha: 0.15),
            AppColors.info,
          ),
        if (h.hasParking)
          _badgeChip(
            '🅿️ Parking',
            context.col.surfaceElevated,
            context.col.textSecondary,
          ),
        if (h.hasPool)
          _badgeChip(
            '🏊 Pool',
            AppColors.secondary.withValues(alpha: 0.15),
            AppColors.secondary,
          ),
        if (h.hasRestaurant)
          _badgeChip(
            '🍽️ Restaurant',
            AppColors.warning.withValues(alpha: 0.15),
            AppColors.warning,
          ),
      ],
      chips: [
        ...h.amenities.map((a) => _ChipWidget(label: a)),
        ...h.roomTypes.map((r) => _ChipWidget(label: r, accent: true)),
      ],
      infoRows: [
        if (h.district.isNotEmpty)
          _InfoRow(
            icon: Icons.map_outlined,
            label: 'District',
            value: h.district,
          ),
      ],
      actions: h.contactPhone.isNotEmpty
          ? _PrimaryButton(
              label: 'Call Now',
              icon: Icons.phone_rounded,
              onTap: () => _launchPhone(h.contactPhone),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cafe detail
// ─────────────────────────────────────────────────────────────────────────────

class _CafeDetail extends StatelessWidget {
  final CafeModel cafe;
  const _CafeDetail({required this.cafe});

  @override
  Widget build(BuildContext context) {
    final c = cafe;
    return _DetailScaffold(
      images: c.images,
      title: c.name,
      rating: c.rating,
      location: c.location,
      description: c.description,
      badges: [
        _badgeChip(
          c.priceRange,
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.primary,
        ),
        if (c.hasWifi)
          _badgeChip(
            '📶 Free WiFi',
            AppColors.info.withValues(alpha: 0.15),
            AppColors.info,
          ),
        if (c.hasOutdoorSeating)
          _badgeChip(
            '🌿 Outdoor Seating',
            AppColors.success.withValues(alpha: 0.15),
            AppColors.success,
          ),
      ],
      chips: c.specialties.map((s) => _ChipWidget(label: s)).toList(),
      infoRows: [
        if (c.openingHours.isNotEmpty)
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Opening Hours',
            value: c.openingHours,
          ),
        if (c.district.isNotEmpty)
          _InfoRow(
            icon: Icons.map_outlined,
            label: 'District',
            value: c.district,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Homestay detail
// ─────────────────────────────────────────────────────────────────────────────

class _HomestayDetail extends StatelessWidget {
  final HomestayModel homestay;
  const _HomestayDetail({required this.homestay});

  @override
  Widget build(BuildContext context) {
    final h = homestay;
    return _DetailScaffold(
      images: h.images,
      title: h.name,
      rating: h.rating,
      location: h.location,
      description: h.description,
      badges: [
        _badgeChip(
          h.priceRange,
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.primary,
        ),
        if (h.hasBreakfast)
          _badgeChip(
            '🍳 Breakfast Included',
            AppColors.warning.withValues(alpha: 0.15),
            AppColors.warning,
          ),
        if (h.hasFreePickup)
          _badgeChip(
            '🚗 Free Pickup',
            AppColors.success.withValues(alpha: 0.15),
            AppColors.success,
          ),
      ],
      chips: h.amenities.map((a) => _ChipWidget(label: a)).toList(),
      infoRows: [
        if (h.hostName.isNotEmpty)
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Host',
            value: h.hostName,
            valueColor: AppColors.primary,
          ),
        if (h.maxGuests > 0)
          _InfoRow(
            icon: Icons.group_outlined,
            label: 'Max Guests',
            value: '${h.maxGuests} persons',
          ),
        if (h.district.isNotEmpty)
          _InfoRow(
            icon: Icons.map_outlined,
            label: 'District',
            value: h.district,
          ),
      ],
      actions: h.contactPhone.isNotEmpty
          ? _PrimaryButton(
              label: 'Contact Host',
              icon: Icons.phone_rounded,
              onTap: () => _launchPhone(h.contactPhone),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Adventure detail
// ─────────────────────────────────────────────────────────────────────────────

Color _diffColor(BuildContext context, String d) {
  switch (d.toLowerCase()) {
    case 'easy':
      return AppColors.success;
    case 'moderate':
      return AppColors.warning;
    case 'challenging':
      return AppColors.error;
    case 'extreme':
      return AppColors.categoryPurple;
    default:
      return context.col.textSecondary;
  }
}

class _AdventureDetail extends StatelessWidget {
  final AdventureSpotModel adventure;
  const _AdventureDetail({required this.adventure});

  @override
  Widget build(BuildContext context) {
    final a = adventure;
    final dc = _diffColor(context, a.difficulty);
    return _DetailScaffold(
      images: a.images,
      title: a.name,
      rating: a.rating,
      location: a.location,
      description: a.description,
      badges: [
        _badgeChip(
          '${AdventureSpotModel.difficultyEmoji(a.difficulty)} ${a.difficulty}',
          dc.withValues(alpha: 0.15),
          dc,
        ),
        if (a.isPopular)
          _badgeChip(
            '🔥 Popular',
            AppColors.accent.withValues(alpha: 0.15),
            AppColors.accent,
          ),
        if (a.category.isNotEmpty)
          _badgeChip(
            a.category,
            AppColors.secondary.withValues(alpha: 0.15),
            AppColors.secondary,
          ),
      ],
      chips: a.activities.map((act) => _ChipWidget(label: act)).toList(),
      infoRows: [
        if (a.duration.isNotEmpty)
          _InfoRow(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: a.duration,
          ),
        if (a.bestSeason.isNotEmpty)
          _InfoRow(
            icon: Icons.wb_sunny_outlined,
            label: 'Best Season',
            value: a.bestSeason,
          ),
        if (a.district.isNotEmpty)
          _InfoRow(
            icon: Icons.map_outlined,
            label: 'District',
            value: a.district,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shopping detail
// ─────────────────────────────────────────────────────────────────────────────

class _ShoppingDetail extends StatelessWidget {
  final ShoppingAreaModel area;
  const _ShoppingDetail({required this.area});

  @override
  Widget build(BuildContext context) {
    final s = area;
    return _DetailScaffold(
      images: s.images,
      title: s.name,
      rating: s.rating,
      location: s.location,
      description: s.description,
      badges: [
        _badgeChip(
          s.type.toUpperCase(),
          AppColors.secondary.withValues(alpha: 0.15),
          AppColors.secondary,
        ),
        _badgeChip(
          s.priceRange,
          AppColors.primary.withValues(alpha: 0.15),
          AppColors.primary,
        ),
        if (s.hasParking)
          _badgeChip(
            '🅿️ Parking',
            context.col.surfaceElevated,
            context.col.textSecondary,
          ),
        if (s.acceptsCards)
          _badgeChip(
            '💳 Cards OK',
            AppColors.success.withValues(alpha: 0.15),
            AppColors.success,
          ),
        if (s.hasDelivery)
          _badgeChip(
            '🛵 Delivery',
            AppColors.info.withValues(alpha: 0.15),
            AppColors.info,
          ),
      ],
      chips: s.products.map((p) => _ChipWidget(label: p)).toList(),
      infoRows: [
        if (s.openingHours.isNotEmpty)
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Opening Hours',
            value: s.openingHours,
          ),
        if (s.district.isNotEmpty)
          _InfoRow(
            icon: Icons.map_outlined,
            label: 'District',
            value: s.district,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Event detail
// ─────────────────────────────────────────────────────────────────────────────

Color _etColor(String type) {
  switch (type.toLowerCase()) {
    case 'festival':
      return AppColors.accent;
    case 'cultural':
      return AppColors.secondary;
    case 'adventure':
      return AppColors.success;
    default:
      return AppColors.info;
  }
}

class _EventDetail extends StatelessWidget {
  final EventModel event;
  const _EventDetail({required this.event});

  @override
  Widget build(BuildContext context) {
    final e = event;
    final tc = _etColor(e.type);
    final formattedDate = e.date != null
        ? DateFormat('EEEE, MMMM d, yyyy').format(e.date!)
        : '';

    return _DetailScaffold(
      images: e.imageUrl.isNotEmpty ? [e.imageUrl] : [],
      title: e.title,
      rating: 0,
      location: e.location,
      description: e.description,
      badges: [
        _badgeChip(
          '${EventModel.typeEmoji(e.type)} ${e.type.toUpperCase()}',
          tc.withValues(alpha: 0.15),
          tc,
        ),
        if (e.category.isNotEmpty)
          _badgeChip(
            e.category,
            context.col.surfaceElevated,
            context.col.textSecondary,
          ),
      ],
      infoRows: [
        if (formattedDate.isNotEmpty)
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: formattedDate,
            valueColor: tc,
          ),
        if (e.time.isNotEmpty)
          _InfoRow(icon: Icons.schedule_outlined, label: 'Time', value: e.time),
        if (e.attendees > 0)
          _InfoRow(
            icon: Icons.people_outline,
            label: 'Attendees',
            value: '${e.attendees} people going',
            valueColor: AppColors.primary,
          ),
        if (e.district.isNotEmpty)
          _InfoRow(
            icon: Icons.map_outlined,
            label: 'District',
            value: e.district,
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic fallback detail
// ─────────────────────────────────────────────────────────────────────────────

class _GenericDetail extends StatelessWidget {
  final Map<String, dynamic> json;
  final String type;
  const _GenericDetail({required this.json, required this.type});

  @override
  Widget build(BuildContext context) {
    final images = json['images'] != null
        ? List<String>.from(json['images'] as List)
        : (json['imageUrl'] != null
              ? [json['imageUrl'] as String]
              : <String>[]);

    return _DetailScaffold(
      images: images,
      title: json['name']?.toString() ?? json['title']?.toString() ?? type,
      rating: _toDouble(json['rating']),
      location: json['location']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small chip widget
// ─────────────────────────────────────────────────────────────────────────────

class _ChipWidget extends StatelessWidget {
  final String label;
  final bool accent;
  const _ChipWidget({required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: accent
          ? AppColors.primary.withValues(alpha: 0.12)
          : context.col.surfaceElevated,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: accent
            ? AppColors.primary.withValues(alpha: 0.3)
            : context.col.border,
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: accent ? AppColors.primary : context.col.textSecondary,
        fontSize: 12,
        fontWeight: accent ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  );
}
