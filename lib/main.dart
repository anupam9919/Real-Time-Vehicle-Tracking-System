import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/firebase_options.dart';
import 'package:vehicle/userPages/homeScreen.dart';
import 'package:vehicle/userPages/signIn.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VehicleApp());
}

class VehicleApp extends StatelessWidget {
  const VehicleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Vehicle App',
        theme: ThemeData(
          primarySwatch: Colors.purple,
        ),
        // home: const HomeScreen());
        // home: Maps());
        home: const HomeScreen());
  }
}
