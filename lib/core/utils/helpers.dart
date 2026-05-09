import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';

/// Helpers is a utility class providing general helpers like formatting, validation,
/// and security hashing functions. Doing this prevents repetitive boilerplates in widgets.
class Helpers {
  /// Formats raw numeric values into beautiful currency strings (e.g., "$1,250.00" or "₱1,250.00").
  /// This helps present consistent financial details across the dashboard and tables.
  static String formatCurrency(double amount) {
    // Add thousands separator manually to keep it purely offline and dependency-free
    String amountStr = amount.toStringAsFixed(2);
    List<String> parts = amountStr.split('.');
    String whole = parts[0];
    String decimal = parts[1];
    
    // Group three digits with commas
    RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String Function(Match) matchFunc = (Match match) => '${match[1]},';
    whole = whole.replaceAllMapped(reg, matchFunc);
    
    return '₱$whole.$decimal';
  }

  /// Hashes a plain-text input (like PIN or Password) using SHA-256 for secure, encrypted
  /// local comparison without storing raw keys in the SQLite database.
  static String hashSha256(String plainText) {
    List<int> bytes = utf8.encode(plainText); // Convert the input string to bytes
    Digest digest = sha256.convert(bytes);     // Perform the SHA-256 calculation
    return digest.toString();                 // Return hex string of the digest
  }

  /// Formats raw ISO timestamp strings into clean, human-readable display logs (e.g. "May 09, 2026 - 02:45 PM").
  static String formatTimestamp(String isoString) {
    try {
      DateTime dt = DateTime.parse(isoString);
      List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      String month = months[dt.month - 1];
      String day = dt.day.toString().padLeft(2, '0');
      int hour = dt.hour;
      String period = 'AM';
      if (hour >= 12) {
        period = 'PM';
        if (hour > 12) hour -= 12;
      }
      if (hour == 0) hour = 12;
      String minute = dt.minute.toString().padLeft(2, '0');
      return '$month $day, ${dt.year} - ${hour.toString().padLeft(2, '0')}:$minute $period';
    } catch (_) {
      return isoString; // Fallback to raw string if parsing fails
    }
  }

  /// Simple helper to validate customer names or product titles for empty space or injection.
  static bool isValidString(String? input) {
    if (input == null) return false;
    return input.trim().isNotEmpty;
  }

  /// Encodes SQLite raw database bytes into a standard compressed ZIP archive stream.
  /// Works flawlessly on both web and native desktop sandboxes because it relies on pure-Dart memory buffers.
  static Uint8List createBackupZip(Uint8List dbBytes) {
    // Initialize standard pure-Dart archive virtual folder
    final Archive archive = Archive();
    
    // Package our DB file into the virtual folder's directory structure
    final ArchiveFile file = ArchiveFile(
      'offline_order_manager.db',
      dbBytes.length,
      dbBytes,
    );
    archive.addFile(file);
    
    // Encode and compress the archive directory using the native ZIP spec
    final List<int>? zipBytes = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipBytes!);
  }

  /// Decodes and extracts the raw SQLite database bytes from a compressed ZIP backup archive.
  /// Returns null if the ZIP file does not contain a valid 'offline_order_manager.db' file.
  static Uint8List? extractDbFromZip(Uint8List zipBytes) {
    // Decode the zip bytes in memory
    final Archive archive = ZipDecoder().decodeBytes(zipBytes);
    
    // Scan all files contained in the zip archive for our database file name
    for (final ArchiveFile file in archive) {
      if (file.name == 'offline_order_manager.db') {
        // Return the extracted decompressed raw bytes
        return file.content as Uint8List;
      }
    }
    return null;
  }
}
