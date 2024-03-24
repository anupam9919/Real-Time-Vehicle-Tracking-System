import 'package:flutter/material.dart';
import 'package:vehicle/pages/gmaps.dart';
import 'package:vehicle/pages/homescreen.dart';

// import 'package:vehicle/screen/signin.dart';
// import 'package:vehicle/screen/temp.dart';

void main() {
  runApp(VehicleApp());
}

class VehicleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Vehicle App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        // home: HomeScreen());
        home: Maps());
    // home: SignInPage());
  }
}
