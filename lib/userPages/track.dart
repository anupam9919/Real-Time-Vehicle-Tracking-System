import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:vehicle/userPages/boardingPoint.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({Key? key}) : super(key: key);

  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('vehicles');
  Timer? _timer;
  final String vehicleName = 'Ac'; // Replace with actual vehicle name

  List<double> _distances = [];
  List<Duration> _etas = [];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchVehicleLocation();
    });
  }

  Future<Map<String, dynamic>> getVehicleLocation(String vehicleName) async {
    final snapshot =
        await _databaseReference.child(vehicleName).child('location').get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return {
        'latitude': data['latitude'].toDouble(),
        'longitude': data['longitude'].toDouble(),
        'timestamp': data['timestamp'] as String,
      };
    } else {
      return {}; // Return an empty map if the location data doesn't exist
    }
  }

  Future<void> _fetchVehicleLocation() async {
    final vehicleLocation = await getVehicleLocation(vehicleName);
    if (vehicleLocation.isNotEmpty) {
      setState(() {
        // Calculate distances and ETAs
        _distances = calculateDistances(
            vehicleLocation['latitude'], vehicleLocation['longitude']);
        _etas = calculateETAs(_distances);
      });
    } else {
      print('No location data found for $vehicleName');
    }
  }

  List<double> calculateDistances(double latitude, double longitude) {
    List<double> distances = [];

    for (var boardingPoint in boardingPoints) {
      double distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        boardingPoint.latitude,
        boardingPoint.longitude,
      );
      distances.add(distance);
    }

    return distances;
  }

  List<Duration> calculateETAs(List<double> distances) {
    List<Duration> etas = [];

    for (var distance in distances) {
      double distanceInKm = distance / 1000;
      double timeInSeconds =
          distanceInKm / (4 / 3600); // Assuming walking speed of 4 km/h
      etas.add(Duration(seconds: timeInSeconds.round()));
    }

    return etas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < boardingPoints.length; i++)
              TimelineTile(
                alignment: TimelineAlign.manual,
                lineXY: 0.5,
                indicatorStyle: const IndicatorStyle(
                  width: 10,
                  color: Colors.blue,
                  padding: EdgeInsets.all(2),
                ),
                startChild: boardingPoints[i].isStart ||
                        boardingPoints[i].isIntermediate
                    ? Container(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(boardingPoints[i].name),
                            Text(
                                'Distance: ${_distances.isNotEmpty ? _distances[i].toStringAsFixed(2) : "Calculating..."} meters'),
                            Text(
                                'ETA: ${_etas.isNotEmpty ? _etas[i].inMinutes : "Calculating..."} minutes'),
                          ],
                        ),
                      )
                    : const SizedBox(),
                endChild:
                    boardingPoints[i].isEnd || boardingPoints[i].isIntermediate
                        ? Container(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(boardingPoints[i].name),
                                Text(
                                    'Distance: ${_distances.isNotEmpty ? _distances[i].toStringAsFixed(2) : "Calculating..."} meters'),
                                Text(
                                    'ETA: ${_etas.isNotEmpty ? _etas[i].inMinutes : "Calculating..."} minutes'),
                              ],
                            ),
                          )
                        : const SizedBox(),
              ),
          ],
        ),
      ),
    );
  }
}
