import 'package:flutter/material.dart';

class VehiclePage extends StatefulWidget {
  final String vehicleNumber;
  final String driverName;
  final String driverMobileNumber;

  const VehiclePage({super.key, 
    required this.vehicleNumber,
    required this.driverName,
    required this.driverMobileNumber,
  });

  @override
  _VehiclePageState createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Number: ${widget.vehicleNumber}',
              style: const TextStyle(fontSize: 18.0),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Driver Name: ${widget.driverName}',
              style: const TextStyle(fontSize: 18.0),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Driver Mobile Number: ${widget.driverMobileNumber}',
              style: const TextStyle(fontSize: 18.0),
            ),
          ],
        ),
      ),
    );
  }
}
