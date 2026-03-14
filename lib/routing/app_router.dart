import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vehicle/features/auth/domain/entities/app_user.dart';
import 'package:vehicle/features/auth/presentation/providers/auth_providers.dart';
import 'package:vehicle/services/app_logger.dart';
import 'package:vehicle/userPages/sign_in.dart';
import 'package:vehicle/userPages/home_screen.dart';
import 'package:vehicle/adminPages/admin.dart';
import 'package:vehicle/driverPages/driver_home.dart';

final _log = AppLogger.getLogger('AppRouter');

/// Route path constants.
class RoutePaths {
  RoutePaths._();

  static const String signIn = '/sign-in';
  static const String home = '/home';
  static const String admin = '/admin';
  static const String driver = '/driver';
  static const String track = '/track';
}

/// Provides the GoRouter instance via Riverpod.
///
/// This allows the router to reactively rebuild when auth state changes.
final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state so router re-evaluates redirect on login/logout.
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: RoutePaths.signIn,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final isSignIn = state.matchedLocation == RoutePaths.signIn;

      // While auth state is loading, don't redirect.
      if (authState.isLoading) return null;

      final user = authState.value;

      // Not logged in → force to sign-in page
      if (user == null) {
        return isSignIn ? null : RoutePaths.signIn;
      }

      // Logged in but on sign-in page → redirect to role-based home
      if (isSignIn) {
        _log.info('Auth redirect: user ${user.uid} has role "${user.role.name}"');
        switch (user.role) {
          case UserRole.admin:
            return RoutePaths.admin;
          case UserRole.driver:
            return RoutePaths.driver;
          case UserRole.student:
            return RoutePaths.home;
        }
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: RoutePaths.signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RoutePaths.admin,
        builder: (context, state) => const AdminPage(),
      ),
      GoRoute(
        path: RoutePaths.driver,
        builder: (context, state) {
          // Driver needs their info — passed via extra or fetched from auth state
          final extra = state.extra as Map<String, String>?;
          final user = ref.read(authStateProvider).value;
          
          return DriverHomePage(
            driverId: extra?['driverId'] ?? user?.uid ?? '',
            driverName: extra?['driverName'] ?? user?.name ?? '',
            assignedVehicle: extra?['assignedVehicle'] ?? user?.assignedVehicle ?? '',
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
