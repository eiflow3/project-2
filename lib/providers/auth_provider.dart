import 'package:flutter/material.dart';
import '../core/utils/helpers.dart';
import '../data/models/user_model.dart';
import '../data/repository/user_repository.dart';
import '../data/database/database_service.dart';

enum AuthStatus {
  loading,
  unregistered, // Needs first-time setup wizard
  unauthenticated, // Setup done, but user needs to enter PIN/Password
  authenticated // Logged in and active
}

/// AuthProvider coordinates authentication and setup session state.
class AuthProvider with ChangeNotifier {
  final UserRepository _userRepo = UserRepository();

  AuthStatus _status = AuthStatus.loading;
  UserModel? _currentUser;
  String? _loginError;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get loginError => _loginError;

  AuthProvider() {
    checkInitialState();
  }

  /// Checks if an administrator account exists on startup.
  /// Determines whether to launch into first-time Setup, Login, or the main App Panel.
  Future<void> checkInitialState() async {
    _status = AuthStatus.loading;
    notifyListeners();

    // Force a premium 3-second display constraint so the OrderFlow intro is visible
    await Future.delayed(const Duration(seconds: 3));

    try {
      bool hasAdmin = await _userRepo.hasRegisteredAdmin();
      if (hasAdmin) {
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.unregistered;
      }
    } catch (_) {
      _status = AuthStatus.unregistered; // Safe fallback to setup wizard
    }
    notifyListeners();
  }

  /// Finalizes the setup wizard. Writes the new administrator credentials
  /// and automatically logs them into the active session.
  Future<bool> completeAdminSetup(String username, String credential, bool isPin) async {
    _status = AuthStatus.loading;
    notifyListeners();

    final String now = DateTime.now().toIso8601String();
    final String hashedValue = Helpers.hashSha256(credential);

    final UserModel newAdmin = UserModel(
      username: username,
      authType: isPin ? 'PIN' : 'PASSWORD',
      passwordHash: isPin ? null : hashedValue,
      pinHash: isPin ? hashedValue : null,
      createdAt: now,
    );

    bool success = await _userRepo.registerMasterAccount(newAdmin);
    if (success) {
      _currentUser = newAdmin;
      // Keep state as unregistered so the onboarding route remains active for Step 2 (Product Catalog Staging)
      _status = AuthStatus.unregistered;
      _loginError = null;
    } else {
      _status = AuthStatus.unregistered;
      _loginError = "Failed to write administrative master account to disk.";
    }
    notifyListeners();
    return success;
  }

  /// Finalizes the entire 2-stage setup. Sets status to authenticated
  /// and unlocks the main application workspace.
  void finalizeOnboarding() {
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Verifies login credentials. Compares entries with SHA-256 hashes inside the repository.
  Future<bool> login(String username, String credential, bool isPin) async {
    _loginError = null;
    notifyListeners();

    final String hash = Helpers.hashSha256(credential);
    final UserModel? user = await _userRepo.authenticateUser(username, hash, isPin);

    if (user != null) {
      _currentUser = user;
      _status = AuthStatus.authenticated;
      _loginError = null;
      notifyListeners();
      return true;
    } else {
      _loginError = "Invalid master username or security verification key.";
      notifyListeners();
      return false;
    }
  }

  /// Logs out of the current active session, returning to the credentials lock screen.
  void logout() {
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _loginError = null;
    notifyListeners();
  }

  /// Resets the local database transactionally and redirects to the Setup Wizard.
  Future<void> resetApplication() async {
    _status = AuthStatus.loading;
    notifyListeners();

    // Force a premium 3-second display constraint so the OrderFlow intro is visible
    await Future.delayed(const Duration(seconds: 3));

    try {
      final dbService = DatabaseService();
      await dbService.clearAllData();
      _currentUser = null;
      _status = AuthStatus.unregistered;
      _loginError = null;
    } catch (_) {
      _loginError = "Failed to reset application database.";
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Exposes the master account settings query from the underlying UserRepository.
  /// Used by the LoginScreen to dynamically toggle between PIN or Password modes.
  Future<UserModel?> getMasterAccount() async {
    return await _userRepo.getMasterAccount();
  }
}
