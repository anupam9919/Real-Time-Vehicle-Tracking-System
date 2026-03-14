import 'dart:async';
import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
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
        void checkPoints(dynamic input) {
          if (input == null) return;
          if (input is List) {
            for (var item in input) { checkPoints(item); }
          } else if (input is Map) {
            if (input.containsKey('name') && input.containsKey('latitude')) {
              final lat = double.tryParse(input['latitude'].toString()) ?? 0;
              final lng = double.tryParse(input['longitude'].toString()) ?? 0;
              final name = input['name']?.toString() ?? 'Unnamed';

              if (lat != 0 && lng != 0) {
                double dist = Geolocator.distanceBetween(userLoc.latitude, userLoc.longitude, lat, lng);
                if (dist < minPointDistance) {
                  minPointDistance = dist;
                  closestPointName = name;
                }
              }
            } else {
              for (var value in input.values) { checkPoints(value); }
            }
          }
        }
        
        checkPoints(vData['boardingPoints']);

        // 2. Check live location of the bus itself
        if (vData['location'] is Map) {
          final loc = vData['location'] as Map;
          final lat = double.tryParse(loc['latitude'].toString());
          final lng = double.tryParse(loc['longitude'].toString());

          if (lat != null && lng != null) {
            double distToBus = Geolocator.distanceBetween(userLoc.latitude, userLoc.longitude, lat, lng);
            
            // Use live speed from driver GPS if available, fallback to 25 km/h
            double speedMs = double.tryParse(loc['speed']?.toString() ?? '') ?? 0;
            double speedKmh = (speedMs > 1.0) ? (speedMs * 3.6) : 25.0;
            speedKmh = speedKmh.clamp(5.0, 120.0);
            Duration eta = calculateETA(distToBus, speedKmh);
            
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00C9FF)),
            const SizedBox(height: 16),
            Text('Finding nearest buses...', style: GoogleFonts.outfit(color: Colors.white70)),
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
              const Icon(Icons.location_off_rounded, size: 64, color: Colors.white54),
              const SizedBox(height: 16),
              Text(
                _errorMsg!, 
                textAlign: TextAlign.center, 
                style: GoogleFonts.outfit(fontSize: 16, color: Colors.white70)
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loadLiveVehicleData,
                icon: const Icon(Icons.refresh_rounded),
                label: Text('Retry', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLiveVehicleData,
      color: const Color(0xFF00C9FF),
      backgroundColor: const Color(0xFF1E1E2C),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 100.0, bottom: 40.0), // Padding to clear the transparent AppBar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nearest Boarding Point Glassmorphism Card
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearest Boarding Point', 
                        style: GoogleFonts.outfit(color: const Color(0xFF00C9FF), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C9FF).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.place_rounded, color: Color(0xFF00C9FF), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _nearestBoardingPointName ?? 'Unknown',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      if (_etaToBoardingPoint != null && _etaToBoardingPoint!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.directions_walk_rounded, color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text(_etaToBoardingPoint!, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              ),
            ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 40),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Live Buses Near You', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                TextButton.icon(
                  onPressed: _loadLiveVehicleData,
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF6C63FF)),
                  label: Text('Refresh', style: GoogleFonts.outfit(color: const Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                )
              ],
            ).animate().fade(delay: 200.ms),
            const SizedBox(height: 16),

            if (_nearestBuses.isEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.bus_alert_rounded, size: 48, color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No live buses detected nearby.', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ).animate().fade(delay: 300.ms)
            else
              ...List.generate(_nearestBuses.length, (index) {
                final bus = _nearestBuses[index];
                final vehicleName = bus['vehicleName'] as String;
                final eta = bus['eta'] as Duration;
                final dist = bus['distance'] as double;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          // We can wire this to Track map in the future 
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.directions_bus_rounded, color: Color(0xFF6C63FF)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vehicleName, 
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${(dist/1000).toStringAsFixed(1)} km away', 
                                      style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${eta.inMinutes}', 
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 24, color: const Color(0xFF00C9FF))
                                    ),
                                    Text('min', style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fade(delay: (300 + (100 * index)).ms).slideX(begin: 0.1, end: 0),
                );
              }),
          ],
        ),
      ),
    );
  }
}
