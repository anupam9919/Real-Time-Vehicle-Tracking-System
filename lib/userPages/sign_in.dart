import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/adminPages/admin.dart';
import 'package:vehicle/driverPages/driver_home.dart';
import 'package:vehicle/services/app_logger.dart';
import 'package:vehicle/userPages/home_screen.dart';

final _log = AppLogger.getLogger('SignInPage');

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  String _email = '';
  String _password = '';
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

  /// Admin/Driver Email & Password Login — auto-detects role from database
  Future<void> _handleStaffLogin() async {
    if (_email.isEmpty || _password.isEmpty) {
      _showError('Please enter Email and Password');
      return;
    }

    setState(() => _isLoading = true);
    _log.info('Staff login attempt: email=$_email');

    try {
      // 1. Authenticate with Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email,
        password: _password,
      );
      
      final uid = userCredential.user?.uid;
      if (uid == null) throw Exception("Authentication failed, no UID.");

      // 2. Fetch role from Realtime Database: /users/<uid>/role
      final snapshot = await FirebaseDatabase.instance.ref().child('users').child(uid).get();
      if (!snapshot.exists) {
        await FirebaseAuth.instance.signOut();
        _showError('User record not found in database.');
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      final role = data['role']?.toString() ?? '';

      // 3. Route based on role from database
      if (role == 'admin') {
        _log.info('Admin login successful');
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminPage()));
      } else if (role == 'driver') {
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
      } else {
        await FirebaseAuth.instance.signOut();
        _showError('Unknown role: "$role". Contact your administrator.');
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

  /// First-time admin setup (long-press AppBar title)
  /// Only works when no admin users exist in the database.
  void _handleFirstAdminSetup() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('First Admin Setup'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Create the first super admin account.\n'
                      'This only works if no admin exists yet.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password (min 6)', prefixIcon: Icon(Icons.lock)),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();
                          final name = nameController.text.trim();
                          
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(dialogContext);

                          if (email.isEmpty || password.isEmpty || name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All fields are required')),
                            );
                            return;
                          }

                          setDialogState(() => isCreating = true);

                          try {
                            // Check if any admin already exists
                            final usersSnap = await FirebaseDatabase.instance.ref().child('users').get();
                            if (usersSnap.exists && usersSnap.value != null) {
                              final users = usersSnap.value as Map<dynamic, dynamic>;
                              final hasAdmin = users.values.any((u) {
                                if (u is Map) return u['role'] == 'admin';
                                return false;
                              });
                              if (hasAdmin) {
                                setDialogState(() => isCreating = false);
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('An admin already exists. Ask them to add you.')),
                                );
                                return;
                              }
                            }

                            // Create the first admin
                            final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            final uid = cred.user!.uid;

                            await FirebaseDatabase.instance.ref().child('users').child(uid).set({
                              'role': 'admin',
                              'name': name,
                              'email': email,
                            });

                            _log.info('First admin created: $uid');

                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(content: Text('Admin "$name" created! You can now log in.')),
                            );
                            // Sign out so they login properly
                            await FirebaseAuth.instance.signOut();
                          } catch (e, st) {
                            _log.severe('Error creating first admin', e, st);
                            setDialogState(() => isCreating = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                  child: isCreating
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create Admin'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onLongPress: _handleFirstAdminSetup,
          child: const Text('Sign In'),
        ),
      ),
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
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'e.g. admin@school.com',
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
      ),
    );
  }
}
