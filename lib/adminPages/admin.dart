import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vehicle/userPages/signIn.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('vehicles');

  String _vehicleNumber = '';
  String _driverName = '';
  String _driverMobileNumber = '';
  String _boardingPointName = '';
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isStart = false;
  bool _isEnd = false;
  bool _isIntermediate = false;

  List<String> _vehicleNumbers = [];

  @override
  void initState() {
    super.initState();
    _fetchVehicleNumbers();
  }

  Future<void> _fetchVehicleNumbers() async {
    final snapshot = await _databaseReference.once();
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _vehicleNumbers = data.keys.cast<String>().toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Handle logout
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => SignInPage(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Vehicle',
              ),
              value: _vehicleNumber.isEmpty ? null : _vehicleNumber,
              items: _vehicleNumbers
                  .map((vehicleNumber) => DropdownMenuItem(
                        value: vehicleNumber,
                        child: Text(vehicleNumber),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _vehicleNumber = value!;
                });
              },
            ),
            if (_vehicleNumber.isNotEmpty)
              Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Driver Name',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _driverName = value;
                      });
                    },
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Driver Mobile Number',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _driverMobileNumber = value;
                      });
                    },
                  ),
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
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
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
                    onPressed: () {
                      _addBoardingPoint();
                    },
                    child: Text('Add Boarding Point'),
                  ),
                ],
              ),
            if (_vehicleNumber.isEmpty)
              ElevatedButton(
                onPressed: () {
                  _addVehicle();
                },
                child: Text('Add Vehicle'),
              ),
          ],
        ),
      ),
    );
  }

  void _addVehicle() async {
    final position = await Geolocator.getCurrentPosition();
    final formattedTimestamp = DateTime.now().toIso8601String();

    final vehicleData = {
      'driverName': _driverName,
      'driverMobileNumber': _driverMobileNumber,
      'boardingPoints': [],
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': formattedTimestamp,
      }
    };

    _databaseReference.child(_vehicleNumber).set(vehicleData);
    _clearForm();
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
        .child(_vehicleNumber)
        .child('boardingPoints')
        .push()
        .set(boardingPoint);

    _databaseReference.child(_vehicleNumber).child('location').set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': formattedTimestamp,
    });

    _clearForm();
  }

  void _clearForm() {
    setState(() {
      _driverName = '';
      _driverMobileNumber = '';
      _boardingPointName = '';
      _latitude = 0.0;
      _longitude = 0.0;
      _isStart = false;
      _isEnd = false;
      _isIntermediate = false;
    });
  }
}
