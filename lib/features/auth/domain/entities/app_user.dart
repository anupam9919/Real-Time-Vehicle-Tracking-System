/// Domain entity representing an authenticated user.
///
/// This is the clean domain representation — no Firebase dependencies.
/// The presentation layer works exclusively with this entity.
class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? assignedVehicle;
  final bool isAnonymous;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.assignedVehicle,
    this.isAnonymous = false,
  });

  /// Factory for anonymous student users.
  factory AppUser.anonymous(String uid) => AppUser(
        uid: uid,
        email: '',
        name: 'Student',
        role: UserRole.student,
        isAnonymous: true,
      );

  @override
  String toString() => 'AppUser(uid: $uid, role: $role, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}

/// User roles in the system.
enum UserRole {
  student,
  driver,
  admin;

  /// Parse a role string from Firebase RTDB.
  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'driver':
        return UserRole.driver;
      default:
        return UserRole.student;
    }
  }
}
