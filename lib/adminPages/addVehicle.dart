import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('AddVehiclePage');

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

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
  void initState() {
    super.initState();
    _log.info('AddVehiclePage initialized');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Vehicle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _log.warning('Form validation failed: vehicle number is empty');
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
                decoration: const InputDecoration(
                  labelText: 'Driver Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _log.warning('Form validation failed: driver name is empty');
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
                decoration: const InputDecoration(
                  labelText: 'Driver Mobile Number',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    _log.warning('Form validation failed: driver mobile number is empty');
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
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _log.info('Form validated, adding vehicle: $_vehicleNumber');
                    _addVehicle();
                    Navigator.pop(context);
                  } else {
                    _log.warning('Form validation failed for vehicle: $_vehicleNumber');
                  }
                },
                child: const Text('Add Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addVehicle() async {
    if (!mounted) return;

    _log.info('Adding vehicle: number=$_vehicleNumber, driver=$_driverName, mobile=$_driverMobileNumber');

    final position = await Geolocator.getCurrentPosition();
    _log.fine('Current position for vehicle: lat=${position.latitude}, lng=${position.longitude}');

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
    _log.info('Vehicle $_vehicleNumber saved to Firebase successfully');

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
            const SnackBar(
              content: Text('Vehicle added successfully'),
              duration: Duration(
                  seconds: 2), // Optional: Set the duration of the SnackBar
            ),
          )
          .closed
          .then((_) {
        // After the SnackBar is closed, navigate back
        _log.fine('SnackBar closed, navigating back');
        Navigator.pop(context);
      });
    }
  }
}
