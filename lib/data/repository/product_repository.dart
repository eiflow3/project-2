import 'package:sqflite/sqflite.dart';
import '../database/database_service.dart';
import '../models/product_model.dart';

/// ProductRepository handles all database queries and transactions relating to product inventory.
class ProductRepository {
  final DatabaseService _dbService = DatabaseService();

  /// Retrieves the complete list of products currently registered in the database,
  /// ordered alphabetically by name.
  Future<List<ProductModel>> getAllProducts() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> results = await db.query('products', orderBy: 'name ASC');
    return results.map((row) => ProductModel.fromMap(row)).toList();
  }

  /// Inserts a new product into the database.
  /// Throws an error or returns -1 if a product with the same name already exists.
  Future<int> insertProduct(ProductModel product) async {
    final db = await _dbService.database;
    try {
      final int id = await db.insert(
        'products',
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort, // Abort to notify user of duplicated names
      );
      if (id != -1 && product.extraColumns.isNotEmpty) {
        await _saveKeys(db, product.extraColumns.keys.toList());
      }
      return id;
    } catch (_) {
      return -1;
    }
  }

  /// Performs a batch transactional insert of multiple products.
  /// This is highly efficient and optimized for the first-time setup wizard where multiple
  /// items are saved in one block.
  Future<bool> batchInsertProducts(List<ProductModel> products) async {
    final db = await _dbService.database;
    try {
      await db.transaction((txn) async {
        final Batch batch = txn.batch();
        final List<String> allKeys = [];
        for (var product in products) {
          batch.insert(
            'products',
            product.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          if (product.extraColumns.isNotEmpty) {
            allKeys.addAll(product.extraColumns.keys);
          }
        }
        await batch.commit(noResult: true);
        if (allKeys.isNotEmpty) {
          await _saveKeys(txn, allKeys);
        }
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Updates pricing, costs, and current stock count of an existing product.
  Future<bool> updateProduct(ProductModel product) async {
    if (product.id == null) return false;
    final db = await _dbService.database;
    
    final int count = await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
    if (count > 0 && product.extraColumns.isNotEmpty) {
      await _saveKeys(db, product.extraColumns.keys.toList());
    }
    return count > 0;
  }

  /// Deletes a product from the database.
  /// Note: The SQLite table enforces `ON DELETE RESTRICT` via foreign keys.
  /// If a product is already linked to some transaction orders, this call will catch a
  /// DatabaseException, preserving referential order integrity!
  Future<bool> deleteProduct(int id) async {
    final db = await _dbService.database;
    try {
      final int count = await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (_) {
      // Deletions of products with existing order logs are blocked to protect business data
      return false;
    }
  }

  /// Helper helper to uniquely insert custom property keys using INSERT OR IGNORE.
  Future<void> _saveKeys(DatabaseExecutor db, List<String> keys) async {
    for (var key in keys) {
      final String trimmed = key.trim();
      if (trimmed.isNotEmpty) {
        await db.insert(
          'product_property_keys',
          {'key_name': trimmed},
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  /// Retrieves all uniquely registered custom property keys (e.g. 'Size', 'Weight') from the database.
  Future<List<String>> getCustomPropertyKeys() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> results = await db.query(
      'product_property_keys',
      orderBy: 'key_name ASC',
    );
    return results.map((row) => row['key_name'] as String).toList();
  }
}
