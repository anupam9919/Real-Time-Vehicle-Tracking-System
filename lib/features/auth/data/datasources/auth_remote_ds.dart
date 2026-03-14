import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:vehicle/core/constants/firebase_paths.dart';
import 'package:vehicle/core/errors/exceptions.dart';
import 'package:vehicle/features/auth/data/models/user_model.dart';
import 'package:vehicle/features/auth/domain/entities/app_user.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('AuthRemoteDataSource');

/// Remote data source that encapsulates all Firebase Auth + RTDB calls
/// for authentication.
///
/// Throws [AppException] subclasses on failure — never raw Firebase errors.
class AuthRemoteDataSource {
  final FirebaseAuth _auth;
  final DatabaseReference _dbRef;

  AuthRemoteDataSource({
    FirebaseAuth? auth,
    DatabaseReference? dbRef,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _dbRef = dbRef ?? FirebaseDatabase.instance.ref();

  /// Sign in anonymously, returns an anonymous [UserModel].
  Future<UserModel> signInAnonymously() async {
    try {
      _log.info('Signing in anonymously...');
      final credential = await _auth.signInAnonymously();
      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthException('Anonymous sign-in returned no UID');
      }
      _log.info('Anonymous sign-in successful: $uid');
      return UserModel.anonymous(uid);
    } on FirebaseAuthException catch (e) {
      _log.warning('Anonymous sign-in failed: ${e.message}');
      throw AuthException(e.message ?? 'Anonymous sign-in failed', e);
    }
  }

  /// Sign in with email/password and fetch user role from RTDB.
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      _log.info('Signing in with email: $email');
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthException('Sign-in returned no UID');
      }

      // Fetch user profile from RTDB
      final snapshot = await _dbRef.child(FirebasePaths.userProfile(uid)).get();
      if (!snapshot.exists) {
        _log.warning('User $uid has no RTDB record, signing out');
        await _auth.signOut();
        throw const NotFoundException('User record not found in database');
      }

      final data = _toStringMap(snapshot.value);
      if (data == null) {
        throw const ParseException('User data is not a valid map');
      }

      _log.info('User $uid signed in with role: ${data['role']}');
      return UserModel.fromFirebase(uid: uid, data: data);
    } on AppException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      _log.warning('Email sign-in failed: ${e.message}');
      throw AuthException(e.message ?? 'Authentication failed', e);
    } catch (e) {
      _log.severe('Unexpected sign-in error: $e');
      throw ServerException('Sign-in failed: $e', e);
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    _log.info('Signing out user: ${_auth.currentUser?.uid}');
    await _auth.signOut();
  }

  /// Get current Firebase Auth user as a stream.
  Stream<User?> get firebaseAuthStateChanges => _auth.authStateChanges();

  /// Get the current Firebase user's UID.
  String? get currentUid => _auth.currentUser?.uid;

  /// Fetch user profile from RTDB for a given UID.
  Future<UserModel?> fetchUserProfile(String uid) async {
    try {
      final snapshot = await _dbRef.child(FirebasePaths.userProfile(uid)).get();
      if (!snapshot.exists) return null;

      final data = _toStringMap(snapshot.value);
      if (data == null) return null;

      return UserModel.fromFirebase(uid: uid, data: data);
    } catch (e) {
      _log.warning('Error fetching user profile for $uid: $e');
      return null;
    }
  }

  /// Create the first admin account.
  Future<UserModel> createFirstAdmin({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _log.info('Creating first admin account: $email');

      // Check if any admin already exists
      final usersSnap = await _dbRef.child(FirebasePaths.users).get();
      if (usersSnap.exists && usersSnap.value != null) {
        final users = _toStringMap(usersSnap.value);
        if (users != null) {
          final hasAdmin = users.values.any((u) {
            if (u is Map) return u['role'] == 'admin';
            return false;
          });
          if (hasAdmin) {
            throw const PermissionException(
              'An admin already exists. Ask them to add you.',
            );
          }
        }
      }

      // Create Firebase Auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // Write admin profile to RTDB
      final model = UserModel(
        uid: uid,
        email: email,
        name: name,
        role: UserRole.admin,
      );
      await _dbRef
          .child(FirebasePaths.userProfile(uid))
          .set(model.toFirebaseMap());

      _log.info('First admin created: $uid');

      // Sign out so the admin can sign in normally
      await _auth.signOut();
      return model;
    } on AppException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(e.message ?? 'Failed to create admin', e);
    } catch (e) {
      throw ServerException('Failed to create admin: $e', e);
    }
  }

  /// Safely converts Firebase snapshot value to a string-keyed map.
  static Map<String, dynamic>? _toStringMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }
}
