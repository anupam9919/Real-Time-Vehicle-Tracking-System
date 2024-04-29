// import 'package:flutter/material.dart';
// import 'package:vehicle/adminPages/admin.dart';

// class AddVehiclePage extends StatefulWidget {
//   const AddVehiclePage({Key? key, required this.controller}) : super(key: key);

//   final AdminPageController controller;

//   @override
//   _AddVehiclePageState createState() => _AddVehiclePageState();
// }

// class _AddVehiclePageState extends State<AddVehiclePage> {
//   final _formKey = GlobalKey<FormState>();
//   String _vehicleNumber = '';
//   String _driverName = '';
//   String _driverMobileNumber = '';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Add Vehicle'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               TextFormField(
//                 decoration: InputDecoration(
//                   labelText: 'Vehicle Number',
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a vehicle number';
//                   }
//                   return null;
//                 },
//                 onChanged: (value) {
//                   setState(() {
//                     _vehicleNumber = value;
//                   });
//                 },
//               ),
//               TextFormField(
//                 decoration: InputDecoration(
//                   labelText: 'Driver Name',
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a driver name';
//                   }
//                   return null;
//                 },
//                 onChanged: (value) {
//                   setState(() {
//                     _driverName = value;
//                   });
//                 },
//               ),
//               TextFormField(
//                 decoration: InputDecoration(
//                   labelText: 'Driver Mobile Number',
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a driver mobile number';
//                   }
//                   return null;
//                 },
//                 onChanged: (value) {
//                   setState(() {
//                     _driverMobileNumber = value;
//                   });
//                 },
//               ),
//               SizedBox(height: 16.0),
//               ElevatedButton(
//                 onPressed: () {
//                   if (_formKey.currentState!.validate()) {
//                     _addVehicle();
//                     Navigator.pop(context);
//                   }
//                 },
//                 child: Text('Add Vehicle'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _addVehicle() {
//     widget.controller
//         .addVehicle(_vehicleNumber, _driverName, _driverMobileNumber);
//     Navigator.pop(context);
//   }
// }
