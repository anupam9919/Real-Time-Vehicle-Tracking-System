import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vehicle/features/auth/data/datasources/auth_remote_ds.dart';
import 'package:vehicle/features/auth/data/repositories/auth_repo_impl.dart';
import 'package:vehicle/features/auth/domain/entities/app_user.dart';
import 'package:vehicle/features/auth/domain/repositories/auth_repository.dart';
import 'package:vehicle/features/auth/domain/usecases/auth_usecases.dart';

// ── Data layer providers ──

/// Provides the [AuthRemoteDataSource] singleton.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

/// Provides the [AuthRepository] implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

// ── Use case providers ──

final signInAnonymouslyProvider = Provider<SignInAnonymouslyUseCase>((ref) {
  return SignInAnonymouslyUseCase(ref.watch(authRepositoryProvider));
});

final signInWithEmailProvider = Provider<SignInWithEmailUseCase>((ref) {
  return SignInWithEmailUseCase(ref.watch(authRepositoryProvider));
});

final signOutProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final createFirstAdminProvider = Provider<CreateFirstAdminUseCase>((ref) {
  return CreateFirstAdminUseCase(ref.watch(authRepositoryProvider));
});

// ── Auth state provider ──

/// Reactive auth state — emits [AppUser?] whenever auth state changes.
///
/// Screens can watch this to determine if the user is signed in
/// and what role they have for routing decisions.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Convenience provider to get the current user synchronously.
/// Returns null if not yet loaded or not signed in.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).value;
});
