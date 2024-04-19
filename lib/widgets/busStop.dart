import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vehicle/userPages/boardingPoint.dart';
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

      setState(() {
        _nearestBoardingPointName = nearestBoardingPoint.name;
        _eta = '${eta.inMinutes} minutes';
      });
    } catch (e) {
      print(e);
    }
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

  Duration calculateETA(double distance, double walkingSpeed) {
    double distanceInKm = distance / 1000;
    double timeInSeconds = distanceInKm / (walkingSpeed / 3600);
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
                icon: Icons.bus_alert,
                title: _nearestBoardingPointName ?? 'Loading...',
                subTitle: _eta ?? '',
              ),
              const SizedBox(height: 16),
              Text(
                'Next Buses',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildBusInfo(
                busNumber: 'PE-5',
                destination: 'To New Shantipuram',
                time: '10:05 AM',
              ),
              const SizedBox(height: 8),
              _buildBusInfo(
                busNumber: 'PE-5',
                destination: 'To Jahangirabad',
                time: '10:51 AM',
              ),
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
    required String destination,
    required String time,
  }) {
    return Row(
      children: [
        const Icon(Icons.bus_alert, color: Colors.grey),
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
            Text(
              destination,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          time,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
