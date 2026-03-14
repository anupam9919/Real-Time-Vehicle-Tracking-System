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
  Timer? _timer;
  
  List<String> _availableVehicles = [];
  String? _selectedVehicle;
  
  List<Map<dynamic, dynamic>> _liveBoardingPoints = [];
  List<double> _distances = [];
  List<Duration> _etas = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _log.info('TrackingPage initialized');
    _loadAvailableVehicles();
  }

  @override
  void dispose() {
    _log.info('TrackingPage disposed, cancelling timer');
    _timer?.cancel();
    super.dispose();
  }

  void _loadAvailableVehicles() {
    _dbRef.child('vehicles').onValue.listen((event) {
      if (!mounted) return;
      if (event.snapshot.value == null) {
        setState(() => _isLoading = false);
        return;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      final vehicles = data.keys.map((e) => e.toString()).toList();
      
      setState(() {
        _availableVehicles = vehicles;
        _isLoading = false;
        
        // Auto-select the first vehicle if none selected currently
        if (_selectedVehicle == null && _availableVehicles.isNotEmpty) {
          _selectVehicle(_availableVehicles.first);
        } else if (!_availableVehicles.contains(_selectedVehicle)) {
          // If selected vehicle was deleted
          _selectedVehicle = null;
          _liveBoardingPoints = [];
          _distances = [];
          _etas = [];
          _timer?.cancel();
        }
      });
    });
  }

  void _selectVehicle(String vehicleName) {
    setState(() {
      _selectedVehicle = vehicleName;
      _liveBoardingPoints = [];
      _distances = [];
      _etas = [];
    });
    _timer?.cancel();
    
    // Load boarding points for this specific vehicle
    _dbRef.child('vehicles').child(vehicleName).child('boardingPoints').get().then((snap) {
      if (snap.exists && snap.value != null && mounted) {
        _log.info('Raw boardingPoints data for $vehicleName: ${snap.value}');
        
        dynamic data = snap.value;
        List<Map<dynamic, dynamic>> parsedPoints = [];
        
        // Helper to recursively find valid boarding points (must have a 'name' and 'latitude')
        void extractPoints(dynamic input) {
          if (input == null) return;
          if (input is List) {
            for (var item in input) {
              extractPoints(item);
            }
          } else if (input is Map) {
            if (input.containsKey('name') && input.containsKey('latitude')) {
              parsedPoints.add(Map<dynamic, dynamic>.from(input));
            } else {
              for (var value in input.values) {
                extractPoints(value);
              }
            }
          }
        }
        
        extractPoints(data);

        setState(() {
          _liveBoardingPoints = parsedPoints;
        });
        _log.info('Parsed boarding points count: ${_liveBoardingPoints.length}');
        
        // Start tracking location for this vehicle
        _startTimer();
        _fetchVehicleLocation(); // Initial fetch
      }
    });
  }

  void _startTimer() {
    _log.info('Starting location fetch timer for $_selectedVehicle');
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchVehicleLocation();
    });
  }

  Future<void> _fetchVehicleLocation() async {
    if (_selectedVehicle == null) return;

    try {
      final snapshot = await _dbRef.child('vehicles').child(_selectedVehicle!).child('location').get();
      _log.info('Fetched live location for $_selectedVehicle: ${snapshot.value}');

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final lat = double.tryParse(data['latitude'].toString());
        final lng = double.tryParse(data['longitude'].toString());
        
        _log.info('Parsed Live Lat: $lat, Lng: $lng');

        if (lat != null && lng != null && mounted) {
          setState(() {
            _distances = _calculateDistances(lat, lng);
            _etas = _calculateETAs(_distances);
          });
          _log.info('Distances and ETAs calculated successfully: ${_etas.length} ETAs');
        } else {
          _log.warning('Could not parse latitude or longitude cleanly from Firebase data.');
        }
      } else {
        _log.warning('No live location exists for $_selectedVehicle in Firebase right now.');
      }
    } catch (e) {
      _log.warning('Error fetching location for $_selectedVehicle', e);
    }
  }

  List<double> _calculateDistances(double lat, double lng) {
    List<double> distances = [];
    for (var point in _liveBoardingPoints) {
      final pLat = double.tryParse(point['latitude'].toString()) ?? 0;
      final pLng = double.tryParse(point['longitude'].toString()) ?? 0;
      if (pLat != 0 && pLng != 0) {
        distances.add(Geolocator.distanceBetween(lat, lng, pLat, pLng));
      } else {
        distances.add(0);
      }
    }
    return distances;
  }

  List<Duration> _calculateETAs(List<double> distances) {
    double busSpeedInKmPerHour = 30; // Configurable average speed
    return distances.map((distance) {
      double distanceInKm = distance / 1000;
      double timeInHours = distanceInKm / busSpeedInKmPerHour;
      return Duration(seconds: (timeInHours * 3600).round());
    }).toList();
  }

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
