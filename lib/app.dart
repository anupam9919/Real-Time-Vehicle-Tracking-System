import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vehicle/core/theme/app_theme.dart';
import 'package:vehicle/routing/app_router.dart';

/// Root application widget.
///
/// Wraps the app in [ProviderScope] for Riverpod state management
/// and uses [routerProvider] for declarative, reactive routing.
class VehicleApp extends StatelessWidget {
  const VehicleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: const _AppContent(),
    );
  }
}

/// Inner widget that can access Riverpod providers.
class _AppContent extends ConsumerWidget {
  const _AppContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Vehicle Tracking System',
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
