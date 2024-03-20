import 'package:flutter/material.dart';
import 'package:vehicle/screen/homescreen.dart';
import 'package:vehicle/screen/signin.dart';

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
        home: SignInPage());
  }
}
