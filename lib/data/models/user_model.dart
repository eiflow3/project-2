/// UserModel represents the master administrative account of the offline app.
/// It contains secure credentials metadata, matching our SQLite table structure.
class UserModel {
  final int? id;
  final String username;
  final String authType; // Either 'PASSWORD' or 'PIN'
  final String? passwordHash; // Hashed password, null if using PIN
  final String? pinHash;      // Hashed PIN, null if using password
  final String createdAt;

  UserModel({
    this.id,
    required this.username,
    required this.authType,
    this.passwordHash,
    this.pinHash,
    required this.createdAt,
  });

  /// Factory method to convert a raw SQLite database map query row into a typed UserModel instance.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      authType: map['auth_type'] as String,
      passwordHash: map['password_hash'] as String?,
      pinHash: map['pin_hash'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  /// Converts the UserModel object instance back into a Map representation
  /// so that it can be cleanly written or updated in our local SQLite tables.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'auth_type': authType,
      'password_hash': passwordHash,
      'pin_hash': pinHash,
      'created_at': createdAt,
    };
  }
}
