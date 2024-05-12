import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vehicle/adminPages/addBoarding.dart';
import 'package:vehicle/adminPages/addVehicle.dart';
import 'package:vehicle/adminPages/vehicle_page.dart';
import 'package:vehicle/userPages/signIn.dart';

class AdminPage extends StatefulWidget {
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
    _fetchVehicleNumbers();
  }

  Future<void> _fetchVehicleNumbers() async {
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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Select Vehicle',
                        ),
                        value: null,
                        items: _vehicleNumbers
                            .map((vehicleNumber) => DropdownMenuItem(
                                  value: vehicleNumber,
                                  child: Text(vehicleNumber),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
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
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddVehiclePage(),
                            ),
                          );
                        },
                        child: Text('Add Vehicle'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isRefreshing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchVehicleNumbers,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
      ),
    );
  }
}
