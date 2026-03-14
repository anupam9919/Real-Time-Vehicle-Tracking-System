import 'dart:math';

/// Utility class for geographic distance calculations.
///
/// Consolidates the duplicated distance logic from:
/// - `bus_stop.dart` → `calculateDistances()` 
/// - `firebase.dart` → `calculateETA()` (distance portion)
/// - `track.dart` → `calculateDistances()`
class DistanceUtils {
  const DistanceUtils._();

  /// Haversine formula to calculate the distance between two coordinates.
  ///
  /// Returns distance in **meters**.
  /// This is a pure function with no external dependencies, making it
  /// easily testable without mocking Geolocator.
  static double haversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * asin(sqrt(a));
    return earthRadiusMeters * c;
  }

  /// Formats a distance in meters to a human-readable string.
  ///
  /// Examples: "450 m", "2.3 km"
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static double _degreesToRadians(double degrees) => degrees * pi / 180;
}
