import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vehicle/adminPages/admin.dart';
import 'package:vehicle/driverPages/driverHome.dart';
import 'package:vehicle/services/app_logger.dart';
import 'package:vehicle/userPages/homeScreen.dart';

final _log = AppLogger.getLogger('SignInPage');

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  String _userId = '';
  String _password = '';
  String _selectedRole = 'student';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _log.info('SignInPage initialized');
  }

  Future<void> _handleLogin() async {
    if (_userId.isEmpty || _password.isEmpty) {
      _showError('Please enter ID and Password');
      return;
    }

    setState(() => _isLoading = true);
    _log.info('Login attempt: userId=$_userId, role=$_selectedRole');

    try {
      if (_selectedRole == 'driver') {
        await _loginDriver();
      } else {
        _loginLocalUser();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Student/Admin auth — checked against .env credentials (existing behavior)
  void _loginLocalUser() {
    final users = [
      {'id': dotenv.env['STUDENT_ID']!, 'password': dotenv.env['STUDENT_PASSWORD']!, 'role': 'student'},
      {'id': dotenv.env['ADMIN_ID']!, 'password': dotenv.env['ADMIN_PASSWORD']!, 'role': 'admin'},
    ];

    final user = users.firstWhere(
      (u) => u['id'] == _userId && u['password'] == _password && u['role'] == _selectedRole,
      orElse: () => {'id': '', 'password': '', 'role': ''},
    );

    if (user['role'] == 'student') {
      _log.info('Login successful: student');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (user['role'] == 'admin') {
      _log.info('Login successful: admin');
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPage()));
    } else {
      _log.warning('Login failed for userId=$_userId, role=$_selectedRole');
      _showError('Invalid ID or Password');
    }
  }

  /// Driver auth — checked against Firebase `drivers/{id}` node
  Future<void> _loginDriver() async {
    _log.info('Checking driver credentials in Firebase...');
    try {
      final snapshot = await FirebaseDatabase.instance.ref().child('drivers').child(_userId).get();

      if (!snapshot.exists) {
        _log.warning('Driver not found: $_userId');
        _showError('Driver not found');
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final storedPassword = data['password']?.toString() ?? '';

      if (storedPassword != _password) {
        _log.warning('Wrong password for driver: $_userId');
        _showError('Invalid password');
        return;
      }

      final driverName = data['name']?.toString() ?? _userId;
      final assignedVehicle = data['assignedVehicle']?.toString() ?? '';

      if (assignedVehicle.isEmpty) {
        _showError('No vehicle assigned to this driver');
        return;
      }

      _log.info('Driver login successful: $_userId, vehicle=$assignedVehicle');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DriverHomePage(
              driverId: _userId,
              driverName: driverName,
              assignedVehicle: assignedVehicle,
            ),
          ),
        );
      }
    } catch (e, st) {
      _log.severe('Error during driver login', e, st);
      _showError('Login error: $e');
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedRole,
              onChanged: (v) {
                setState(() => _selectedRole = v!);
                _log.fine('Role changed to: $_selectedRole');
              },
              items: const [
                DropdownMenuItem(value: 'student', child: Text('User')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'driver', child: Text('Driver')),
              ],
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10.0),
            TextField(
              decoration: const InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => _userId = v.trim(),
            ),
            const SizedBox(height: 10.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              obscureText: _obscurePassword,
              onChanged: (v) => _password = v.trim(),
            ),
            const SizedBox(height: 10.0),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 20.0),
            TextButton(
              onPressed: () {
                _log.fine('Forgot password tapped');
              },
              child: const Text('Forgot password?', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      ),
    );
  }
}
