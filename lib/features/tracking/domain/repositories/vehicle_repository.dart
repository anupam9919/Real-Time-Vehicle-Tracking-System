import 'package:vehicle/features/tracking/domain/entities/tracking_entities.dart';

/// Abstract repository interface for vehicle tracking operations.
///
/// Defines the contract for accessing vehicle and boarding point data.
abstract class VehicleRepository {
  /// Stream of all available vehicle IDs.
  Stream<List<String>> watchAvailableVehicles();

  /// Stream of live location updates for a specific vehicle.
  Stream<VehicleLocation?> watchVehicleLocation(String vehicleId);

  /// Stream of boarding points for a specific vehicle.
  Stream<List<BoardingPoint>> watchBoardingPoints(String vehicleId);

  /// One-shot fetch of vehicle details.
  Future<Vehicle?> getVehicle(String vehicleId);

  /// Update vehicle location (used by driver).
  Future<void> updateVehicleLocation({
    required String vehicleId,
    required double latitude,
    required double longitude,
    required double speed,
    required String timestamp,
  });
}
