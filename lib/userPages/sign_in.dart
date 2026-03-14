import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vehicle/core/errors/exceptions.dart';
import 'package:vehicle/features/auth/domain/entities/app_user.dart';
import 'package:vehicle/features/auth/presentation/providers/auth_providers.dart';
import 'package:vehicle/routing/app_router.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('SignInPage');

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
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
      await ref.read(signInAnonymouslyProvider).call();
      _log.info('Student login successful');

      if (mounted) context.go(RoutePaths.home);
    } catch (e, st) {
      _log.severe('Error during anonymous student login', e, st);
      _showError('Student login failed: ${_friendlyError(e)}');
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
      final user = await ref.read(signInWithEmailProvider).call(
        email: _email,
        password: _password,
      );

      _log.info('Login successful: ${user.role}');

      if (!mounted) return;

      // Route based on role
      switch (user.role) {
        case UserRole.admin:
          context.go(RoutePaths.admin);
        case UserRole.driver:
          if (user.assignedVehicle?.isEmpty ?? true) {
            _showError('Notice: No vehicle currently assigned to this driver.');
          }
          context.go(RoutePaths.driver, extra: {
            'driverId': user.uid,
            'driverName': user.name,
            'assignedVehicle': user.assignedVehicle ?? '',
          });
        case UserRole.student:
          await ref.read(signOutProvider).call();
          _showError('Unknown role. Contact your administrator.');
      }
    } on AppException catch (e) {
      _log.warning('Auth error: ${e.message}');
      _showError(e.message);
    } catch (e, st) {
      _log.severe('Error during login', e, st);
      _showError('Login error: ${_friendlyError(e)}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// First-time admin setup (long-press AppBar title)
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
              backgroundColor: const Color(0xFF1E1E2C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('First Admin Setup', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Create the first super admin account.\nThis only works if no admin exists yet.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogField(nameController, 'Name', Icons.person),
                    const SizedBox(height: 12),
                    _buildDialogField(emailController, 'Email', Icons.email, isEmail: true),
                    const SizedBox(height: 12),
                    _buildDialogField(passwordController, 'Password (min 6)', Icons.lock, isPassword: true),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isCreating ? null : () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isCreating
                      ? null
                      : () async {
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();
                          final name = nameController.text.trim();

                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(dialogContext);

                          if (email.isEmpty || password.isEmpty || name.isEmpty) {
                             messenger.showSnackBar(const SnackBar(content: Text('All fields are required')));
                            return;
                          }

                          setDialogState(() => isCreating = true);

                          try {
                            await ref.read(createFirstAdminProvider).call(
                              email: email,
                              password: password,
                              name: name,
                            );

                            _log.info('First admin created');
                            navigator.pop();
                            messenger.showSnackBar(SnackBar(content: Text('Admin "$name" created! You can now log in.')));
                          } on AppException catch (e) {
                            setDialogState(() => isCreating = false);
                            messenger.showSnackBar(SnackBar(content: Text(e.message)));
                          } catch (e, st) {
                            _log.severe('Error creating first admin', e, st);
                            setDialogState(() => isCreating = false);
                            messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        },
                  child: isCreating
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Create Admin', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _friendlyError(dynamic e) {
    if (e is AppException) return e.message;
    final s = e.toString();
    if (s.contains('user-not-found')) return 'No account found with this email.';
    if (s.contains('wrong-password')) return 'Incorrect password.';
    if (s.contains('network-request-failed')) return 'No internet connection.';
    return s;
  }

  Widget _buildDialogField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: GoogleFonts.outfit()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsive glassmorphism
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A), // Deep dark premium background
      body: Stack(
        children: [
          // ── BACKGROUND DECORATIONS ──
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ).animate().fade(duration: 1000.ms).scale(begin: const Offset(0.8, 0.8)),
          
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C9FF).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ).animate().fade(duration: 1200.ms).scale(begin: const Offset(0.8, 0.8)),

          // ── MAIN CONTENT ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO & TITLE
                    GestureDetector(
                      onLongPress: _handleFirstAdminSetup, // Hidden admin setup
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: const Icon(
                          Icons.directions_bus_filled_rounded,
                          size: 64,
                          color: Color(0xFF00C9FF),
                        ),
                      ).animate().fade(duration: 600.ms).slideY(begin: -0.2, end: 0),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ).animate().fade(delay: 200.ms, duration: 600.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Login to track or manage your fleet',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ).animate().fade(delay: 300.ms, duration: 600.ms),
                    const SizedBox(height: 40),

                    // GLASSMORPHISM CONTAINER FOR FORM
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          width: size.width > 500 ? 500 : double.infinity,
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.white.withValues(alpha: 0.02),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // --- STUDENT LOGIN ---
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00C9FF).withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 5),
                                    )
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleStudentLogin,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    backgroundColor: const Color(0xFF00C9FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.location_on_rounded),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Track Buses as Student',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),
                              
                              // --- DIVIDER ---
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      'Staff Portal',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
                                ],
                              ),
                              
                              const SizedBox(height: 32),

                              // --- STAFF LOGIN ---
                              _buildTextField(
                                'Email Address',
                                Icons.email_outlined,
                                onChanged: (v) => _email = v.trim(),
                                isEmail: true,
                              ),
                              const SizedBox(height: 16.0),
                              _buildTextField(
                                'Password',
                                Icons.lock_outline_rounded,
                                onChanged: (v) => _password = v.trim(),
                                isPassword: true,
                                obscure: _obscurePassword,
                                onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              const SizedBox(height: 24.0),
                              
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleStaffLogin,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        'Sign In to Dashboard',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 500.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        _log.fine('Forgot password tapped');
                      },
                      child: Text(
                        'Forgot password?',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ).animate().fade(delay: 700.ms).slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon, {
    required Function(String) onChanged,
    bool isPassword = false,
    bool isEmail = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return TextFormField(
      onChanged: onChanged,
      obscureText: isPassword && obscure,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: GoogleFonts.outfit(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.5)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
        ),
      ),
    );
  }
}
