import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('FirebaseService');

DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

Future<Map<String, double>> getDriverLocation(String vehicleName) async {
  _log.info('Fetching driver location for vehicle: $vehicleName');
  final snapshot = await _databaseReference
      .child('vehicles')
      .child(vehicleName)
      .child('location')
      .get();

  if (snapshot.exists) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    final lat = data['latitude'].toDouble();
    final lng = data['longitude'].toDouble();
    _log.info('Location found for $vehicleName: lat=$lat, lng=$lng');
    return {
      'latitude': lat,
      'longitude': lng,
    };
  } else {
    _log.warning('No location data found for vehicle: $vehicleName');
    return {}; // Return an empty map if the location data doesn't exist
  }
}

Future<String> calculateETA(
    double destinationLatitude, double destinationLongitude) async {
  double currentLatitude = 25.42042;
  double currentLongitude = 81.94188;

  _log.fine('Calculating ETA from ($currentLatitude, $currentLongitude) to ($destinationLatitude, $destinationLongitude)');

  double distanceInMeters = Geolocator.distanceBetween(
    currentLatitude,
    currentLongitude,
    destinationLatitude,
    destinationLongitude,
  );

  double timeInHours = distanceInMeters / 30000;
  int timeInMinutes = (timeInHours * 60).toInt();
  _log.info('ETA calculated: $timeInMinutes minutes (distance: ${distanceInMeters.toStringAsFixed(0)}m)');
  return '$timeInMinutes minutes';
}
