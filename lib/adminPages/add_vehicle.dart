import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('AddVehiclePage');

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('vehicles');

  final _formKey = GlobalKey<FormState>();
  String _vehicleNumber = '';

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
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Vehicle Number',
                  hintText: 'e.g. BUS-01',
                  prefixIcon: Icon(Icons.directions_bus),
                  border: OutlineInputBorder(),
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

              const SizedBox(height: 24.0),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _log.info('Form validated, adding vehicle: $_vehicleNumber');
                      _addVehicle();
                      Navigator.pop(context);
                    } else {
                      _log.warning('Form validation failed for vehicle: $_vehicleNumber');
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Vehicle', style: TextStyle(fontSize: 16)),
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
      ),
    );
  }

  void _addVehicle() async {
    if (!mounted) return;

    _log.info('Adding vehicle: number=$_vehicleNumber');

    final vehicleData = {
      'boardingPoints': [],
      // 'location' is intentionally left out until a driver goes live.
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
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }
}
