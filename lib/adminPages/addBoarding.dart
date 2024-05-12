import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AddBoardingPointPage extends StatefulWidget {
  final String vehicleNumber;

  AddBoardingPointPage({required this.vehicleNumber});

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Boarding Point'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Boarding Point Name',
              ),
              onChanged: (value) {
                setState(() {
                  _boardingPointName = value;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Latitude',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                setState(() {
                  _latitude = double.parse(value);
                });
              },
            ),
            TextField(
              decoration: InputDecoration(
                labelText: 'Longitude',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                    });
                  },
                ),
                Text('Is Start'),
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
                Text('Is End'),
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
                Text('Is Intermediate'),
              ],
            ),
            ElevatedButton(
              onPressed: _addBoardingPoint,
              child: Text('Add Boarding Point'),
            ),
          ],
        ),
      ),
    );
  }

  void _addBoardingPoint() async {
    final position = await Geolocator.getCurrentPosition();
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

    _databaseReference.child(widget.vehicleNumber).child('location').set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': formattedTimestamp,
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Boarding point added successfully'),
      ),
    );
  }
}
