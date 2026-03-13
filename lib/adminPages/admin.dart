import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/adminPages/manage_drivers.dart';
import 'package:vehicle/adminPages/manage_vehicles.dart';
import 'package:vehicle/services/app_logger.dart';
import 'package:vehicle/userPages/sign_in.dart';

final _log = AppLogger.getLogger('AdminPage');

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  int _totalVehicles = 0;
  int _totalDrivers = 0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _log.info('AdminPage initialized');
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    _log.info('Fetching dashboard stats...');
    setState(() => _isRefreshing = true);
    
    try {
      int vCount = 0;
      int dCount = 0;

      // Fetch vehicles
      final vSnap = await _dbRef.child('vehicles').get();
      if (vSnap.exists && vSnap.value != null) {
        vCount = (vSnap.value as Map).length;
      }

      // Fetch drivers
      final dSnap = await _dbRef.child('users').get();
      if (dSnap.exists && dSnap.value != null) {
        final users = dSnap.value as Map<dynamic, dynamic>;
        dCount = users.values.where((u) => u is Map && u['role'] == 'driver').length;
      }

      setState(() {
        _totalVehicles = vCount;
        _totalDrivers = dCount;
      });
      _log.info('Stats loaded: Vehicles=$vCount, Drivers=$dCount');
    } catch (e, st) {
      _log.severe('Error fetching stats', e, st);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  /// Show dialog to create a new admin account
  void _showAddAdminDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    bool isCreating = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Admin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Admin Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'e.g. newadmin@school.com',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password (min 6 chars)',
                        prefixIcon: Icon(Icons.lock),
                      ),
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

                          if (email.isEmpty || password.isEmpty || name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All fields are required')),
                            );
                            return;
                          }
                          if (password.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password must be at least 6 characters')),
                            );
                            return;
                          }

                          setDialogState(() => isCreating = true);

                          try {
                            _log.info('Creating new admin: $email');

                            // 1. Create Firebase Auth account
                            final cred = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                              email: email,
                              password: password,
                            );
                            final uid = cred.user!.uid;

                            // 2. Write admin role to /users/<uid>
                            await FirebaseDatabase.instance
                                .ref()
                                .child('users')
                                .child(uid)
                                .set({
                              'role': 'admin',
                              'name': name,
                              'email': email,
                            });

                            _log.info('Admin account created: $uid');

                            // 3. Note: createUser auto-signs in as new user.
                            //    The current admin will be signed out.
                            //    They'll need to re-login.
                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Admin "$name" created!\n'
                                  'Email: $email\n'
                                  'Note: You will be signed out. Please log back in.',
                                ),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                            // Sign out and go to login (since we're now signed in as new admin)
                            await FirebaseAuth.instance.signOut();
                            if (!context.mounted) return;
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const SignInPage()),
                              (route) => false,
                            );
                          } on FirebaseAuthException catch (e) {
                            _log.warning('Error creating admin: ${e.message}');
                            setDialogState(() => isCreating = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: ${e.message}')),
                            );
                          } catch (e, st) {
                            _log.severe('Error creating admin', e, st);
                            setDialogState(() => isCreating = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                  child: isCreating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Admin'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminEmail = FirebaseAuth.instance.currentUser?.email ?? 'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              _log.info('Admin logging out');
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SignInPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isRefreshing
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchStats,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Welcome Header
                    Text(
                      'Welcome,',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    Text(
                      adminEmail,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // Stats Row
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Vehicles', _totalVehicles.toString(), Icons.directions_bus, Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildStatCard('Drivers', _totalDrivers.toString(), Icons.person, Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    const Text('Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Services Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildActionCard(
                          context,
                          title: 'Manage\nVehicles',
                          icon: Icons.directions_bus,
                          color: Colors.blue,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageVehiclesPage())),
                        ),
                        _buildActionCard(
                          context,
                          title: 'Manage\nDrivers',
                          icon: Icons.people,
                          color: Colors.orange,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageDriversPage())),
                        ),
                        _buildActionCard(
                          context,
                          title: 'Add\nAdmin',
                          icon: Icons.admin_panel_settings,
                          color: Colors.deepPurple,
                          onTap: _showAddAdminDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
