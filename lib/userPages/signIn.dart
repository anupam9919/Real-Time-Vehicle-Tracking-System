import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
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
  String _email = '';
  String _password = '';
  String _selectedRole = 'admin'; // Removed 'student' from dropdown
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _log.info('SignInPage initialized');
  }

  /// Student Anonymous Login
  Future<void> _handleStudentLogin() async {
    setState(() => _isLoading = true);
    try {
      // Students don't need a password; they can just log in anonymously
      _log.info('Logging in student anonymously...');
      await FirebaseAuth.instance.signInAnonymously();
      _log.info('Student login successful');
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e, st) {
      _log.severe('Error during anonymous student login', e, st);
      _showError('Student login failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Admin/Driver Email & Password Login
  Future<void> _handleStaffLogin() async {
    if (_email.isEmpty || _password.isEmpty) {
      _showError('Please enter Email and Password');
      return;
    }

    setState(() => _isLoading = true);
    _log.info('Staff login attempt: email=$_email, role=$_selectedRole');

    try {
      // 1. Authenticate with Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );
      
      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception("Authentication failed, no UID.");

      // 2. Verify Role in Realtime Database: /users/<uid>/role
      final snapshot = await FirebaseDatabase.instance.ref().child('users').child(uid).get();
      if (!snapshot.exists) {
        await FirebaseAuth.instance.signOut();
        _showError('User record not found in database.');
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final actualRole = data['role']?.toString() ?? '';

      if (actualRole != _selectedRole) {
        await FirebaseAuth.instance.signOut();
        _showError('Invalid role. You do not have $_selectedRole access.');
        return;
      }

      // 3. Route to Correct Dashboard
      if (_selectedRole == 'admin') {
        _log.info('Admin login successful');
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPage()));
      } else if (_selectedRole == 'driver') {
        // Find assigned vehicle if any
        final assignedVehicle = data['assignedVehicle']?.toString() ?? '';
        final driverName = data['name']?.toString() ?? _email.split('@')[0];

        if (assignedVehicle.isEmpty) {
          _showError('Notice: No vehicle currently assigned to this driver.');
        }

        _log.info('Driver login successful');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DriverHomePage(
                driverId: uid,
                driverName: driverName,
                assignedVehicle: assignedVehicle,
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _log.warning('Auth exception: ${e.message}');
      _showError(e.message ?? 'Authentication failed');
    } catch (e, st) {
      _log.severe('Error during login', e, st);
      _showError('Login error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- STUDENT LOGIN ---
              const Text('Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.directions_bus),
                  label: const Text('Continue as Student (Track Buses)', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _handleStudentLogin,
                ),
              ),

              const SizedBox(height: 40),
              const Divider(thickness: 2),
              const SizedBox(height: 20),

              // --- STAFF LOGIN ---
              const Text('Staff Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                onChanged: (v) {
                  setState(() => _selectedRole = v!);
                  _log.fine('Role changed to: $_selectedRole');
                },
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'driver', child: Text('Driver')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Staff Role',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10.0),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => _email = v.trim(),
              ),
              const SizedBox(height: 10.0),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                onChanged: (v) => _password = v.trim(),
              ),
              const SizedBox(height: 15.0),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleStaffLogin,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Staff Login'),
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
      ),
    );
  }
}

