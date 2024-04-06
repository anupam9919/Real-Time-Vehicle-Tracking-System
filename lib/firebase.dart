import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

DatabaseReference _databaseReference = FirebaseDatabase.instance.ref();

Future<Map<String, double>> getDriverLocation(String vehicleName) async {
  final snapshot = await _databaseReference
      .child('vehicles')
      .child(vehicleName)
      .child('location')
      .get();

  if (snapshot.exists) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return {
      'latitude': data['latitude'].toDouble(),
      'longitude': data['longitude'].toDouble(),
    };
  } else {
    return {}; // Return an empty map if the location data doesn't exist
  }
}

Future<String> calculateETA(
    double destinationLatitude, double destinationLongitude) async {
  double currentLatitude = 25.42042;
  double currentLongitude = 81.94188;

  double distanceInMeters = Geolocator.distanceBetween(
    currentLatitude,
    currentLongitude,
    destinationLatitude,
    destinationLongitude,
  );

  double timeInHours = distanceInMeters / 30000;
  int timeInMinutes = (timeInHours * 60).toInt();
  return '$timeInMinutes minutes';
}
