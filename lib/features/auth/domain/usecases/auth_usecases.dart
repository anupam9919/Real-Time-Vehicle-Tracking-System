import 'package:vehicle/features/auth/domain/entities/app_user.dart';
import 'package:vehicle/features/auth/domain/repositories/auth_repository.dart';

/// Use case: Sign in a student anonymously.
class SignInAnonymouslyUseCase {
  final AuthRepository _repository;

  const SignInAnonymouslyUseCase(this._repository);

  Future<AppUser> call() => _repository.signInAnonymously();
}

/// Use case: Sign in staff (admin/driver) with email and password.
class SignInWithEmailUseCase {
  final AuthRepository _repository;

  const SignInWithEmailUseCase(this._repository);

  Future<AppUser> call({
    required String email,
    required String password,
  }) =>
      _repository.signInWithEmailPassword(email: email, password: password);
}

/// Use case: Sign out the current user.
class SignOutUseCase {
  final AuthRepository _repository;

  const SignOutUseCase(this._repository);

  Future<void> call() => _repository.signOut();
}

/// Use case: Create the first admin account (one-time setup).
class CreateFirstAdminUseCase {
  final AuthRepository _repository;

  const CreateFirstAdminUseCase(this._repository);

  Future<AppUser> call({
    required String email,
    required String password,
    required String name,
  }) =>
      _repository.createFirstAdmin(
        email: email,
        password: password,
        name: name,
      );
}
