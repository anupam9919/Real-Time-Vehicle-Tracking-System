import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:vehicle/services/app_logger.dart';

import 'boarding.dart';

final _log = AppLogger.getLogger('LocationUtils');

Future<Position> _getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  _log.fine('Checking location service availability...');
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled, request the user to enable them
    _log.warning('Location services are disabled');
    return Future.error('Location services are disabled.');
  }

  // Request permission to access the user's location
  permission = await Geolocator.checkPermission();
  _log.fine('Current location permission: $permission');
  if (permission == LocationPermission.denied) {
    _log.info('Requesting location permission...');
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permission is denied, handle the case
      _log.warning('Location permission denied by user');
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permission is permanently denied, handle the case
    _log.severe('Location permissions are permanently denied');
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // Get the user's current position
  _log.fine('Getting current GPS position...');
  final position = await Geolocator.getCurrentPosition();
  _log.info('Current position acquired: lat=${position.latitude}, lng=${position.longitude}');
  return position;
}

List<double> calculateDistances(
    Position userLocation, List<BoardingPoint> boardingPoints) {
  _log.fine('Calculating distances from user to ${boardingPoints.length} boarding points');
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
  int index = distances.indexOf(minDistance);
  _log.fine('Nearest boarding point index: $index (distance: ${minDistance.toStringAsFixed(0)}m)');
  return index;
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
  _log.info('Finding nearest boarding point and ETA...');
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

  _log.info('Nearest boarding point: ${nearestBoardingPoint.name}, ETA: ${eta.inMinutes} minutes');

  // Return the result
  return 'Nearest boarding point: ${nearestBoardingPoint.name}\nETA: ${eta.inMinutes} minutes';
}
