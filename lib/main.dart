import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vehicle/firebase_options.dart';
import 'package:vehicle/services/app_logger.dart';
import 'package:vehicle/userPages/signIn.dart';

final _log = AppLogger.getLogger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init();
  _log.info('App starting...');

  _log.info('Loading environment variables...');
  await dotenv.load(fileName: ".env");
  _log.info('Environment variables loaded successfully');

  _log.info('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _log.info('Firebase initialized successfully');

  _log.info('Launching VehicleApp');
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
      home: const SignInPage()
    );
  }
}
