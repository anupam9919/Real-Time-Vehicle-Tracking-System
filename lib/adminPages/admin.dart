import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              title: Text(
                'Admin Dashboard', 
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, letterSpacing: 1.2)
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              elevation: 0,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFF00C9FF)),
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
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient Blobs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C9FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: _isRefreshing
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C9FF)))
                : RefreshIndicator(
                    color: const Color(0xFF00C9FF),
                    backgroundColor: const Color(0xFF1E1E2C),
                    onRefresh: _fetchStats,
                    child: ListView(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0, bottom: 40.0),
                      children: [
                        // Welcome Header
                        Text(
                          'Welcome back,',
                          style: GoogleFonts.outfit(fontSize: 16, color: Colors.white54),
                        ).animate().fade().slideY(begin: -0.2),
                        Text(
                          adminEmail,
                          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ).animate().fade(delay: 100.ms).slideY(begin: -0.2),
                        const SizedBox(height: 32),

                        // Stats Row
                        Row(
                          children: [
                            Expanded(child: _buildStatCard('Vehicles', _totalVehicles.toString(), Icons.directions_bus_rounded, const Color(0xFF00C9FF)).animate().fade(delay: 200.ms).slideX(begin: -0.1)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildStatCard('Drivers', _totalDrivers.toString(), Icons.person_rounded, const Color(0xFF6C63FF)).animate().fade(delay: 300.ms).slideX(begin: 0.1)),
                          ],
                        ),
                        const SizedBox(height: 40),

                        Text(
                          'Management', 
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                        ).animate().fade(delay: 400.ms),
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
                              icon: Icons.directions_bus_rounded,
                              color: const Color(0xFF00C9FF),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageVehiclesPage())),
                            ).animate().fade(delay: 500.ms).scale(begin: const Offset(0.9, 0.9)),
                            _buildActionCard(
                              context,
                              title: 'Manage\nDrivers',
                              icon: Icons.people_rounded,
                              color: const Color(0xFF6C63FF),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageDriversPage())),
                            ).animate().fade(delay: 600.ms).scale(begin: const Offset(0.9, 0.9)),
                            _buildActionCard(
                              context,
                              title: 'Add\nAdmin',
                              icon: Icons.admin_panel_settings_rounded,
                              color: const Color(0xFFFF6B6B),
                              onTap: _showAddAdminDialog,
                            ).animate().fade(delay: 700.ms).scale(begin: const Offset(0.9, 0.9)),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                value, 
                style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)
              ),
              Text(
                title, 
                style: GoogleFonts.outfit(color: Colors.white54, fontWeight: FontWeight.w500, fontSize: 14)
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15), 
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2),
                    ]
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  title, 
                  textAlign: TextAlign.center, 
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.2
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
