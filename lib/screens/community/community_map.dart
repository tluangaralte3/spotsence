import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../../core/theme/app_theme.dart';
import '../../models/spot_model.dart';
import '../../services/firestore_cafes_service.dart';
import '../../services/firestore_restaurants_service.dart';
import '../../services/firestore_spots_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models for map pins
// ─────────────────────────────────────────────────────────────────────────────

// Filter categories matching the app's listing categories
typedef _MapCat = ({String emoji, String label, String? type});

const _kMapCategories = <_MapCat>[
  (emoji: '🗺️', label: 'All', type: null),
  (emoji: '🗺️', label: 'Tourist Spots', type: 'spot'),
  (emoji: '🍽️', label: 'Restaurants', type: 'restaurant'),
  (emoji: '☕', label: 'Cafes', type: 'cafe'),
  (emoji: '🧗', label: 'Adventure', type: 'adventure'),
  (emoji: '🏡', label: 'Homestays', type: 'homestay'),
  (emoji: '🛍️', label: 'Shopping', type: 'shopping'),
  (emoji: '📅', label: 'Events', type: 'event'),
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
  MapPlace? _selectedPlace;
  SpotModel? _selectedSpot;
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
              isSelected: _selectedPlace?.id == place.id,
              onTap: () => setState(() {
                _selectedPlace = _selectedPlace?.id == place.id ? null : place;
                _selectedSpot = null;
              }),
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
              isSelected: _selectedSpot?.id == spot.id,
              onTap: () => setState(() {
                _selectedSpot = _selectedSpot?.id == spot.id ? null : spot;
                _selectedPlace = null;
              }),
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
            error: (_, __) => const _MapPlaceholder(),
            data: (allPlaces) {
              final filtered = _filtered(allPlaces);
              final spotsAsync = ref.watch(mapSpotsProvider);
              final spots = spotsAsync.when(
                data: (s) => s,
                loading: () => <SpotModel>[],
                error: (_, __) => <SpotModel>[],
              );
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _aizawl,
                  initialZoom: 13.5,
                  minZoom: 5,
                  maxZoom: 18,
                  onTap: (_, __) => setState(() {
                    _selectedPlace = null;
                    _selectedSpot = null;
                  }),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    scrollWheelVelocity: 0.005,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.hillstech.spotmizoram',
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
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                                : AppColors.surface.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            '${cat.emoji}  ${cat.label}',
                            style: TextStyle(
                              color: selected
                                  ? Colors.black
                                  : AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
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

          // ── Bottom place card (restaurants/cafes) ─────────────────────────
          if (_selectedPlace != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: _PlaceCard(
                place: _selectedPlace!,
                onClose: () => setState(() => _selectedPlace = null),
              ),
            ),

          // ── Bottom spot card (tourist spots) ──────────────────────────────
          if (_selectedSpot != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: _SpotCard(
                spot: _selectedSpot!,
                onClose: () => setState(() => _selectedSpot = null),
              ),
            ),
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
              builder: (_, __) => Transform.scale(
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
// Spot detail card
// ─────────────────────────────────────────────────────────────────────────────

class _SpotCard extends StatelessWidget {
  final SpotModel spot;
  final VoidCallback onClose;

  const _SpotCard({required this.spot, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: spot.heroImage.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: spot.heroImage,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _spotImgFallback(),
                  )
                : _spotImgFallback(),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    spot.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.star,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        spot.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColors.star,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          spot.category,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (spot.locationAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            spot.locationAddress,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
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
          ),
          // Close
          GestureDetector(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _spotImgFallback() => Container(
    width: 80,
    height: 80,
    color: AppColors.surfaceElevated,
    child: const Icon(Icons.terrain, color: AppColors.textMuted),
  );
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
                  color: Colors.black.withOpacity(0.4),
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
                      errorWidget: (_, __, ___) => _fallback(),
                      placeholder: (_, __) => _fallback(),
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
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
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
          Container(height: 1, color: AppColors.border),
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
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
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
        color: const Color(0xFF0A0E1A),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Loading map…',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
        color: AppColors.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search, color: AppColors.textSecondary, size: 18),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(
                hintText: 'Search restaurants & cafes…',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.map_outlined,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Place Detail Card (bottom sheet-style)
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceCard extends StatelessWidget {
  final MapPlace place;
  final VoidCallback onClose;

  const _PlaceCard({required this.place, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: place.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: place.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: AppColors.surfaceElevated,
                      child: const Icon(
                        Icons.restaurant,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: AppColors.surfaceElevated,
                    child: const Icon(
                      Icons.restaurant,
                      color: AppColors.textMuted,
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: AppColors.star,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColors.star,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          place.type,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (place.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 11,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            place.location,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
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
          ),
          GestureDetector(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
