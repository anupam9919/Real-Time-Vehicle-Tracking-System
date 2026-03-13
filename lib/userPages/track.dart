import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:vehicle/services/app_logger.dart';
import 'package:vehicle/userPages/boarding.dart';

final _log = AppLogger.getLogger('TrackingPage');

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('vehicles');
  Timer? _timer;
  final String vehicleName = 'A1'; // Replace with actual vehicle name

  List<double> _distances = [];
  List<Duration> _etas = [];

  @override
  void initState() {
    super.initState();
    _log.info('TrackingPage initialized for vehicle: $vehicleName');
    _startTimer();
  }

  @override
  void dispose() {
    _log.info('TrackingPage disposed, cancelling timer');
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _log.info('Starting location fetch timer (interval: 5s)');
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchVehicleLocation();
    });
  }

  Future<Map<String, dynamic>> getVehicleLocation(String vehicleName) async {
    _log.fine('Querying Firebase for vehicle location: $vehicleName');
    try {
      final snapshot =
          await _databaseReference.child(vehicleName).child('location').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final location = {
          'latitude': data['latitude'].toDouble(),
          'longitude': data['longitude'].toDouble(),
          'timestamp': data['timestamp'] as String,
        };
        _log.fine('Vehicle $vehicleName location: lat=${location['latitude']}, lng=${location['longitude']}');
        return location;
      } else {
        _log.warning('No location data found in Firebase for vehicle: $vehicleName');
        return {}; // Return an empty map if the location data doesn't exist
      }
    } catch (e, stackTrace) {
      _log.severe('Error getting vehicle location from Firebase. Check your Database Security Rules.', e, stackTrace);
      return {};
    }
  }

  Future<void> _fetchVehicleLocation() async {
    _log.fine('Fetching vehicle location for: $vehicleName');
    final vehicleLocation = await getVehicleLocation(vehicleName);
    if (vehicleLocation.isNotEmpty) {
      setState(() {
        // Calculate distances and ETAs
        _distances = calculateDistances(
            vehicleLocation['latitude'], vehicleLocation['longitude']);
        _etas = calculateETAs(_distances);
      });
      _log.info('Updated distances and ETAs for $vehicleName (${_distances.length} boarding points)');
    } else {
      _log.warning('No location data found for $vehicleName, skipping update');
    }
  }

  List<double> calculateDistances(double latitude, double longitude) {
    _log.fine('Calculating distances from ($latitude, $longitude) to ${boardingPoints.length} boarding points');
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

    // Assuming an average bus speed of 30 km/h (you can adjust this value as needed)
    double busSpeedInKmPerHour = 30;

    for (var distance in distances) {
      double distanceInKm = distance / 1000;
      double timeInHours = distanceInKm / busSpeedInKmPerHour;
      int timeInSeconds = (timeInHours * 3600).round();
      etas.add(Duration(seconds: timeInSeconds));
    }

    _log.fine('ETAs calculated for ${etas.length} boarding points');
    return etas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < boardingPoints.length; i++)
                      TimelineTile(
                        alignment: TimelineAlign.manual,
                        lineXY: 0.1,
                        indicatorStyle: const IndicatorStyle(
                          width: 10,
                          color: Colors.deepPurple,
                          padding: EdgeInsets.all(2),
                        ),
                        endChild: Container(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Row(
                            children: [
                              Text(boardingPoints[i].name),
                              const SizedBox(width: 16.0),
                              Text(
                                  'ETA: ${_etas.isNotEmpty ? _etas[i].inMinutes : "Calculating..."} minutes'),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
