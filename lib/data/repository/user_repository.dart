import 'package:sqflite/sqflite.dart';
import '../database/database_service.dart';
import '../models/user_model.dart';

/// UserRepository performs data access operations for credentials and authentication.
class UserRepository {
  final DatabaseService _dbService = DatabaseService();

  /// Checks if any administrative user has already completed the first-time setup phase.
  /// If this returns 0, the application automatically redirects to the Admin Wizard setup screen.
  Future<bool> hasRegisteredAdmin() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> result = await db.query('users');
    
    // We check if there's any user other than the system-injected default 'admin'
    // or if the administrator has modified the default credentials.
    // If there are registered users who are configured properly, return true.
    if (result.isEmpty) return false;
    
    // If the only user has username 'admin' and the pin matches our default "1234",
    // we can consider that they still need the setup phase to establish their personalized master account.
    if (result.length == 1 && result.first['username'] == 'admin' && result.first['pin_hash'] == '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918') {
      return false;
    }
    return true;
  }

  /// Sets up or overwrites the master account credentials during the first-time initialization wizard.
  Future<bool> registerMasterAccount(UserModel user) async {
    final db = await _dbService.database;
    try {
      // Clear all existing system accounts (like our default temporary admin)
      await db.delete('users');
      
      // Insert the custom master account
      final int id = await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return id > 0;
    } catch (_) {
      return false;
    }
  }

  /// Validates the master credentials entered in the login screen.
  /// Matches username and compares SHA-256 hashed keys for PIN or standard passwords.
  Future<UserModel?> authenticateUser(String username, String hash, bool isPin) async {
    final db = await _dbService.database;
    
    // Construct query parameters
    final String keyColumn = isPin ? 'pin_hash' : 'password_hash';
    final String authType = isPin ? 'PIN' : 'PASSWORD';

    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ? AND $keyColumn = ? AND auth_type = ?',
      whereArgs: [username, hash, authType],
    );

    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }

  /// Returns the details of the active administrator (if any)
  Future<UserModel?> getMasterAccount() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> results = await db.query('users', limit: 1);
    if (results.isNotEmpty) {
      return UserModel.fromMap(results.first);
    }
    return null;
  }
}
