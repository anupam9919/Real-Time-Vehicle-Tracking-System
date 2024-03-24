// import 'package:flutter/material.dart';
// import 'package:vehicle/screen/accountpage.dart';
// import 'package:vehicle/screen/helpsupport.dart';
// import 'package:vehicle/screen/searchpage.dart';
// import 'package:vehicle/screen/track.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   int _selectedIndex = 0;
//   late PageController _pageController;

//   @override
//   void initState() {
//     super.initState();
//     _pageController = PageController(initialPage: _selectedIndex);
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//       _pageController.animateToPage(
//         index,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.ease,
//       );
//     });
//   }

//   void _openSearchPage() {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => SearchPage(),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Vehicle Tracking App'),
//       ),
//       body: PageView(
//         controller: _pageController,
//         onPageChanged: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//         children: const [
//           SizedBox(
//             height: 300, // Set the desired height
//             child: BusStopScreen(),
//           ),
//           TrackingPage(),
//           AccountPage(),
//           HelpPage(),
//         ],
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         type: BottomNavigationBarType.fixed,
//         items: const <BottomNavigationBarItem>[
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.track_changes),
//             label: 'Track',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.account_circle),
//             label: 'Account',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.help),
//             label: 'Help',
//           ),
//         ],
//         currentIndex: _selectedIndex,
//         selectedItemColor: Theme.of(context).primaryColor,
//         onTap: _onItemTapped,
//       ),
//       floatingActionButton: _selectedIndex == 0
//           ? FloatingActionButton(
//               onPressed: _openSearchPage,
//               child: const Icon(Icons.search),
//             )
//           : null, // Only show FAB if "Home" is selected
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//     );
//   }
// }

// class BusStopScreen extends StatefulWidget {
//   const BusStopScreen({Key? key}) : super(key: key);

//   @override
//   _BusStopScreenState createState() => _BusStopScreenState();
// }

// class _BusStopScreenState extends State<BusStopScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.5),
//             spreadRadius: 2,
//             blurRadius: 5,
//             offset: Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Scaffold(
//         appBar: AppBar(
//           title: Text('Nearest Bus Stop'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 // Handle "See All" button press
//               },
//               child: Text(
//                 'See All',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         body: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.bus_alert, color: Colors.grey),
//                   SizedBox(width: 8),
//                   Text(
//                     'Ada Mode',
//                     style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(width: 8),
//                   Text(
//                     '3 min',
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 16),
//               Text(
//                 'Next Buses',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 8),
//               _buildBusInfo(
//                 'PE-5',
//                 'To New Shantipuram',
//                 '10:05 AM',
//               ),
//               SizedBox(height: 8),
//               _buildBusInfo(
//                 'PE-5',
//                 'To Jahangirbad',
//                 '10:51 AM',
//               ),
//               SizedBox(height: 16),
//               Center(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // Handle "See all buses" button press
//                   },
//                   child: Text('See all buses'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBusInfo(String busNumber, String destination, String time) {
//     return Row(
//       children: [
//         Icon(Icons.bus_alert, color: Colors.grey),
//         SizedBox(width: 8),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               busNumber,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             Text(
//               destination,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey,
//               ),
//             ),
//           ],
//         ),
//         Spacer(),
//         Text(
//           time,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ],
//     );
//   }
// }
