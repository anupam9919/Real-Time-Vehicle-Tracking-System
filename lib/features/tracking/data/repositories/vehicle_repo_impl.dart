import 'package:vehicle/features/tracking/data/datasources/vehicle_remote_ds.dart';
import 'package:vehicle/features/tracking/domain/entities/tracking_entities.dart';
import 'package:vehicle/features/tracking/domain/repositories/vehicle_repository.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('VehicleRepositoryImpl');

/// Concrete implementation of [VehicleRepository].
///
/// Delegates to [VehicleRemoteDataSource] for all Firebase operations.
class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource _remoteDataSource;

  VehicleRepositoryImpl({required VehicleRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Stream<List<String>> watchAvailableVehicles() {
    _log.info('Repository: watchAvailableVehicles');
    return _remoteDataSource.watchAvailableVehicles();
  }

  @override
  Stream<VehicleLocation?> watchVehicleLocation(String vehicleId) {
    _log.info('Repository: watchVehicleLocation($vehicleId)');
    return _remoteDataSource.watchVehicleLocation(vehicleId);
  }

  @override
  Stream<List<BoardingPoint>> watchBoardingPoints(String vehicleId) {
    _log.info('Repository: watchBoardingPoints($vehicleId)');
    return _remoteDataSource.watchBoardingPoints(vehicleId);
  }

  @override
  Future<Vehicle?> getVehicle(String vehicleId) {
    _log.info('Repository: getVehicle($vehicleId)');
    return _remoteDataSource.getVehicle(vehicleId);
  }

  @override
  Future<void> updateVehicleLocation({
    required String vehicleId,
    required double latitude,
    required double longitude,
    required double speed,
    required String timestamp,
  }) {
    _log.info('Repository: updateVehicleLocation($vehicleId)');
    return _remoteDataSource.updateVehicleLocation(
      vehicleId: vehicleId,
      latitude: latitude,
      longitude: longitude,
      speed: speed,
      timestamp: timestamp,
    );
  }
}
