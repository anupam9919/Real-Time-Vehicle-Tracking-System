import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('TrackingPage');

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  List<String> _availableVehicles = [];
  String? _selectedVehicle;

  List<Map<String, dynamic>> _liveBoardingPoints = [];
  List<double> _distances = [];
  List<Duration> _etas = [];

  bool _isLoading = true;

  StreamSubscription? _vehiclesSub;
  StreamSubscription? _locationSub;
  StreamSubscription? _boardingPointsSub;

  @override
  void initState() {
    super.initState();
    _log.info('TrackingPage initialized');
    _loadAvailableVehicles();
  }

  @override
  void dispose() {
    _log.info('TrackingPage disposed, cancelling subscriptions');
    _vehiclesSub?.cancel();
    _locationSub?.cancel();
    _boardingPointsSub?.cancel();
    super.dispose();
  }

  // ── Safe helpers to convert Firebase data without hard `as` casts ──

  /// Safely converts any Firebase value to a string-keyed Map.
  /// Returns null if conversion is not possible.
  static Map<String, dynamic>? _toStringMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  /// Safely parses a number from any Firebase value (handles int, double, String).
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return double.tryParse(value.toString());
  }

  /// Recursively extracts boarding point maps from any shape of Firebase data.
  /// A valid boarding point must contain both 'name' and 'latitude' keys.
  static List<Map<String, dynamic>> _extractBoardingPoints(dynamic input) {
    List<Map<String, dynamic>> results = [];
    if (input == null) return results;

    if (input is List) {
      for (var item in input) {
        results.addAll(_extractBoardingPoints(item));
      }
    } else if (input is Map) {
      // Convert all keys to strings for safe access
      final map = input.map((k, v) => MapEntry(k.toString(), v));
      if (map.containsKey('name') && map.containsKey('latitude')) {
        results.add(map);
      } else {
        for (var value in map.values) {
          results.addAll(_extractBoardingPoints(value));
        }
      }
    }
    return results;
  }

  // ── Data loading ──

  void _loadAvailableVehicles() {
    _vehiclesSub = _dbRef.child('vehicles').onValue.listen((event) {
      if (!mounted) return;
      final raw = event.snapshot.value;
      if (raw == null) {
        setState(() => _isLoading = false);
        return;
      }

      final map = _toStringMap(raw);
      if (map == null) {
        _log.warning('vehicles node is not a Map: ${raw.runtimeType}');
        setState(() => _isLoading = false);
        return;
      }

      final vehicles = map.keys.toList();
      _log.info('Loaded ${vehicles.length} vehicles: $vehicles');

      setState(() {
        _availableVehicles = vehicles;
        _isLoading = false;

        if (_selectedVehicle == null && _availableVehicles.isNotEmpty) {
          _selectVehicle(_availableVehicles.first);
        } else if (!_availableVehicles.contains(_selectedVehicle)) {
          _selectedVehicle = null;
          _liveBoardingPoints = [];
          _distances = [];
          _etas = [];
        }
      });
    }, onError: (e) {
      _log.severe('Error listening to vehicles', e);
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _selectVehicle(String vehicleName) {
    _log.info('Selected vehicle: $vehicleName');
    setState(() {
      _selectedVehicle = vehicleName;
      _liveBoardingPoints = [];
      _distances = [];
      _etas = [];
    });

    // Cancel previous subscriptions
    _locationSub?.cancel();
    _boardingPointsSub?.cancel();

    // Listen to boarding points in real-time
    _boardingPointsSub = _dbRef
        .child('vehicles')
        .child(vehicleName)
        .child('boardingPoints')
        .onValue
        .listen((event) {
      if (!mounted) return;
      final raw = event.snapshot.value;
      _log.info('Boarding points raw data type: ${raw.runtimeType}');
      _log.info('Boarding points raw data: $raw');

      final points = _extractBoardingPoints(raw);
      _log.info('Extracted ${points.length} boarding points');
      for (var p in points) {
        _log.info('  → ${p['name']} (lat: ${p['latitude']}, lng: ${p['longitude']})');
      }

      setState(() {
        _liveBoardingPoints = points;
      });
    }, onError: (e) {
      _log.severe('Error listening to boarding points for $vehicleName', e);
    });

    // Listen to live location in real-time (instead of polling with Timer)
    _locationSub = _dbRef
        .child('vehicles')
        .child(vehicleName)
        .child('location')
        .onValue
        .listen((event) {
      if (!mounted) return;
      final raw = event.snapshot.value;
      _log.info('Location raw data type: ${raw.runtimeType}');
      _log.info('Location raw data: $raw');

      if (raw == null) {
        _log.warning('No location data available for $vehicleName');
        return;
      }

      final locMap = _toStringMap(raw);
      if (locMap == null) {
        _log.warning('Location data is not a Map: ${raw.runtimeType} = $raw');
        return;
      }

      final lat = _toDouble(locMap['latitude']);
      final lng = _toDouble(locMap['longitude']);
      _log.info('Parsed location: lat=$lat, lng=$lng');

      if (lat != null && lng != null && mounted) {
        setState(() {
          _distances = _calculateDistances(lat, lng);
          _etas = _calculateETAs(_distances);
        });
        _log.info('Calculated ${_etas.length} ETAs successfully');
      } else {
        _log.warning('Failed to parse lat/lng from location data');
      }
    }, onError: (e) {
      _log.severe('Error listening to location for $vehicleName', e);
    });
  }

  // ── Calculation helpers ──

  List<double> _calculateDistances(double lat, double lng) {
    List<double> distances = [];
    for (var point in _liveBoardingPoints) {
      final pLat = _toDouble(point['latitude']) ?? 0.0;
      final pLng = _toDouble(point['longitude']) ?? 0.0;
      if (pLat != 0.0 && pLng != 0.0) {
        distances.add(
          Geolocator.distanceBetween(lat, lng, pLat, pLng).toDouble(),
        );
      } else {
        distances.add(0.0);
      }
    }
    return distances;
  }

  List<Duration> _calculateETAs(List<double> distances) {
    const double busSpeedKmh = 30.0;
    return distances.map((d) {
      double km = d / 1000.0;
      double hours = km / busSpeedKmh;
      return Duration(seconds: (hours * 3600.0).round());
    }).toList();
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Vehicle Selector Dropdown
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.directions_bus, color: Colors.deepPurple),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedVehicle,
                          hint: const Text('Select a Route / Vehicle'),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                          items: _availableVehicles.map((String vehicle) {
                            return DropdownMenuItem<String>(
                              value: vehicle,
                              child: Text(vehicle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              _selectVehicle(newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Route Timeline
            Expanded(
              child: _selectedVehicle == null
                  ? const Center(child: Text('Please select a vehicle to track', style: TextStyle(color: Colors.grey)))
                  : _liveBoardingPoints.isEmpty
                      ? const Center(child: Text('This vehicle has no boarding points configured.', style: TextStyle(color: Colors.grey)))
                      : Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ListView.builder(
                              itemCount: _liveBoardingPoints.length,
                              itemBuilder: (context, index) {
                                final point = _liveBoardingPoints[index];
                                final name = point['name']?.toString() ?? 'Unnamed Stop';
                                final eta = _etas.length > index ? _etas[index] : null;

                                return TimelineTile(
                                  alignment: TimelineAlign.manual,
                                  lineXY: 0.1,
                                  isFirst: index == 0,
                                  isLast: index == _liveBoardingPoints.length - 1,
                                  indicatorStyle: IndicatorStyle(
                                    width: 16,
                                    color: eta != null && eta.inMinutes <= 1 ? Colors.green : Colors.deepPurple,
                                    padding: const EdgeInsets.all(2),
                                    iconStyle: IconStyle(iconData: Icons.circle, color: Colors.white, fontSize: 10),
                                  ),
                                  beforeLineStyle: const LineStyle(color: Colors.deepPurple, thickness: 2),
                                  endChild: Container(
                                    padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 16.0, bottom: 16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: eta == null ? Colors.grey.shade200 : (eta.inMinutes <= 1 ? Colors.green.shade100 : Colors.blue.shade50),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            eta == null
                                                ? "Locating..."
                                                : eta.inMinutes <= 0 ? "Arriving" : "${eta.inMinutes} min",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: eta == null ? Colors.grey.shade600 : (eta.inMinutes <= 1 ? Colors.green.shade800 : Colors.blue.shade800),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
