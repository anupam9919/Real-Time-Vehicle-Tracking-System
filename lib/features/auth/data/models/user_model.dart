import 'package:vehicle/features/auth/domain/entities/app_user.dart';

/// Data-layer model that maps between Firebase data and [AppUser] entity.
///
/// Handles serialization/deserialization for Firebase RTDB.
class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.role,
    super.assignedVehicle,
    super.isAnonymous,
  });

  /// Creates a [UserModel] from Firebase RTDB snapshot data.
  ///
  /// [uid] comes from FirebaseAuth, [data] from RTDB `/users/{uid}`.
  factory UserModel.fromFirebase({
    required String uid,
    required Map<String, dynamic> data,
  }) {
    return UserModel(
      uid: uid,
      email: data['email']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      role: UserRole.fromString(data['role']?.toString()),
      assignedVehicle: data['assignedVehicle']?.toString(),
    );
  }

  /// Creates a [UserModel] for an anonymous student user.
  factory UserModel.anonymous(String uid) {
    return UserModel(
      uid: uid,
      email: '',
      name: 'Student',
      role: UserRole.student,
      isAnonymous: true,
    );
  }

  /// Converts to a map for writing to Firebase RTDB.
  Map<String, dynamic> toFirebaseMap() {
    return {
      'email': email,
      'name': name,
      'role': role.name,
      if (assignedVehicle != null) 'assignedVehicle': assignedVehicle,
    };
  }

  /// Converts a domain [AppUser] to a [UserModel].
  factory UserModel.fromEntity(AppUser user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      name: user.name,
      role: user.role,
      assignedVehicle: user.assignedVehicle,
      isAnonymous: user.isAnonymous,
    );
  }
}
