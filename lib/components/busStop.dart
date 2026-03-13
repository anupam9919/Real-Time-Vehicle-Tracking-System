import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vehicle/services/app_logger.dart';
import 'package:vehicle/userPages/boarding.dart';
import 'package:vehicle/userPages/searchPage.dart';

final _log = AppLogger.getLogger('BusStopWidget');

class BusStopWidget extends StatefulWidget {
  const BusStopWidget({super.key});

  @override
  _BusStopWidgetState createState() => _BusStopWidgetState();
}

class _BusStopWidgetState extends State<BusStopWidget> {
  Future<Position>? _currentLocationFuture;
  String? _nearestBoardingPointName;
  String? _eta;
  List<Map<String, dynamic>> _nearestBuses = [];

  @override
  void initState() {
    super.initState();
    _log.info('BusStopWidget initialized');
    _getCurrentLocationAndNearestBoardingPoint();
  }

  Future<void> _getCurrentLocationAndNearestBoardingPoint() async {
    try {
      _log.info('Fetching current location and nearest boarding point...');
      Position userLocation = await _getCurrentLocation();
      _log.info('User location acquired: lat=${userLocation.latitude}, lng=${userLocation.longitude}');

      List<double> distances = calculateDistances(userLocation, boardingPoints);
      int nearestBoardingPointIndex = findNearestBoardingPointIndex(distances);
      BoardingPoint nearestBoardingPoint =
          boardingPoints[nearestBoardingPointIndex];
      Duration eta =
          calculateETA(distances[nearestBoardingPointIndex], 4); // 4 km/h

      _log.info('Nearest boarding point: ${nearestBoardingPoint.name} (distance: ${distances[nearestBoardingPointIndex].toStringAsFixed(0)}m, ETA: ${eta.inMinutes} min)');

      List<Map<String, dynamic>> nearestBuses =
          await getNearestBuses(userLocation);
      _log.info('Found ${nearestBuses.length} nearest buses');

      setState(() {
        _nearestBoardingPointName = nearestBoardingPoint.name;
        _eta = '${eta.inMinutes} minutes';
        _nearestBuses = nearestBuses;
      });
    } catch (e, stackTrace) {
      _log.severe('Error getting location/nearest boarding point', e, stackTrace);
    }
  }

  Future<List<Map<String, dynamic>>> getNearestBuses(
      Position userLocation) async {
    _log.fine('Calculating nearest buses to user location');
    List<Map<String, dynamic>> nearestBuses = [];

    // Dummy data for demonstration purposes
    List<Map<String, dynamic>> dummyBuses = [
      {
        'vehicleName': 'Bus-01',
        'latitude': 25.362357,
        'longitude': 81.882431,
      },
      {
        'vehicleName': 'Bus-02',
        'latitude': 25.322336,
        'longitude': 81.914504,
      },
      {
        'vehicleName': 'Bus-03',
        'latitude': 25.386473,
        'longitude': 81.868368,
      },
    ];

    for (var bus in dummyBuses) {
      double distance = Geolocator.distanceBetween(
        userLocation.latitude,
        userLocation.longitude,
        bus['latitude'],
        bus['longitude'],
      );
      Duration eta = calculateETA(distance, 30); // 30 km/h for buses
      nearestBuses.add({
        'vehicleName': bus['vehicleName'],
        'eta': eta,
      });
      _log.fine('Bus ${bus['vehicleName']}: distance=${distance.toStringAsFixed(0)}m, ETA=${eta.inMinutes} min');
    }

    nearestBuses
        .sort((a, b) => a['eta'].inMinutes.compareTo(b['eta'].inMinutes));

    return nearestBuses.take(2).toList();
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    _log.fine('Checking location service availability...');
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _log.warning('Location services are disabled');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    _log.fine('Current location permission: $permission');
    if (permission == LocationPermission.denied) {
      _log.info('Requesting location permission...');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _log.warning('Location permission denied by user');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _log.severe('Location permissions are permanently denied');
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    _log.fine('Location permission granted, getting current position...');
    return await Geolocator.getCurrentPosition();
  }

  List<double> calculateDistances(
      Position userLocation, List<BoardingPoint> boardingPoints) {
    _log.fine('Calculating distances to ${boardingPoints.length} boarding points');
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

  Duration calculateETA(double distance, double speed) {
    double distanceInKm = distance / 1000;
    double timeInSeconds = distanceInKm / (speed / 3600);
    return Duration(seconds: timeInSeconds.round());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nearest Bus Stop',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 30),
              _buildBusStopInfo(
                icon: Icons.location_on,
                title: _nearestBoardingPointName ?? 'Loading...',
                subTitle: _eta ?? '',
              ),
              const SizedBox(height: 40),
              Text(
                'Next Buses',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: _nearestBuses
                      .map((bus) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: _buildBusInfo(
                              busNumber: bus['vehicleName'],
                              eta: bus['eta'].inMinutes.toString(),
                            ),
                          ))
                      .toList(),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () {
                    _log.info('Navigating to SearchPage from BusStopWidget');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SearchPage(),
                      ),
                    );
                  },
                  child: const Text('See all buses'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusStopInfo({
    required IconData icon,
    required String title,
    required String subTitle,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          subTitle,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBusInfo({
    required String busNumber,
    required String eta,
  }) {
    return Row(
      children: [
        const Icon(Icons.bus_alert_rounded, color: Colors.grey),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              busNumber,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          'ETA: $eta minutes',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
