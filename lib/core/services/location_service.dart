import 'package:geolocator/geolocator.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('LocationService');

/// Single source of truth for GPS permissions and location access.
///
/// Replaces the 3 duplicated implementations previously in:
/// - `bus_stop.dart` → `_getCurrentLocation()`
/// - `driver_home.dart` → `_determinePosition()`
/// - `locationUtils.dart` → `_getCurrentLocation()`
class LocationService {
  const LocationService();

  /// Check and request location permissions, then return a one-shot position.
  ///
  /// Throws a [LocationServiceException] if services are disabled or
  /// permissions are denied.
  Future<Position> getCurrentPosition() async {
    _log.fine('Checking location service availability...');
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _log.warning('Location services are disabled');
      throw const LocationServiceException('Location services are disabled. Please enable GPS.');
    }

    var permission = await Geolocator.checkPermission();
    _log.fine('Current location permission: $permission');

    if (permission == LocationPermission.denied) {
      _log.info('Requesting location permission...');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _log.warning('Location permission denied by user');
        throw const LocationServiceException('Location permission denied. Please grant access in Settings.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _log.severe('Location permissions are permanently denied');
      throw const LocationServiceException(
        'Location permissions are permanently denied. Please enable them in app settings.',
      );
    }

    _log.fine('Location permission granted, getting current position...');
    return Geolocator.getCurrentPosition();
  }

  /// Returns a stream of position updates for continuous tracking.
  ///
  /// Used by the driver to continuously broadcast their GPS position.
  /// Replaces the `Timer.periodic` + `getCurrentPosition` pattern.
  Stream<Position> getPositionStream({
    int distanceFilter = 10,
    Duration? interval,
  }) {
    _log.info('Starting position stream (distanceFilter: ${distanceFilter}m)');
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
        intervalDuration: interval ?? const Duration(seconds: 5),
      ),
    );
  }

  /// Calculates the distance in meters between two coordinates.
  ///
  /// Wrapper around [Geolocator.distanceBetween] for testability.
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}

/// Exception thrown when location services or permissions fail.
class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);

  @override
  String toString() => 'LocationServiceException: $message';
}
