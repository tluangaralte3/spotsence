import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../core/theme/app_theme.dart';
import '../../models/spot_model.dart';
import '../../services/firestore_cafes_service.dart';
import '../../services/firestore_restaurants_service.dart';
import '../../services/firestore_spots_service.dart';
import 'place_detail_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models for map pins
// ─────────────────────────────────────────────────────────────────────────────

// Filter categories matching the app's listing categories
typedef _MapCat = ({IconData icon, String label, String? type});

const _kMapCategories = <_MapCat>[
  (icon: Iconsax.discover, label: 'All', type: null),
  (icon: Iconsax.map_1, label: 'Tourist Spots', type: 'spot'),
  (icon: Iconsax.cup, label: 'Restaurants', type: 'restaurant'),
  (icon: Iconsax.coffee, label: 'Cafes', type: 'cafe'),
  (icon: Iconsax.activity, label: 'Adventure', type: 'adventure'),
  (icon: Iconsax.buildings, label: 'Homestays', type: 'homestay'),
  (icon: Iconsax.bag_2, label: 'Shopping', type: 'shopping'),
  (icon: Iconsax.calendar, label: 'Events', type: 'event'),
];

class MapPlace {
  final String id;
  final String name;
  final String imageUrl;
  final double lat;
  final double lng;
  final double rating;
  final String category;
  final String type;
  final String location;

  const MapPlace({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.category,
    required this.type,
    required this.location,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final mapPlacesProvider = FutureProvider<List<MapPlace>>((ref) async {
  final restaurants = await ref
      .read(firestoreRestaurantsServiceProvider)
      .getRestaurants(limit: 200);
  final cafes = await ref
      .read(firestoreCafesServiceProvider)
      .getCafes(limit: 200);

  final places = <MapPlace>[];

  for (final r in restaurants) {
    final lat = r.latitude;
    final lng = r.longitude;
    if (lat == null || lng == null) continue;
    places.add(
      MapPlace(
        id: r.id,
        name: r.name,
        imageUrl: r.heroImage,
        lat: lat,
        lng: lng,
        rating: r.rating,
        category: r.cuisineTypes.isNotEmpty
            ? r.cuisineTypes.first.toLowerCase()
            : 'restaurant',
        type: 'restaurant',
        location: r.location,
      ),
    );
  }

  for (final c in cafes) {
    final lat = c.latitude;
    final lng = c.longitude;
    if (lat == null || lng == null) continue;
    places.add(
      MapPlace(
        id: c.id,
        name: c.name,
        imageUrl: c.heroImage,
        lat: lat,
        lng: lng,
        rating: c.rating,
        category: c.specialties.isNotEmpty
            ? c.specialties.first.toLowerCase()
            : 'cafe',
        type: 'cafe',
        location: c.location,
      ),
    );
  }

  return places;
});

/// Spots from Firestore that have lat/lng coordinates
final mapSpotsProvider = FutureProvider<List<SpotModel>>((ref) async {
  return ref
      .read(firestoreSpotsServiceProvider)
      .getFeaturedSpots(category: null, limit: 200);
});

// ─────────────────────────────────────────────────────────────────────────────
// CommunityMap — main widget
// ─────────────────────────────────────────────────────────────────────────────

class CommunityMap extends ConsumerStatefulWidget {
  const CommunityMap({super.key});

  @override
  ConsumerState<CommunityMap> createState() => _CommunityMapState();
}

class _CommunityMapState extends ConsumerState<CommunityMap> {
  final _mapController = MapController();
  _MapCat _selectedCategory = _kMapCategories.first;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  static const LatLng _aizawl = LatLng(23.7271, 92.7176);

  @override
  void dispose() {
    _mapController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MapPlace> _filtered(List<MapPlace> all) {
    var list = all;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.location.toLowerCase().contains(q) ||
                p.category.toLowerCase().contains(q),
          )
          .toList();
    }
    if (_selectedCategory.type != null) {
      final type = _selectedCategory.type!;
      // For restaurant/cafe filter by the place's type field;
      // for other types filter by category string
      list = list
          .where(
            (p) => p.type == type || p.category.toLowerCase().contains(type),
          )
          .toList();
    }
    return list;
  }

  List<Marker> _buildMarkers(List<MapPlace> places) {
    return places
        .map(
          (place) => Marker(
            point: LatLng(place.lat, place.lng),
            width: 64,
            height: 76,
            child: _CirclePin(
              place: place,
              isSelected: false,
              onTap: () => showPlaceDetailSheet(context, place),
            ),
          ),
        )
        .toList();
  }

  List<Marker> _buildSpotMarkers(List<SpotModel> spots) {
    return spots
        .where((s) => s.latitude != null && s.longitude != null)
        .map(
          (spot) => Marker(
            point: LatLng(spot.latitude!, spot.longitude!),
            width: 56,
            height: 56,
            child: _SpotPin(
              spot: spot,
              isSelected: false,
              onTap: () => showSpotDetailSheet(context, spot),
            ),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(mapPlacesProvider);

    return SizedBox.expand(
      child: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          async.when(
            loading: () => const _MapPlaceholder(),
            error: (_, _) => const _MapPlaceholder(),
            data: (allPlaces) {
              final filtered = _filtered(allPlaces);
              final spotsAsync = ref.watch(mapSpotsProvider);
              final spots = spotsAsync.when(
                data: (s) => s,
                loading: () => <SpotModel>[],
                error: (_, _) => <SpotModel>[],
              );
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _aizawl,
                  initialZoom: 13.5,
                  minZoom: 5,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    scrollWheelVelocity: 0.005,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: context.col.isDark
                        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.hillstech.xplooria',
                    retinaMode: MediaQuery.of(context).devicePixelRatio > 1,
                  ),
                  // Spots layer — pulsing blinking pins
                  MarkerLayer(markers: _buildSpotMarkers(spots), rotate: false),
                  // Restaurant/cafe circular image pins
                  MarkerLayer(markers: _buildMarkers(filtered), rotate: false),
                ],
              );
            },
          ),

          // ── Top overlay: search + chips ────────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: _SearchBar(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _kMapCategories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _kMapCategories[i];
                      final selected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : context.col.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : context.col.border,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat.icon,
                                size: 14,
                                color: selected
                                    ? Colors.black
                                    : context.col.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                cat.label,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.black
                                      : context.col.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Zoom controls ──────────────────────────────────────────────────
          Positioned(
            right: 12,
            bottom: MediaQuery.of(context).padding.bottom + 100,
            child: _ZoomControls(mapController: _mapController),
          ),

          // Pin taps now open place_detail_sheet.dart via showPlaceDetailSheet / showSpotDetailSheet
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spot pin — pulsing blink animation for tourist spots
// ─────────────────────────────────────────────────────────────────────────────

class _SpotPin extends StatefulWidget {
  final SpotModel spot;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpotPin({
    required this.spot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SpotPin> createState() => _SpotPinState();
}

class _SpotPinState extends State<_SpotPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scale = Tween<double>(
      begin: 1.0,
      end: 2.2,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut));
    _opacity = Tween<double>(
      begin: 0.7,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Category-based colour
    final color = _spotColor(widget.spot.category);

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing outer ring
            AnimatedBuilder(
              animation: _pulse,
              builder: (_, _) => Transform.scale(
                scale: _scale.value,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: _opacity.value),
                  ),
                ),
              ),
            ),
            // Inner dot / icon
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.isSelected ? 30 : 22,
              height: widget.isSelected ? 30 : 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: widget.isSelected
                      ? Colors.white
                      : color.withValues(alpha: 0.4),
                  width: widget.isSelected ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: widget.isSelected ? 12 : 6,
                    spreadRadius: widget.isSelected ? 2 : 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _spotEmoji(widget.spot.category),
                  style: TextStyle(fontSize: widget.isSelected ? 13 : 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _spotColor(String category) {
    switch (category.toLowerCase()) {
      case 'mountains':
        return const Color(0xFF7C9EFF);
      case 'waterfalls':
        return const Color(0xFF00D4FF);
      case 'cultural sites':
        return const Color(0xFFFFB347);
      case 'viewpoints':
        return const Color(0xFFFF6B9D);
      case 'adventure':
        return const Color(0xFFFF7043);
      case 'lakes':
        return const Color(0xFF26C6DA);
      case 'caves':
        return const Color(0xFFAB47BC);
      default:
        return AppColors.primary;
    }
  }

  String _spotEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'mountains':
        return '⛰️';
      case 'waterfalls':
        return '💧';
      case 'cultural sites':
        return '🏛️';
      case 'viewpoints':
        return '👁️';
      case 'adventure':
        return '🧗';
      case 'lakes':
        return '🏞️';
      case 'caves':
        return '🕳️';
      default:
        return '📍';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circular image map pin widget
// ─────────────────────────────────────────────────────────────────────────────

class _CirclePin extends StatelessWidget {
  final MapPlace place;
  final bool isSelected;
  final VoidCallback onTap;

  const _CirclePin({
    required this.place,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.primary
        : const Color(0xFFD4E842);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: place.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: place.imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => _fallback(),
                      placeholder: (_, _) => _fallback(),
                    )
                  : _fallback(),
            ),
          ),
          CustomPaint(
            size: const Size(14, 10),
            painter: _PinTipPainter(color: borderColor),
          ),
        ],
      ),
    );
  }

  Widget _fallback() => Container(
    color: const Color(0xFF1C2333),
    child: const Icon(Icons.restaurant, color: Color(0xFF8892A4), size: 24),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Pin tip triangle painter
// ─────────────────────────────────────────────────────────────────────────────

class _PinTipPainter extends CustomPainter {
  final Color color;
  const _PinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTipPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// Zoom +/- controls
// ─────────────────────────────────────────────────────────────────────────────

class _ZoomControls extends StatelessWidget {
  final MapController mapController;
  const _ZoomControls({required this.mapController});

  void _zoom(double delta) {
    final current = mapController.camera.zoom;
    mapController.move(
      mapController.camera.center,
      (current + delta).clamp(5, 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.col.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.col.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomBtn(icon: Icons.add, onTap: () => _zoom(1)),
          Container(height: 1, color: context.col.border),
          _ZoomBtn(icon: Icons.remove, onTap: () => _zoom(-1)),
        ],
      ),
    );
  }
}

class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(icon, color: context.col.textPrimary, size: 20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder while loading
// ─────────────────────────────────────────────────────────────────────────────

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        color: context.col.bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Loading map…',
                style: TextStyle(
                  color: context.col.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.col.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.col.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.search,
              color: context.col.textSecondary,
              size: 18,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(color: context.col.textPrimary, fontSize: 14),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Search restaurants & cafes…',
                hintStyle: TextStyle(
                  color: context.col.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.close,
                  color: context.col.textSecondary,
                  size: 18,
                ),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.map_outlined,
                color: context.col.textSecondary,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}
