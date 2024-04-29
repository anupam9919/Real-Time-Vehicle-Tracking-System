import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vehicle/userPages/boarding.dart';
import 'package:vehicle/userPages/searchPage.dart';

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
    _getCurrentLocationAndNearestBoardingPoint();
  }

  Future<void> _getCurrentLocationAndNearestBoardingPoint() async {
    try {
      Position userLocation = await _getCurrentLocation();
      List<double> distances = calculateDistances(userLocation, boardingPoints);
      int nearestBoardingPointIndex = findNearestBoardingPointIndex(distances);
      BoardingPoint nearestBoardingPoint =
          boardingPoints[nearestBoardingPointIndex];
      Duration eta =
          calculateETA(distances[nearestBoardingPointIndex], 4); // 4 km/h

      List<Map<String, dynamic>> nearestBuses =
          await getNearestBuses(userLocation);

      setState(() {
        _nearestBoardingPointName = nearestBoardingPoint.name;
        _eta = '${eta.inMinutes} minutes';
        _nearestBuses = nearestBuses;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<List<Map<String, dynamic>>> getNearestBuses(
      Position userLocation) async {
    List<Map<String, dynamic>> nearestBuses = [];

    // Dummy data for demonstration purposes
    List<Map<String, dynamic>> dummyBuses = [
      {
        'vehicleName': 'Bus-01',
        'latitude': 31.4834,
        'longitude': 74.3722,
      },
      {
        'vehicleName': 'Bus-02',
        'latitude': 31.4804,
        'longitude': 74.3752,
      },
      {
        'vehicleName': 'Bus-03',
        'latitude': 31.4824,
        'longitude': 74.3762,
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
    }

    nearestBuses
        .sort((a, b) => a['eta'].inMinutes.compareTo(b['eta'].inMinutes));

    return nearestBuses.take(2).toList();
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

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

  Duration calculateETA(double distance, double speed) {
    double distanceInKm = distance / 1000;
    double timeInSeconds = distanceInKm / (speed / 3600);
    return Duration(seconds: timeInSeconds.round());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
              const SizedBox(height: 16),
              _buildBusStopInfo(
                icon: Icons.location_on,
                title: _nearestBoardingPointName ?? 'Loading...',
                subTitle: _eta ?? '',
              ),
              const SizedBox(height: 16),
              Text(
                'Next Buses',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._nearestBuses.map((bus) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: _buildBusInfo(
                      busNumber: bus['vehicleName'],
                      eta: bus['eta'].inMinutes.toString(),
                    ),
                  )),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
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
