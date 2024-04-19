import 'dart:math';

import 'package:geolocator/geolocator.dart';

import 'boardingPoint.dart';

Future<Position> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled, request the user to enable them
    return Future.error('Location services are disabled.');
  }

  // Request permission to access the user's location
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permission is denied, handle the case
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permission is permanently denied, handle the case
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // Get the user's current position
  return await Geolocator.getCurrentPosition();
}

List<double> calculateDistances(
    Position userLocation, List<BoardingPoint> boardingPoints) {
  List<double> distances = [];

  for (var boardingPoint in boardingPoints) {
    double distance = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      boardingPoint.latitude,
      boardingPoint.longitude,
    );
    distances.add(distance);
  }

  return distances;
}

int findNearestBoardingPointIndex(List<double> distances) {
  double minDistance = distances.reduce(min);
  return distances.indexOf(minDistance);
}

Duration calculateETA(double distance, double walkingSpeed) {
  // Convert distance from meters to kilometers
  double distanceInKm = distance / 1000;

  // Calculate the time in seconds using the walking speed (assumed in km/h)
  double timeInSeconds = distanceInKm / (walkingSpeed / 3600);

  // Convert the time from seconds to a Duration object
  return Duration(seconds: timeInSeconds.round());
}

Future<String> findNearestBoardingPointAndETA() async {
  // Get the user's current location
  Position userLocation = await _getCurrentLocation();

  // Calculate the distances between the user's location and each boarding point
  List<double> distances = calculateDistances(userLocation, boardingPoints);

  // Find the index of the nearest boarding point
  int nearestBoardingPointIndex = findNearestBoardingPointIndex(distances);

  // Get the nearest boarding point
  BoardingPoint nearestBoardingPoint =
      boardingPoints[nearestBoardingPointIndex];

  // Calculate the ETA to reach the nearest boarding point (assuming a walking speed of 4 km/h)
  Duration eta = calculateETA(distances[nearestBoardingPointIndex], 4);

  // Return the result
  return 'Nearest boarding point: ${nearestBoardingPoint.name}\nETA: ${eta.inMinutes} minutes';
}
