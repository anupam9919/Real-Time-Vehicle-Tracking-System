import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vehicle/features/auth/presentation/providers/auth_providers.dart';
import 'package:vehicle/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:vehicle/routing/app_router.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('AccountPage');

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final vehicles = ref.watch(availableVehiclesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 80.0, bottom: 20.0),
          child: authState.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00C9FF))),
            error: (e, _) => Center(
              child: Text('Error loading profile', style: GoogleFonts.outfit(color: Colors.white54)),
            ),
            data: (user) {
              final isAnonymous = user?.isAnonymous ?? true;
              final displayName = isAnonymous ? 'Student' : (user?.name ?? 'User');
              final email = isAnonymous ? 'Anonymous Sign-In' : (user?.email ?? '');

              return ListView(
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: Icon(
                            isAnonymous ? Icons.school_rounded : Icons.person_rounded,
                            size: 48,
                            color: const Color(0xFF00C9FF),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          displayName,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                        if (user?.role != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user!.role.name.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6C63FF),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Available Buses
                  _buildSectionCard(
                    title: 'Available Routes',
                    icon: Icons.directions_bus_rounded,
                    child: vehicles.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C9FF))),
                      ),
                      error: (_, __) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Could not load routes', style: GoogleFonts.outfit(color: Colors.white54)),
                      ),
                      data: (vehicleList) => vehicleList.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('No vehicles available', style: GoogleFonts.outfit(color: Colors.white54)),
                            )
                          : Column(
                              children: vehicleList.map((v) => ListTile(
                                leading: const Icon(Icons.directions_bus_rounded, color: Color(0xFF00C9FF), size: 20),
                                title: Text(v, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600)),
                                dense: true,
                              )).toList(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logout
                  _buildSectionCard(
                    title: 'Sign Out',
                    icon: Icons.logout_rounded,
                    iconColor: const Color(0xFFFF6B6B),
                    onTap: () async {
                      _log.info('User logging out from AccountPage');
                      await ref.read(signOutProvider).call();
                      if (context.mounted) context.go(RoutePaths.signIn);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    Color iconColor = const Color(0xFF00C9FF),
    Widget? child,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (onTap != null) ...[
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3)),
                  ],
                ],
              ),
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }
}
