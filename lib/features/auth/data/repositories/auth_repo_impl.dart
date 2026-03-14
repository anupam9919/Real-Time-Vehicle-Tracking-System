import 'dart:async';

import 'package:vehicle/features/auth/data/datasources/auth_remote_ds.dart';
import 'package:vehicle/features/auth/domain/entities/app_user.dart';
import 'package:vehicle/features/auth/domain/repositories/auth_repository.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('AuthRepositoryImpl');

/// Concrete implementation of [AuthRepository].
///
/// Delegates to [AuthRemoteDataSource] for all Firebase operations.
/// Converts data-layer models to domain entities.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  /// Cached current user — avoids re-fetching on every access.
  AppUser? _cachedUser;

  AuthRepositoryImpl({required AuthRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<AppUser> signInAnonymously() async {
    _log.info('Repository: signInAnonymously');
    final userModel = await _remoteDataSource.signInAnonymously();
    _cachedUser = userModel;
    return userModel;
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _log.info('Repository: signInWithEmailPassword($email)');
    final userModel = await _remoteDataSource.signInWithEmailPassword(
      email: email,
      password: password,
    );
    _cachedUser = userModel;
    return userModel;
  }

  @override
  Future<void> signOut() async {
    _log.info('Repository: signOut');
    await _remoteDataSource.signOut();
    _cachedUser = null;
  }

  @override
  AppUser? get currentUser => _cachedUser;

  @override
  Stream<AppUser?> get authStateChanges {
    return _remoteDataSource.firebaseAuthStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _cachedUser = null;
        return null;
      }

      if (firebaseUser.isAnonymous) {
        final user = AppUser.anonymous(firebaseUser.uid);
        _cachedUser = user;
        return user;
      }

      // Fetch full profile from RTDB
      final profile = await _remoteDataSource.fetchUserProfile(firebaseUser.uid);
      _cachedUser = profile;
      return profile;
    });
  }

  @override
  Future<AppUser> createFirstAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    _log.info('Repository: createFirstAdmin($email)');
    final userModel = await _remoteDataSource.createFirstAdmin(
      email: email,
      password: password,
      name: name,
    );
    // Don't cache — admin needs to sign in after creation
    return userModel;
  }
}
