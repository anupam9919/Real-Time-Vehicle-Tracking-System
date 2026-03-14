/// Typed exceptions for the data layer.
///
/// These are thrown by data sources and caught by repositories,
/// which convert them into [Failure] objects for the presentation layer.
/// Base class for all app-level exceptions.
abstract class AppException implements Exception {
  final String message;
  final dynamic originalError;

  const AppException(this.message, [this.originalError]);

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when a Firebase operation fails.
class ServerException extends AppException {
  const ServerException(super.message, [super.originalError]);
}

/// Thrown when a requested resource is not found.
class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.originalError]);
}

/// Thrown when the user is not authenticated.
class AuthException extends AppException {
  const AuthException(super.message, [super.originalError]);
}

/// Thrown when the user lacks permission for an operation.
class PermissionException extends AppException {
  const PermissionException(super.message, [super.originalError]);
}

/// Thrown when data parsing/serialization fails.
class ParseException extends AppException {
  const ParseException(super.message, [super.originalError]);
}
