import 'dart:html' as html;
import 'dart:typed_data';

/// SaveHelper web-specific implementation using html.Blob and html.AnchorElement.
/// Triggers browser downloads on Chrome without breaking native mobile/desktop compilations.
class SaveHelper {
  /// Prompts browser download of the given bytes with the requested fileName.
  static Future<void> saveFile(Uint8List bytes, String fileName) async {
    // 1. Create a binary Blob from bytes array
    final blob = html.Blob([bytes]);

    // 2. Map blob bytes to virtual anchor URL object
    final url = html.Url.createObjectUrlFromBlob(blob);

    // 3. Programmatically click anchor to trigger browser download
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();

    // 4. Revoke memory bindings
    html.Url.revokeObjectUrl(url);
  }
}
