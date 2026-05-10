import '../database/database_service.dart';
import '../models/merchant_model.dart';

/// MerchantRepository acts as the data access layer for store configurations in SQLite.
/// It encapsulates safe reads, transactional writes, and auto-initializations.
class MerchantRepository {
  final DatabaseService _dbService = DatabaseService();

  /// Retrieves the active store branding configuration from SQLite.
  /// Automatically injects a fallback default model if the table has no entries.
  Future<MerchantConfigModel> getBranding() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query('merchant_config', limit: 1);

    if (maps.isEmpty) {
      // Injects default fallback configurations (OrderFlow as global template)
      final MerchantConfigModel fallback = MerchantConfigModel(
        storeName: 'OrderFlow',
        storeTagline: 'OFFLINE LEDGER & POS SYSTEM',
        storeIcon: 'STORE',
        updatedAt: DateTime.now().toIso8601String(),
      );
      await db.insert('merchant_config', fallback.toMap());
      return fallback;
    }

    return MerchantConfigModel.fromMap(maps.first);
  }

  /// Commits a fresh brand identity (Store Name, Tagline, Icon) to the SQLite database.
  Future<bool> updateBranding(MerchantConfigModel config) async {
    try {
      final db = await _dbService.database;
      // Get the existing row count to verify if we overwrite or insert
      final List<Map<String, dynamic>> existing = await db.query('merchant_config', limit: 1);
      
      if (existing.isEmpty) {
        await db.insert('merchant_config', config.toMap());
      } else {
        final int id = existing.first['id'] as int;
        await db.update(
          'merchant_config',
          config.toMap(),
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
