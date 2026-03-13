import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/adminPages/add_boarding.dart';

class ManageBoardingPage extends StatefulWidget {
  final String vehicleNumber;
  const ManageBoardingPage({super.key, required this.vehicleNumber});

  @override
  State<ManageBoardingPage> createState() => _ManageBoardingPageState();
}

class _ManageBoardingPageState extends State<ManageBoardingPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  String _getTypeString(Map point) {
    if (point['isStart'] == true) return 'Start';
    if (point['isEnd'] == true) return 'End';
    return 'Intermediate';
  }

  void _deletePoint(String pointId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Boarding Point?'),
        content: const Text('Are you sure you want to remove this point from the route?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete')
          ),
        ],
      )
    );

    if (confirm == true && mounted) {
      try {
        await _dbRef.child('vehicles').child(widget.vehicleNumber).child('boardingPoints').child(pointId).remove();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Boarding point deleted')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route: ${widget.vehicleNumber}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef.child('vehicles').child(widget.vehicleNumber).child('boardingPoints').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(
              child: Text('No boarding points found.\nTap + to add one.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          final data = snapshot.data!.snapshot.value;
          if (data is! Map) {
            return const Center(child: Text('Invalid data format'));
          }
          
          final points = data.entries.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: points.length,
            itemBuilder: (context, index) {
              final pointId = points[index].key.toString();
              final pData = points[index].value as Map<dynamic, dynamic>;

              final name = pData['name']?.toString() ?? 'Unnamed Point';
              final lat = pData['latitude']?.toString() ?? '0.0';
              final lng = pData['longitude']?.toString() ?? '0.0';
              final typeStr = _getTypeString(pData);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withValues(alpha: 0.2),
                    child: const Icon(Icons.place, color: Colors.teal),
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Lat: $lat, Lng: $lng', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeStr == 'Start' ? Colors.green.withValues(alpha: 0.1) : (typeStr == 'End' ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          typeStr,
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            color: typeStr == 'Start' ? Colors.green[800] : (typeStr == 'End' ? Colors.red[800] : Colors.blue[800])
                          )
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deletePoint(pointId),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddBoardingPointPage(vehicleNumber: widget.vehicleNumber))),
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add_location),
        label: const Text('Add Point'),
      ),
    );
  }
}
