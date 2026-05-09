import 'dart:io' as io;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

/// SaveHelper desktop-specific implementation using native system file dialogs.
/// Integrates path writing safely via dart:io stream writers.
class SaveHelper {
  /// Opens a native OS "Save As" overlay and writes bytes to user selected path.
  static Future<void> saveFile(Uint8List bytes, String fileName) async {
    // 1. Launch FilePicker's OS save dialog overlay
    String? outputFile = await FilePicker.saveFile(
      dialogTitle: 'Export Database ZIP Backup:',
      fileName: fileName,
    );

    if (outputFile != null) {
      // 2. Write the compressed archive stream straight to selected disk sector
      final file = io.File(outputFile);
      await file.writeAsBytes(bytes);
    }
  }
}
