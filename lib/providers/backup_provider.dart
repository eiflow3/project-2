import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';

// Import our internal references
import '../core/utils/helpers.dart';
import '../data/database/database_service.dart';

// Cross-platform save helper using conditional compilation
import '../core/utils/save_helper_stub.dart'
    if (dart.library.html) '../core/utils/save_helper_web.dart'
    if (dart.library.io) '../core/utils/save_helper_desktop.dart';

/// BackupProvider coordinates database exporting and importing operations.
/// It uses pure-Dart memory compression to safely ZIP SQLite schemas,
/// and is 100% responsive and interactive across desktop and web environments.
class BackupProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Clear messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Exports the local database file as a compressed ZIP backup archive.
  Future<bool> exportBackup() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final dbService = DatabaseService();
      final String dbPath = await dbService.getDatabasePath();

      // Read raw SQLite database bytes using the factory (supports ffi and web!)
      final Uint8List dbBytes = await databaseFactory.readDatabaseBytes(dbPath);

      if (dbBytes.isEmpty) {
        throw Exception("Database file is empty or uninitialized.");
      }

      // Convert database bytes into compressed ZIP file bytes
      final Uint8List zipBytes = Helpers.createBackupZip(dbBytes);

      // Create a unique backup file name containing the current human-readable date and time
      final DateTime now = DateTime.now();
      final String timestamp = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
      final String fileName = "orderflow_backup_$timestamp.zip";

      // Trigger cross-platform save operation
      await SaveHelper.saveFile(zipBytes, fileName);

      _successMessage = "Database backup exported successfully as: $fileName";
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to export database: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Prompts the user to select a ZIP archive and restores their database.
  /// On success, triggers the [onReloadAll] callback to notify other providers to refresh state from the new SQLite database.
  Future<bool> importBackup(Future<void> Function() onReloadAll) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // 1. Pick a zip file from system
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        dialogTitle: 'Select OrderFlow Backup ZIP:',
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled picker
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final PlatformFile pickedFile = result.files.first;
      Uint8List? zipBytes;

      // 2. Load file bytes safely across both Web and Desktop platforms
      if (kIsWeb) {
        zipBytes = pickedFile.bytes;
      } else {
        if (pickedFile.bytes != null) {
          zipBytes = pickedFile.bytes;
        } else if (pickedFile.path != null) {
          final io.File file = io.File(pickedFile.path!);
          zipBytes = await file.readAsBytes();
        }
      }

      if (zipBytes == null || zipBytes.isEmpty) {
        throw Exception("Could not read backup file contents.");
      }

      // 3. Extract the database file from ZIP
      final Uint8List? dbBytes = Helpers.extractDbFromZip(zipBytes);
      if (dbBytes == null) {
        throw Exception("Invalid backup file. Could not find a valid database file inside the ZIP archive.");
      }

      // 4. Close database connection, overwrite the file, and re-establish connection
      await DatabaseService().importDatabaseBytes(dbBytes);

      // 5. Trigger external callbacks to reload other provider data schemas
      await onReloadAll();

      _successMessage = "Database backup imported successfully. Your active screen has been refreshed!";
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Failed to import database: ${e.toString()}";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
