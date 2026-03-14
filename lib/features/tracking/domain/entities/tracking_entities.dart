/// Domain entity representing a vehicle in the tracking system.
class Vehicle {
  final String id;
  final String vehicleNumber;
  final String? driverMobileNumber;
  final String? boardingPoint; // route start
  final String? destination;
  final VehicleLocation? location;

  const Vehicle({
    required this.id,
    required this.vehicleNumber,
    this.driverMobileNumber,
    this.boardingPoint,
    this.destination,
    this.location,
  });

  @override
  String toString() => 'Vehicle(id: $id, number: $vehicleNumber)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Live GPS location of a vehicle.
class VehicleLocation {
  final double latitude;
  final double longitude;
  final double speedMs; // Speed in m/s from Geolocator
  final String? timestamp;

  const VehicleLocation({
    required this.latitude,
    required this.longitude,
    this.speedMs = 0.0,
    this.timestamp,
  });

  double get speedKmh => speedMs * 3.6;
}

/// Domain entity representing a boarding point (bus stop).
class BoardingPoint {
  final String? id;
  final String name;
  final double latitude;
  final double longitude;

  const BoardingPoint({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  /// Whether this boarding point has valid GPS coordinates.
  bool get hasValidCoords => latitude != 0.0 && longitude != 0.0;

  @override
  String toString() => 'BoardingPoint(name: $name, lat: $latitude, lng: $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardingPoint &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(name, latitude, longitude);
}
