import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/firebase_options.dart';
import 'package:vehicle/pages/homescreen.dart';


// import 'package:vehicle/screen/signin.dart';
// import 'package:vehicle/screen/temp.dart';

// void main() {
//   runApp(VehicleApp());
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
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
        home: HomeScreen());
    // home: Maps());
    // home: SignInPage());
  }
}
