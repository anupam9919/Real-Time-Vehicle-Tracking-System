import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:vehicle/userPages/boardingPoint.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('vehicles');
  Timer? _timer;
  final String vehicleName = 'Ac'; // Replace with actual vehicle name
// final String vehicleName =_selectedBus;

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
        // Update the UI with the retrieved location data
        print('Latitude: ${vehicleLocation['latitude']}');
        print('Longitude: ${vehicleLocation['longitude']}');
        print('Timestamp: ${vehicleLocation['timestamp']}');
      });
    } else {
      print('No location data found for $vehicleName');
    }
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
                            // Text(boardingPoints[i].eta),
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
                                // Text(boardingPoints[i].eta),
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
