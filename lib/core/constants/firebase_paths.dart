/// Centralized Firebase Realtime Database path constants.
///
/// Prevents typo bugs from hardcoded strings scattered across the codebase.
/// All Firebase path references should use these constants.
class FirebasePaths {
  FirebasePaths._();

  // ── Root Collections ──
  static const String vehicles = 'vehicles';
  static const String users = 'users';
  static const String drivers = 'drivers';
  static const String boardingPoints = 'boardingPoints';

  // ── Vehicle Sub-paths ──
  static String vehicleLocation(String vehicleId) => '$vehicles/$vehicleId/location';
  static String vehicleBoardingPoints(String vehicleId) => '$vehicles/$vehicleId/boardingPoints';

  // ── User Sub-paths ──
  static String userRole(String uid) => '$users/$uid/role';
  static String userProfile(String uid) => '$users/$uid';

  // ── Driver Sub-paths ──
  static String driverProfile(String driverId) => '$drivers/$driverId';
}
