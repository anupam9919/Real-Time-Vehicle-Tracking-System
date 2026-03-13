import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/adminPages/addBoarding.dart';
import 'package:vehicle/adminPages/addDriver.dart';
import 'package:vehicle/adminPages/addVehicle.dart';
import 'package:vehicle/services/app_logger.dart';
import 'package:vehicle/userPages/signIn.dart';

final _log = AppLogger.getLogger('AdminPage');

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref().child('vehicles');

  List<String> _vehicleNumbers = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _log.info('AdminPage initialized');
    _fetchVehicleNumbers();
  }

  Future<void> _fetchVehicleNumbers() async {
    _log.info('Fetching vehicle numbers from Firebase...');
    setState(() {
      _isRefreshing = true;
    });
    final snapshot = await _databaseReference.once();
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _vehicleNumbers = data.keys.cast<String>().toList();
        _isRefreshing = false;
      });
      _log.info('Fetched ${_vehicleNumbers.length} vehicle numbers: $_vehicleNumbers');
    } else {
      _log.warning('No vehicles found in Firebase');
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _log.info('Admin user logging out');
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignInPage(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Select Vehicle',
                        ),
                        initialValue: null,
                        items: _vehicleNumbers
                            .map((vehicleNumber) => DropdownMenuItem(
                                  value: vehicleNumber,
                                  child: Text(vehicleNumber),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _log.info('Vehicle selected: $value, navigating to AddBoardingPointPage');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddBoardingPointPage(vehicleNumber: value),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          _log.info('Navigating to AddVehiclePage');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddVehiclePage(),
                            ),
                          );
                        },
                        child: const Text('Add Vehicle'),
                      ),
                      const SizedBox(height: 12.0),
                      ElevatedButton(
                        onPressed: () {
                          _log.info('Navigating to AddDriverPage');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddDriverPage(),
                            ),
                          );
                        },
                        child: const Text('Add Driver'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isRefreshing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _log.info('Refresh button pressed');
          _fetchVehicleNumbers();
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
