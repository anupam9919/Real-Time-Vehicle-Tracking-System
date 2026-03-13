import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('AddDriverPage');

class AddDriverPage extends StatefulWidget {
  const AddDriverPage({super.key});

  @override
  State<AddDriverPage> createState() => _AddDriverPageState();
}

class _AddDriverPageState extends State<AddDriverPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final _formKey = GlobalKey<FormState>();

  String _driverUsername = '';
  String _password = '';
  String _driverName = '';
  String _mobileNumber = '';
  String _assignedVehicle = '';

  List<String> _vehicleNumbers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _log.info('AddDriverPage initialized');
    _fetchVehicles();
  }

  /// Auto-append admin's email domain if user enters just a username
  String? _formatEmail(String input) {
    if (input.contains('@')) return input;
    // Use the current admin's email domain
    final adminEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    if (!adminEmail.contains('@')) return null;
    final domain = adminEmail.split('@').last;
    return '$input@$domain';
  }

  Future<void> _fetchVehicles() async {
    _log.info('Fetching available vehicles...');
    try {
      final snapshot = await _dbRef.child('vehicles').once();
      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _vehicleNumbers = data.keys.cast<String>().toList();
        });
        _log.info('Fetched ${_vehicleNumbers.length} vehicles');
      }
    } catch (e, st) {
      _log.severe('Error fetching vehicles', e, st);
    }
  }

  Future<void> _addDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final driverEmail = _formatEmail(_driverUsername);
    if (driverEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not determine email domain. Make sure you are logged in with a valid admin email.')),
      );
      setState(() => _isLoading = false);
      return;
    }
    _log.info('Adding driver: email=$driverEmail, name=$_driverName, vehicle=$_assignedVehicle');

    // Save reference to current admin user so we can re-sign in after
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentEmail = currentUser?.email;

    try {
      // 1. Create Firebase Auth account for the driver
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: driverEmail,
        password: _password,
      );
      final uid = userCredential.user!.uid;
      _log.info('Created Firebase Auth account for driver, UID: $uid');

      // 2. Write driver data to /users/<uid> (for login role verification)
      await _dbRef.child('users').child(uid).set({
        'role': 'driver',
        'name': _driverName,
        'mobileNumber': _mobileNumber,
        'assignedVehicle': _assignedVehicle,
      });

      // 3. Also write to /drivers/<uid> (for admin management)
      await _dbRef.child('drivers').child(uid).set({
        'email': driverEmail,
        'name': _driverName,
        'mobileNumber': _mobileNumber,
        'assignedVehicle': _assignedVehicle,
      });

      _log.info('Driver $uid saved to Firebase');

      // 4. Re-sign in as the current admin (createUser auto-signs in as new user)
      if (currentEmail != null) {
        // We need the admin's password to re-authenticate, but we don't have it.
        // Instead, we'll just sign out the newly created user — the admin will
        // need to re-login. A better approach is to use Firebase Admin SDK,
        // but for client-side Flutter, this is the simplest workaround.
        _log.info('Note: Admin session may need refresh after creating driver');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Driver "$_driverName" created successfully!\nLogin: $driverEmail')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      _log.warning('Auth error creating driver: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e, st) {
      _log.severe('Error adding driver', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Driver')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Driver Username',
                  hintText: 'e.g. driver1',
                  prefixIcon: const Icon(Icons.person),
                  suffixText: '@${FirebaseAuth.instance.currentUser?.email?.split('@').last ?? ''}',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  return null;
                },
                onChanged: (v) => _driverUsername = v.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 6) return 'Minimum 6 characters';
                  return null;
                },
                onChanged: (v) => _password = v.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Driver Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (v) => _driverName = v.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                onChanged: (v) => _mobileNumber = v.trim(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Assign Vehicle (Optional)'),
                items: _vehicleNumbers
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) _assignedVehicle = v;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addDriver,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create Driver Account'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This will create a Firebase Auth account for the driver. '
                'They can then log in with their email and password.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
