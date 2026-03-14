import 'package:vehicle/features/auth/domain/entities/app_user.dart';

/// Abstract repository interface for authentication operations.
///
/// Defines the contract between the domain/presentation layer
/// and the data layer. Implementations can be swapped for testing.
abstract class AuthRepository {
  /// Sign in anonymously as a student.
  Future<AppUser> signInAnonymously();

  /// Sign in with email and password (admin/driver).
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Sign out the current user.
  Future<void> signOut();

  /// Get the currently authenticated user, or null if not signed in.
  AppUser? get currentUser;

  /// Stream of auth state changes.
  Stream<AppUser?> get authStateChanges;

  /// Create a new admin user (first-time setup only).
  Future<AppUser> createFirstAdmin({
    required String email,
    required String password,
    required String name,
  });
}
