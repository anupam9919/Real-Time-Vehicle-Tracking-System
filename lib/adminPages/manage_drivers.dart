import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/adminPages/add_driver.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('ManageDriversPage');

class ManageDriversPage extends StatefulWidget {
  const ManageDriversPage({super.key});

  @override
  State<ManageDriversPage> createState() => _ManageDriversPageState();
}

class _ManageDriversPageState extends State<ManageDriversPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  List<String> _vehicles = [];

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    try {
      final snap = await _dbRef.child('vehicles').get();
      if (snap.exists && snap.value != null) {
        final data = snap.value as Map<dynamic, dynamic>;
        setState(() {
          _vehicles = data.keys.cast<String>().toList();
        });
      }
    } catch (e) {
      _log.warning('Failed to fetch vehicles', e);
    }
  }

  void _showEditDialog(String uid, Map driverData) {
    String selectedVehicle = driverData['assignedVehicle']?.toString() ?? '';
    if (selectedVehicle.isEmpty && _vehicles.isNotEmpty) {
      selectedVehicle = _vehicles.first; // fallback if invalid
    } else if (!_vehicles.contains(selectedVehicle)) {
      _vehicles.add(selectedVehicle); // ensure it's in the list
    }

    showDialog(
      context: context,
      builder: (ctx) {
        String newVehicle = selectedVehicle;
        bool isUpdating = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit ${driverData['name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${driverData['email']}'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Assign Vehicle'),
                    initialValue: newVehicle.isEmpty ? null : newVehicle,
                    items: [
                      const DropdownMenuItem(value: '', child: Text('None')),
                      ..._vehicles.map((v) => DropdownMenuItem(value: v, child: Text(v))),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => newVehicle = v);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isUpdating ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isUpdating
                      ? null
                      : () async {
                          setState(() => isUpdating = true);
                          try {
                            // Update both locations
                            await _dbRef.child('drivers').child(uid).update({'assignedVehicle': newVehicle});
                            await _dbRef.child('users').child(uid).update({'assignedVehicle': newVehicle});
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle updated')));
                          } catch (e) {
                            setState(() => isUpdating = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                  child: isUpdating ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Drivers'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.child('drivers').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text('No drivers found.', style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final drivers = data.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final uid = drivers[index].key.toString();
              final driverData = drivers[index].value as Map<dynamic, dynamic>;

              final name = driverData['name']?.toString() ?? 'Unknown';
              final email = driverData['email']?.toString() ?? 'No Email';
              final mobile = driverData['mobileNumber']?.toString() ?? 'No phone';
              final vehicle = driverData['assignedVehicle']?.toString() ?? '';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    child: const Icon(Icons.person, color: Colors.orange),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(email),
                      Text(mobile),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: vehicle.isNotEmpty ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          vehicle.isNotEmpty ? 'Vehicle: $vehicle' : 'No Vehicle Assigned',
                          style: TextStyle(color: vehicle.isNotEmpty ? Colors.blue[800] : Colors.red[800], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDialog(uid, driverData),
                    tooltip: 'Edit Assignment',
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDriverPage())),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add),
        label: const Text('Add Driver'),
      ),
    );
  }
}
