import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AddVehiclePage extends StatefulWidget {
  @override
  _AddVehiclePageState createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('vehicles');

  final _formKey = GlobalKey<FormState>();
  String _vehicleNumber = '';
  String _driverName = '';
  String _driverMobileNumber = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Vehicle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Vehicle Number',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a vehicle number';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _vehicleNumber = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Driver Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a driver name';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _driverName = value;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Driver Mobile Number',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a driver mobile number';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _driverMobileNumber = value;
                  });
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _addVehicle();
                    Navigator.pop(context);
                  }
                },
                child: Text('Add Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addVehicle() async {
    if (!mounted) return;

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

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
            SnackBar(
              content: Text('Vehicle added successfully'),
              duration: Duration(
                  seconds: 2), // Optional: Set the duration of the SnackBar
            ),
          )
          .closed
          .then((_) {
        // After the SnackBar is closed, navigate back
        Navigator.pop(context);
      });
    }
  }
}
