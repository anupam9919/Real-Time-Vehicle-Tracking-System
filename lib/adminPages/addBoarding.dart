import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('AddBoardingPointPage');

class AddBoardingPointPage extends StatefulWidget {
  final String vehicleNumber;

  const AddBoardingPointPage({super.key, required this.vehicleNumber});

  @override
  _AddBoardingPointPageState createState() => _AddBoardingPointPageState();
}

class _AddBoardingPointPageState extends State<AddBoardingPointPage> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('vehicles');

  String _boardingPointName = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isStart = false;
  bool _isEnd = false;
  bool _isIntermediate = false;

  @override
  void initState() {
    super.initState();
    _log.info('AddBoardingPointPage initialized for vehicle: ${widget.vehicleNumber}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Boarding Point'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Boarding Point Name',
              ),
              onChanged: (value) {
                setState(() {
                  _boardingPointName = value;
                });
              },
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Latitude',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  _latitude = double.parse(value);
                });
              },
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Longitude',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  _longitude = double.parse(value);
                });
              },
            ),
            Row(
              children: [
                Checkbox(
                  value: _isStart,
                  onChanged: (value) {
                    setState(() {
                      _isStart = value!;
                      _isEnd = false;
                      _isIntermediate = false;
                      _log.fine('Boarding point type changed: isStart=$_isStart');
                    });
                  },
                ),
                const Text('Is Start'),
                Checkbox(
                  value: _isEnd,
                  onChanged: (value) {
                    setState(() {
                      _isEnd = value!;
                      _isStart = false;
                      _isIntermediate = false;
                      _log.fine('Boarding point type changed: isEnd=$_isEnd');
                    });
                  },
                ),
                const Text('Is End'),
                Checkbox(
                  value: _isIntermediate,
                  onChanged: (value) {
                    setState(() {
                      _isIntermediate = value!;
                      _isStart = false;
                      _isEnd = false;
                      _log.fine('Boarding point type changed: isIntermediate=$_isIntermediate');
                    });
                  },
                ),
                const Text('Is Intermediate'),
              ],
            ),
            ElevatedButton(
              onPressed: _addBoardingPoint,
              child: const Text('Add Boarding Point'),
            ),
          ],
        ),
      ),
    );
  }

  void _addBoardingPoint() async {
    _log.info('Adding boarding point: name=$_boardingPointName, lat=$_latitude, lng=$_longitude for vehicle: ${widget.vehicleNumber}');
    _log.fine('Boarding point type: isStart=$_isStart, isEnd=$_isEnd, isIntermediate=$_isIntermediate');

    final position = await Geolocator.getCurrentPosition();
    _log.fine('Current device position: lat=${position.latitude}, lng=${position.longitude}');

    final formattedTimestamp = DateTime.now().toIso8601String();

    final boardingPoint = {
      'name': _boardingPointName,
      'latitude': _latitude,
      'longitude': _longitude,
      'isStart': _isStart,
      'isEnd': _isEnd,
      'isIntermediate': _isIntermediate,
    };

    _databaseReference
        .child(widget.vehicleNumber)
        .child('boardingPoints')
        .push()
        .set(boardingPoint);
    _log.info('Boarding point "$_boardingPointName" saved to Firebase');

    _databaseReference.child(widget.vehicleNumber).child('location').set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': formattedTimestamp,
    });
    _log.info('Vehicle ${widget.vehicleNumber} location updated in Firebase');

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Boarding point added successfully'),
      ),
    );
  }
}
