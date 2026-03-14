/// Utility class for Estimated Time of Arrival calculations.
///
/// Consolidates the duplicated ETA logic from:
/// - `bus_stop.dart:176` → `calculateETA(distance, speedKmh)`
/// - `firebase.dart:32` → `calculateETA(destLat, destLng)` (hardcoded origin!)
/// - `track.dart` → inline ETA calculation
class EtaUtils {
  const EtaUtils._();

  /// Default vehicle speed assumption in km/h when actual speed is unavailable.
  static const double defaultVehicleSpeedKmh = 25.0;

  /// Walking speed for pedestrian ETA in km/h.
  static const double walkingSpeedKmh = 4.0;

  /// Minimum vehicle speed cap in km/h (avoids division errors at standstill).
  static const double minSpeedKmh = 5.0;

  /// Maximum vehicle speed cap in km/h.
  static const double maxSpeedKmh = 120.0;

  /// Calculate ETA given distance in meters and speed in km/h.
  ///
  /// Returns a [Duration] representing the estimated travel time.
  /// Speed is clamped to [minSpeedKmh]–[maxSpeedKmh] range.
  static Duration calculate({
    required double distanceMeters,
    required double speedKmh,
  }) {
    final clampedSpeed = speedKmh.clamp(minSpeedKmh, maxSpeedKmh);
    final distanceKm = distanceMeters / 1000.0;
    final timeHours = distanceKm / clampedSpeed;
    return Duration(seconds: (timeHours * 3600).round());
  }

  /// Calculate ETA using the default vehicle speed.
  static Duration calculateWithDefaultSpeed(double distanceMeters) {
    return calculate(
      distanceMeters: distanceMeters,
      speedKmh: defaultVehicleSpeedKmh,
    );
  }

  /// Calculate walking ETA.
  static Duration calculateWalkingEta(double distanceMeters) {
    return calculate(
      distanceMeters: distanceMeters,
      speedKmh: walkingSpeedKmh,
    );
  }

  /// Normalize a speed value from m/s (from GPS) to km/h,
  /// with fallback to default if speed is too low (e.g., stationary).
  static double normalizeSpeedMsToKmh(double speedMs) {
    final speedKmh = speedMs * 3.6;
    return (speedKmh > 1.0) ? speedKmh.clamp(minSpeedKmh, maxSpeedKmh) : defaultVehicleSpeedKmh;
  }

  /// Formats an ETA duration to a human-readable string.
  ///
  /// Examples: "3 min", "1 hr 15 min", "< 1 min"
  static String formatEta(Duration eta) {
    if (eta.inMinutes < 1) return '< 1 min';
    if (eta.inHours < 1) return '${eta.inMinutes} min';
    final hours = eta.inHours;
    final mins = eta.inMinutes.remainder(60);
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }
}
