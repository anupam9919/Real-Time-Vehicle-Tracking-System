// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class Maps extends StatefulWidget {
//    Maps({super.key});

//   @override
//   State<Maps> createState() => _MapsState();
//   Completer<GoogleMapController> _controller = Completer();
// }

// class _MapsState extends State<Maps> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView( 
//         child: Column(
//           children: [
//             Container(
//               height: 300,
//               child: GoogleMap(
//                 mapType: MapType.normal,
//                 initialCameraPosition: const CameraPosition(
//                   target: LatLng(37.42796133580664, -122.085749655962),
//                   zoom: 14.4746,
//                 ),
//                 onMapCreated: (GoogleMapController controller) {
//                   widget._controller.complete(controller);
//                 },
//               ),
//             ),
//             const SizedBox(
//               height: 20,
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 final GoogleMapController controller = await widget._controller.future;
//                 controller.animateCamera(
//                   CameraUpdate.newCameraPosition(
//                     const CameraPosition(
//                       target: LatLng(37.42796133580664, -122.085749655962),
//                       zoom: 16,
//                     ),
//                   ),
//                 );
//               },
//               child: const Text('Go to Googleplex'),
//             ),
//           ],
//         ),
//       )
//     );
//   } 
// }