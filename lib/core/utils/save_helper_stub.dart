import 'dart:typed_data';

/// SaveHelper defines the cross-platform contract for exporting files.
/// This stub is used as the default interface and gets swapped out at compile-time
/// using conditional imports for web or desktop-specific environments.
class SaveHelper {
  /// Prompts the user to save backup bytes to a ZIP file.
  static Future<void> saveFile(Uint8List bytes, String fileName) async {
    throw UnimplementedError('Platform not supported.');
  }
}
