import 'package:flutter/material.dart';
import 'package:vehicle/screen/homepage.dart';
import 'package:vehicle/screen/sign_in.dart';
// Import the correct home screen file

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
        // home: HomePage(),
        home: SignInPage());
  }
}
