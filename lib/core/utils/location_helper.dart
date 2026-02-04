import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Location and distance calculation utilities
class LocationHelper {
  /// Calculate distance between two points in meters
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check and request location permissions
  static Future<bool> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current position
  static Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if user is near a location (within radius in meters)
  static bool isNearby({
    required double userLat,
    required double userLon,
    required double targetLat,
    required double targetLon,
    double radiusInMeters = 100,
  }) {
    final distance = calculateDistance(
      lat1: userLat,
      lon1: userLon,
      lat2: targetLat,
      lon2: targetLon,
    );

    return distance <= radiusInMeters;
  }

  /// Get bearing between two points
  static double calculateBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLon = _toRadians(lon2 - lon1);
    final y = sin(dLon) * cos(_toRadians(lat2));
    final x =
        cos(_toRadians(lat1)) * sin(_toRadians(lat2)) -
        sin(_toRadians(lat1)) * cos(_toRadians(lat2)) * cos(dLon);

    final bearing = atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
  static double _toDegrees(double radians) => radians * 180 / pi;
}
