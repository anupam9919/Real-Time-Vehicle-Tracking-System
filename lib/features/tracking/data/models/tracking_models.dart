import 'package:vehicle/features/tracking/domain/entities/tracking_entities.dart';

/// Data-layer model for [Vehicle] with Firebase serialization.
class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.vehicleNumber,
    super.driverMobileNumber,
    super.boardingPoint,
    super.destination,
    super.location,
  });

  /// Parses a vehicle from RTDB data at `/vehicles/{vehicleId}`.
  factory VehicleModel.fromFirebase({
    required String id,
    required Map<String, dynamic> data,
  }) {
    VehicleLocation? location;
    final locData = _toStringMap(data['location']);
    if (locData != null) {
      location = VehicleLocationModel.fromMap(locData);
    }

    return VehicleModel(
      id: id,
      vehicleNumber: data['vehicleNumber']?.toString() ?? id,
      driverMobileNumber: data['driverMobileNumber']?.toString(),
      boardingPoint: data['boardingPoint']?.toString(),
      destination: data['destination']?.toString(),
      location: location,
    );
  }
}

/// Data-layer model for [VehicleLocation] with Firebase serialization.
class VehicleLocationModel extends VehicleLocation {
  const VehicleLocationModel({
    required super.latitude,
    required super.longitude,
    super.speedMs,
    super.timestamp,
  });

  factory VehicleLocationModel.fromMap(Map<String, dynamic> data) {
    return VehicleLocationModel(
      latitude: _toDouble(data['latitude']) ?? 0.0,
      longitude: _toDouble(data['longitude']) ?? 0.0,
      speedMs: _toDouble(data['speed']) ?? 0.0,
      timestamp: data['timestamp']?.toString(),
    );
  }
}

/// Data-layer model for [BoardingPoint] with Firebase serialization.
class BoardingPointModel extends BoardingPoint {
  const BoardingPointModel({
    super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
  });

  factory BoardingPointModel.fromFirebase({
    String? id,
    required Map<String, dynamic> data,
  }) {
    return BoardingPointModel(
      id: id,
      name: data['name']?.toString() ?? 'Unnamed Stop',
      latitude: _toDouble(data['latitude']) ?? 0.0,
      longitude: _toDouble(data['longitude']) ?? 0.0,
    );
  }

  Map<String, dynamic> toFirebaseMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Recursively extracts boarding point maps from any shape of Firebase data.
  /// Handles both List and Map structures.
  static List<BoardingPointModel> extractFromFirebase(dynamic input) {
    List<BoardingPointModel> results = [];
    if (input == null) return results;

    if (input is List) {
      for (var i = 0; i < input.length; i++) {
        results.addAll(extractFromFirebase(input[i]));
      }
    } else if (input is Map) {
      final map = input.map((k, v) => MapEntry(k.toString(), v));
      if (map.containsKey('name') && map.containsKey('latitude')) {
        results.add(BoardingPointModel.fromFirebase(data: map));
      } else {
        for (var entry in map.entries) {
          if (entry.value is Map || entry.value is List) {
            results.addAll(extractFromFirebase(entry.value));
          }
        }
      }
    }
    return results;
  }
}

// ── Helpers ──

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return double.tryParse(value.toString());
}

Map<String, dynamic>? _toStringMap(dynamic value) {
  if (value == null) return null;
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  return null;
}
