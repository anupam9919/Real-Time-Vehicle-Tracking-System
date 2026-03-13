import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/adminPages/add_vehicle.dart';
import 'package:vehicle/adminPages/manage_boarding.dart';

class ManageVehiclesPage extends StatefulWidget {
  const ManageVehiclesPage({super.key});

  @override
  State<ManageVehiclesPage> createState() => _ManageVehiclesPageState();
}

class _ManageVehiclesPageState extends State<ManageVehiclesPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  Map<String, String> _vehicleToDriver = {};

  @override
  void initState() {
    super.initState();
    _listenToDrivers();
  }

  void _listenToDrivers() {
    _dbRef.child('drivers').onValue.listen((event) {
      if (event.snapshot.value != null && mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final newMap = <String, String>{};
        
        data.forEach((uid, driverData) {
          if (driverData is Map) {
            final vehicle = driverData['assignedVehicle']?.toString();
            final name = driverData['name']?.toString() ?? 'Unknown';
            if (vehicle != null && vehicle.isNotEmpty) {
              newMap[vehicle] = name;
            }
          }
        });

        setState(() {
          _vehicleToDriver = newMap;
        });
      }
    });
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Never';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Vehicles'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.child('vehicles').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(
              child: Text('No vehicles found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
            );
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final vehicles = data.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicleNumber = vehicles[index].key.toString();
              final vData = vehicles[index].value as Map<dynamic, dynamic>;

              final driverName = _vehicleToDriver[vehicleNumber] ?? 'Unassigned';
              int boardingPointsCount = 0;
              if (vData['boardingPoints'] != null && vData['boardingPoints'] is Map) {
                boardingPointsCount = (vData['boardingPoints'] as Map).length;
              }
              final locationTime = vData['location']?['timestamp']?.toString();

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withValues(alpha: 0.2),
                    child: const Icon(Icons.directions_bus, color: Colors.blue),
                  ),
                  title: Text(vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Driver: $driverName', style: const TextStyle(fontWeight: FontWeight.w500)),
                      Text('Boarding Points: $boardingPointsCount'),
                      Text('Last Location: ${_formatTime(locationTime)}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                  trailing: ElevatedButton.icon(
                    icon: const Icon(Icons.pin_drop, size: 18),
                    label: const Text('Boarding'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ManageBoardingPage(vehicleNumber: vehicleNumber)),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehiclePage())),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
    );
  }
}
