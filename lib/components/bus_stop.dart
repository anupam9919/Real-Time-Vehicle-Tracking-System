import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('BusStopWidget');

class BusStopWidget extends StatefulWidget {
  const BusStopWidget({super.key});

  @override
  State<BusStopWidget> createState() => _BusStopWidgetState();
}

class _BusStopWidgetState extends State<BusStopWidget> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  
  String? _nearestBoardingPointName;
  String? _etaToBoardingPoint;
  List<Map<String, dynamic>> _nearestBuses = [];
  bool _isLoading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _log.info('BusStopWidget initialized');
    _loadLiveVehicleData();
  }

  Future<void> _loadLiveVehicleData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMsg = null;
      });

      _log.info('Fetching current location...');
      Position userLoc = await _getCurrentLocation();
      _log.info('User location acquired: lat=${userLoc.latitude}, lng=${userLoc.longitude}');

      _log.info('Fetching live vehicles from Firebase...');
      final snap = await _dbRef.child('vehicles').get();
      
      if (!snap.exists || snap.value == null) {
        setState(() {
          _errorMsg = 'No active vehicles found on the network.';
          _isLoading = false;
        });
        return;
      }

      final vehicles = snap.value as Map<dynamic, dynamic>;
      
      String? closestPointName;
      double minPointDistance = double.infinity;

      List<Map<String, dynamic>> allLiveBuses = [];

      vehicles.forEach((vehicleNumber, vData) {
        if (vData is! Map) return;

        // 1. Check all boarding points to find the absolute nearest one
        if (vData['boardingPoints'] is Map) {
          final points = vData['boardingPoints'] as Map<dynamic, dynamic>;
          points.forEach((key, pData) {
            if (pData is Map) {
              final lat = double.tryParse(pData['latitude'].toString()) ?? 0;
              final lng = double.tryParse(pData['longitude'].toString()) ?? 0;
              final name = pData['name']?.toString() ?? 'Unnamed';

              if (lat != 0 && lng != 0) {
                double dist = Geolocator.distanceBetween(userLoc.latitude, userLoc.longitude, lat, lng);
                if (dist < minPointDistance) {
                  minPointDistance = dist;
                  closestPointName = name;
                }
              }
            }
          });
        }

        // 2. Check live location of the bus itself
        if (vData['location'] is Map) {
          final loc = vData['location'] as Map;
          final lat = double.tryParse(loc['latitude'].toString());
          final lng = double.tryParse(loc['longitude'].toString());

          if (lat != null && lng != null) {
            double distToBus = Geolocator.distanceBetween(userLoc.latitude, userLoc.longitude, lat, lng);
            Duration eta = calculateETA(distToBus, 30); // 30 km/h avg
            
            allLiveBuses.add({
              'vehicleName': vehicleNumber.toString(),
              'distance': distToBus,
              'eta': eta,
            });
          }
        }
      });

      // Sort live buses by distance/ETA
      allLiveBuses.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));

      // Calculate ETA to the nearest boarding point (walking speed ~ 4 km/h)
      String pointEtaStr = '';
      if (closestPointName != null) {
        Duration walkingEta = calculateETA(minPointDistance, 4);
        pointEtaStr = '${walkingEta.inMinutes} min walk (${(minPointDistance/1000).toStringAsFixed(1)} km)';
      }

      setState(() {
        _nearestBoardingPointName = closestPointName ?? 'No stops available';
        _etaToBoardingPoint = closestPointName != null ? pointEtaStr : '';
        _nearestBuses = allLiveBuses.take(3).toList(); // Show top 3
        _isLoading = false;
      });

    } catch (e, stackTrace) {
      _log.severe('Error loading live vehicle data', e, stackTrace);
      setState(() {
        _errorMsg = 'Could not get location or load data.\nPlease ensure GPS is enabled.';
        _isLoading = false;
      });
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    _log.fine('Checking location service availability...');
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _log.warning('Location services are disabled');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    _log.fine('Current location permission: $permission');
    if (permission == LocationPermission.denied) {
      _log.info('Requesting location permission...');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _log.warning('Location permission denied by user');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _log.severe('Location permissions are permanently denied');
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    _log.fine('Location permission granted, getting current position...');
    return await Geolocator.getCurrentPosition();
  }

  Duration calculateETA(double distance, double speedKmh) {
    double distanceInKm = distance / 1000;
    double timeInHours = distanceInKm / speedKmh;
    return Duration(seconds: (timeInHours * 3600).round());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('Finding nearest buses...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMsg!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadLiveVehicleData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLiveVehicleData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nearest Boarding Point Card
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nearest Boarding Point', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _nearestBoardingPointName ?? 'Unknown',
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (_etaToBoardingPoint != null && _etaToBoardingPoint!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.directions_walk, color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(_etaToBoardingPoint!, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    )
                  ]
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Live Buses Near You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: _loadLiveVehicleData,
                  child: const Text('Refresh', style: TextStyle(color: Colors.deepPurple)),
                )
              ],
            ),
            const SizedBox(height: 12),

            if (_nearestBuses.isEmpty)
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16)
                ),
                child: const Column(
                  children: [
                    Icon(Icons.bus_alert, size: 40, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('No live buses detected nearby.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ..._nearestBuses.map((bus) {
                final vehicleName = bus['vehicleName'] as String;
                final eta = bus['eta'] as Duration;
                final dist = bus['distance'] as double;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // We can wire this to Track map in the future 
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_bus, color: Colors.orange),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(vehicleName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('${(dist/1000).toStringAsFixed(1)} km away', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${eta.inMinutes}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.deepPurple)),
                              const Text('min', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
