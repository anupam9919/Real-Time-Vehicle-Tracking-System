import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vehicle/features/tracking/data/datasources/vehicle_remote_ds.dart';
import 'package:vehicle/features/tracking/data/repositories/vehicle_repo_impl.dart';
import 'package:vehicle/features/tracking/domain/entities/tracking_entities.dart';
import 'package:vehicle/features/tracking/domain/repositories/vehicle_repository.dart';

// ── Data layer providers ──

/// Provides the [VehicleRemoteDataSource] singleton.
final vehicleRemoteDataSourceProvider = Provider<VehicleRemoteDataSource>((ref) {
  return VehicleRemoteDataSource();
});

/// Provides the [VehicleRepository] implementation.
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepositoryImpl(
    remoteDataSource: ref.watch(vehicleRemoteDataSourceProvider),
  );
});

// ── Stream providers ──

/// Stream of all available vehicle IDs.
final availableVehiclesProvider = StreamProvider<List<String>>((ref) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.watchAvailableVehicles();
});

/// Stream of live location for a specific vehicle.
/// Usage: `ref.watch(vehicleLocationProvider('A1'))`
final vehicleLocationProvider =
    StreamProvider.family<VehicleLocation?, String>((ref, vehicleId) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.watchVehicleLocation(vehicleId);
});

/// Stream of boarding points for a specific vehicle.
/// Usage: `ref.watch(boardingPointsProvider('A1'))`
final boardingPointsProvider =
    StreamProvider.family<List<BoardingPoint>, String>((ref, vehicleId) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.watchBoardingPoints(vehicleId);
});

/// One-shot fetch of vehicle details.
/// Usage: `ref.watch(vehicleDetailsProvider('A1'))`
final vehicleDetailsProvider =
    FutureProvider.family<Vehicle?, String>((ref, vehicleId) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getVehicle(vehicleId);
});
