import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vehicle/services/app_logger.dart';
import 'package:vehicle/userPages/sign_in.dart';

final _log = AppLogger.getLogger('DriverHome');

class DriverHomePage extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String assignedVehicle;

  const DriverHomePage({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.assignedVehicle,
  });

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  Timer? _locationTimer;
  bool _isLive = false;
  Position? _lastPosition;
  String? _lastTimestamp;

  // Vehicle details fetched from Firebase
  String _vehicleNumber = '';
  String _driverMobileNumber = '';
  String _boardingPoint = '';
  String _destination = '';

  @override
  void initState() {
    super.initState();
    _log.info('DriverHomePage initialized for driver: ${widget.driverId}, vehicle: ${widget.assignedVehicle}');
    _fetchVehicleDetails();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _log.info('DriverHomePage disposed, timer cancelled');
    super.dispose();
  }

  Future<void> _fetchVehicleDetails() async {
    _log.info('Fetching vehicle details for: ${widget.assignedVehicle}');
    try {
      final snapshot = await _dbRef.child('vehicles').child(widget.assignedVehicle).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _vehicleNumber = data['vehicleNumber']?.toString() ?? widget.assignedVehicle;
          _driverMobileNumber = data['driverMobileNumber']?.toString() ?? '';
          _boardingPoint = data['boardingPoint']?.toString() ?? '';
          _destination = data['destination']?.toString() ?? '';
        });
        _log.info('Vehicle details loaded: number=$_vehicleNumber');
      } else {
        _log.warning('No vehicle data found for: ${widget.assignedVehicle}');
      }
    } catch (e, st) {
      _log.severe('Error fetching vehicle details', e, st);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _startTransmitting() {
    _log.info('Starting GPS transmission for vehicle: ${widget.assignedVehicle}');
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final position = await _determinePosition();
        final timestamp = DateTime.now().toIso8601String();

        await _dbRef.child('vehicles').child(widget.assignedVehicle).update({
          'location': {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': timestamp,
          },
        });

        setState(() {
          _lastPosition = position;
          _lastTimestamp = timestamp;
        });

        _log.fine('Location transmitted: lat=${position.latitude}, lng=${position.longitude}');
      } catch (e) {
        _log.warning('Error transmitting location: $e');
      }
    });
  }

  void _stopTransmitting() {
    _log.info('Stopping GPS transmission');
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void _toggleLive() {
    if (!_isLive && widget.assignedVehicle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vehicle assigned. Contact your admin to assign a vehicle first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _isLive = !_isLive;
      if (_isLive) {
        _startTransmitting();
      } else {
        _stopTransmitting();
      }
    });
  }

  void _triggerSOS() {
    _log.warning('SOS triggered by driver: ${widget.driverId}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS triggered!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _logout() {
    _stopTransmitting();
    _log.info('Driver ${widget.driverId} logging out');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SignInPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text(
          'Driver Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vehicle badge
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: _isLive ? Colors.green[700] : Colors.blueGrey[700],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.assignedVehicle,
                      style: const TextStyle(fontSize: 36.0, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    if (_isLive)
                      const Text('● LIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Info card
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Driver: ${widget.driverName}', style: const TextStyle(fontSize: 16.0)),
                      const SizedBox(height: 8.0),
                      if (_vehicleNumber.isNotEmpty)
                        Text('Vehicle Number: $_vehicleNumber', style: const TextStyle(fontSize: 16.0)),
                      if (_driverMobileNumber.isNotEmpty) ...[
                        const SizedBox(height: 8.0),
                        Text('Mobile: $_driverMobileNumber', style: const TextStyle(fontSize: 16.0)),
                      ],
                      if (_boardingPoint.isNotEmpty) ...[
                        const SizedBox(height: 8.0),
                        Text('Boarding Point: $_boardingPoint', style: const TextStyle(fontSize: 16.0)),
                      ],
                      if (_destination.isNotEmpty) ...[
                        const SizedBox(height: 8.0),
                        Text('Destination: $_destination', style: const TextStyle(fontSize: 16.0)),
                      ],
                      const Spacer(),
                      if (_lastPosition != null) ...[
                        const Divider(),
                        Text(
                          'Last: ${_lastPosition!.latitude.toStringAsFixed(5)}, ${_lastPosition!.longitude.toStringAsFixed(5)}',
                          style: TextStyle(fontSize: 13.0, color: Colors.grey[600]),
                        ),
                        Text(
                          'At: ${_lastTimestamp ?? ""}',
                          style: TextStyle(fontSize: 13.0, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Go Live / Stop button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _toggleLive,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLive ? Colors.red : Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _isLive ? 'STOP' : 'GO LIVE',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),

            // SOS button (only when live)
            if (_isLive) ...[
              const SizedBox(height: 12.0),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _triggerSOS,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('SOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
