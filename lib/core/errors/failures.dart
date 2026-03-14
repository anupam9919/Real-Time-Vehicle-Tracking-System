/// Typed failures for the domain/presentation layer.
///
/// Failures are returned (not thrown) from repositories to the presentation
/// layer. They are the domain-level representation of what went wrong.
/// Base class for all failures.
abstract class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Failure && runtimeType == other.runtimeType && message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// A server/network operation failed.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// The requested resource was not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// The user is not authenticated.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// The user lacks permission.
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// Location services failed.
class LocationFailure extends Failure {
  const LocationFailure(super.message);
}
