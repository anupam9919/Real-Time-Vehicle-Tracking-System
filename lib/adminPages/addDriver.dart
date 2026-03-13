import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('AddDriverPage');

class AddDriverPage extends StatefulWidget {
  const AddDriverPage({super.key});

  @override
  State<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final _formKey = GlobalKey<FormState>();

  String _driverId = '';
  String _password = '';
  String _driverName = '';
  String _mobileNumber = '';
  String _assignedVehicle = '';

  List<String> _vehicleNumbers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _log.info('AddDriverPage initialized');
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    _log.info('Fetching available vehicles...');
    try {
      final snapshot = await _dbRef.child('vehicles').once();
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _vehicleNumbers = data.keys.cast<String>().toList();
        });
        _log.info('Fetched ${_vehicleNumbers.length} vehicles');
      }
    } catch (e, st) {
      _log.severe('Error fetching vehicles', e, st);
    }
  }

  Future<void> _addDriver() async {
    if (!_formKey.currentState!.validate()) return;
    if (_assignedVehicle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    setState(() => _isLoading = true);

    _log.info('Adding driver: id=$_driverId, name=$_driverName, vehicle=$_assignedVehicle');

    try {
      await _dbRef.child('drivers').child(_driverId).set({
        'password': _password,
        'name': _driverName,
        'mobileNumber': _mobileNumber,
        'assignedVehicle': _assignedVehicle,
      });

      _log.info('Driver $_driverId saved to Firebase');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver added successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e, st) {
      _log.severe('Error adding driver', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Driver')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Driver ID (login username)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (v) => _driverId = v.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (v) => _password = v.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Driver Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (v) => _driverName = v.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Mobile Number'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (v) => _mobileNumber = v.trim(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Assign Vehicle'),
                items: _vehicleNumbers
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _assignedVehicle = v;
                },
                validator: (v) => (v == null || v.isEmpty) ? 'Select a vehicle' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addDriver,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Add Driver'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
