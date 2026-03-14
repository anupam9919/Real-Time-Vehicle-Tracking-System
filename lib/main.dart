import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/app.dart';
import 'package:vehicle/config/env_config.dart';
import 'package:vehicle/firebase_options.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.init();
  _log.info('App starting...');

  _log.info('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  _log.info('Firebase initialized successfully');

  // Connect to Firebase emulators in local development
  if (EnvConfig.useEmulators) {
    _log.info('Connecting to Firebase emulators...');
    await FirebaseAuth.instance.useAuthEmulator(
      EnvConfig.emulatorHost,
      EnvConfig.authEmulatorPort,
    );
    FirebaseDatabase.instance.useDatabaseEmulator(
      EnvConfig.emulatorHost,
      EnvConfig.databaseEmulatorPort,
    );
    _log.info('Connected to Firebase emulators');
  }

  _log.info('Launching VehicleApp');
  runApp(const VehicleApp());
}
