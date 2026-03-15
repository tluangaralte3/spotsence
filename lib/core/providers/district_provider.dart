import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mizoram district capital coordinates (WGS-84)
// ─────────────────────────────────────────────────────────────────────────────

class MizoramDistrict {
  final String name;
  final double lat;
  final double lng;
  const MizoramDistrict(this.name, this.lat, this.lng);
}

const kMizoramDistricts = [
  MizoramDistrict('Aizawl', 23.7271, 92.7176),
  MizoramDistrict('Champhai', 23.4619, 93.3270),
  MizoramDistrict('Hnahthial', 22.9833, 92.8085),
  MizoramDistrict('Khawzawl', 23.2200, 93.1900),
  MizoramDistrict('Kolasib', 24.2274, 92.6776),
  MizoramDistrict('Lawngtlai', 22.0274, 92.9049),
  MizoramDistrict('Lunglei', 22.8868, 92.7350),
  MizoramDistrict('Mamit', 23.9222, 92.4777),
  MizoramDistrict('Saiha', 22.4900, 92.9740),
  MizoramDistrict('Saitual', 23.3800, 92.9200),
  MizoramDistrict('Serchhip', 23.3083, 92.8486),
];

/// All district name strings, sorted alphabetically.
final kDistrictNames = kMizoramDistricts.map((d) => d.name).toList()..sort();

// ── Haversine formula ─────────────────────────────────────────────────────────

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _toRad(double deg) => deg * math.pi / 180;

// ── Nearest district ──────────────────────────────────────────────────────────

String nearestDistrict(double lat, double lng) {
  MizoramDistrict? nearest;
  double minDist = double.infinity;
  for (final d in kMizoramDistricts) {
    final dist = _haversineKm(lat, lng, d.lat, d.lng);
    if (dist < minDist) {
      minDist = dist;
      nearest = d;
    }
  }
  return nearest?.name ?? 'Mizoram';
}

// ─────────────────────────────────────────────────────────────────────────────
// GPS-detected district state
// ─────────────────────────────────────────────────────────────────────────────

class DistrictState {
  final String district;
  final bool loading;
  final String? error;

  const DistrictState({
    this.district = 'Mizoram',
    this.loading = false,
    this.error,
  });

  DistrictState copyWith({String? district, bool? loading, String? error}) =>
      DistrictState(
        district: district ?? this.district,
        loading: loading ?? this.loading,
        error: error,
      );
}

class DistrictNotifier extends Notifier<DistrictState> {
  @override
  DistrictState build() {
    Future.microtask(_detect);
    return const DistrictState(loading: true);
  }

  Future<void> _detect() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        state = const DistrictState(district: 'Mizoram');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final name = nearestDistrict(pos.latitude, pos.longitude);
      state = DistrictState(district: name);
    } catch (_) {
      state = const DistrictState(district: 'Mizoram');
    }
  }

  Future<void> refresh() async {
    state = const DistrictState(loading: true);
    await _detect();
  }
}

final districtProvider = NotifierProvider<DistrictNotifier, DistrictState>(
  DistrictNotifier.new,
);

// ─────────────────────────────────────────────────────────────────────────────
// Selected district filter — null means "All districts"
// ─────────────────────────────────────────────────────────────────────────────

/// Holds the user's manually selected district filter.
/// `null` = show all (no filter applied).
class SelectedDistrictNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? district) => state = district;
  void clear() => state = null;
}

final selectedDistrictProvider =
    NotifierProvider<SelectedDistrictNotifier, String?>(
      SelectedDistrictNotifier.new,
    );
