import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('AddBoardingPointPage');

class AddBoardingPointPage extends StatefulWidget {
  final String vehicleNumber;

  const AddBoardingPointPage({super.key, required this.vehicleNumber});

  @override
  State<AddBoardingPointPage> createState() => _AddBoardingPointPageState();
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
        child: ListView(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Boarding Point Name',
                prefixIcon: Icon(Icons.place),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _boardingPointName = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Latitude',
                prefixIcon: Icon(Icons.explore),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  _latitude = double.parse(value);
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Longitude',
                prefixIcon: Icon(Icons.explore),
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  _longitude = double.parse(value);
                });
              },
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _isStart,
                      onChanged: (value) {
                        setState(() {
                          _isStart = value!;
                          _isEnd = false;
                          _isIntermediate = false;
                        });
                      },
                    ),
                    const Text('Start'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _isEnd,
                      onChanged: (value) {
                        setState(() {
                          _isEnd = value!;
                          _isStart = false;
                          _isIntermediate = false;
                        });
                      },
                    ),
                    const Text('End'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: _isIntermediate,
                      onChanged: (value) {
                        setState(() {
                          _isIntermediate = value!;
                          _isStart = false;
                          _isEnd = false;
                        });
                      },
                    ),
                    const Text('Intermediate'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _addBoardingPoint,
                icon: const Icon(Icons.add_location),
                label: const Text('Add Boarding Point', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addBoardingPoint() async {
    _log.info('Adding boarding point: name=$_boardingPointName, lat=$_latitude, lng=$_longitude for vehicle: ${widget.vehicleNumber}');
    _log.fine('Boarding point type: isStart=$_isStart, isEnd=$_isEnd, isIntermediate=$_isIntermediate');

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

    if (mounted) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boarding point added successfully')),
      );
    }
  }
}
