import 'package:firebase_database/firebase_database.dart';
import 'package:vehicle/core/constants/firebase_paths.dart';
import 'package:vehicle/core/errors/exceptions.dart';
import 'package:vehicle/features/tracking/data/models/tracking_models.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('VehicleRemoteDataSource');

/// Remote data source encapsulating all Firebase RTDB operations
/// for vehicle tracking.
///
/// Uses `onValue` stream listeners instead of Timer polling.
class VehicleRemoteDataSource {
  final DatabaseReference _dbRef;

  VehicleRemoteDataSource({DatabaseReference? dbRef})
      : _dbRef = dbRef ?? FirebaseDatabase.instance.ref();

  /// Stream of all vehicle IDs available in the system.
  Stream<List<String>> watchAvailableVehicles() {
    _log.info('Watching available vehicles');
    return _dbRef.child(FirebasePaths.vehicles).onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return <String>[];

      final map = _toStringMap(raw);
      if (map == null) {
        _log.warning('vehicles node is not a Map: ${raw.runtimeType}');
        return <String>[];
      }

      final vehicles = map.keys.toList();
      _log.info('Vehicles updated: ${vehicles.length} found');
      return vehicles;
    });
  }

  /// Stream of live location updates for a specific vehicle.
  Stream<VehicleLocationModel?> watchVehicleLocation(String vehicleId) {
    _log.info('Watching location for vehicle: $vehicleId');
    return _dbRef
        .child(FirebasePaths.vehicleLocation(vehicleId))
        .onValue
        .map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return null;

      final map = _toStringMap(raw);
      if (map == null) {
        _log.warning('Location data is not a Map: ${raw.runtimeType}');
        return null;
      }

      return VehicleLocationModel.fromMap(map);
    });
  }

  /// Stream of boarding points for a specific vehicle.
  Stream<List<BoardingPointModel>> watchBoardingPoints(String vehicleId) {
    _log.info('Watching boarding points for vehicle: $vehicleId');
    return _dbRef
        .child(FirebasePaths.vehicleBoardingPoints(vehicleId))
        .onValue
        .map((event) {
      final raw = event.snapshot.value;
      _log.fine('Boarding points raw data: ${raw.runtimeType}');

      final points = BoardingPointModel.extractFromFirebase(raw);
      _log.info('Extracted ${points.length} boarding points for $vehicleId');
      return points;
    });
  }

  /// One-shot fetch of full vehicle details.
  Future<VehicleModel?> getVehicle(String vehicleId) async {
    try {
      final snapshot =
          await _dbRef.child('${FirebasePaths.vehicles}/$vehicleId').get();
      if (!snapshot.exists) return null;

      final map = _toStringMap(snapshot.value);
      if (map == null) return null;

      return VehicleModel.fromFirebase(id: vehicleId, data: map);
    } catch (e) {
      _log.severe('Error fetching vehicle $vehicleId', e);
      throw ServerException('Failed to fetch vehicle: $e', e);
    }
  }

  /// Update vehicle location (called by driver during transmission).
  Future<void> updateVehicleLocation({
    required String vehicleId,
    required double latitude,
    required double longitude,
    required double speed,
    required String timestamp,
  }) async {
    try {
      await _dbRef
          .child('${FirebasePaths.vehicles}/$vehicleId')
          .update({
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'speed': speed,
          'timestamp': timestamp,
        },
      });
      _log.fine(
        'Location updated for $vehicleId: '
        'lat=$latitude, lng=$longitude, '
        'speed=${(speed * 3.6).toStringAsFixed(1)} km/h',
      );
    } catch (e) {
      _log.severe('Error updating location for $vehicleId', e);
      throw ServerException('Failed to update location: $e', e);
    }
  }

  static Map<String, dynamic>? _toStringMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }
}
