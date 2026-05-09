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
      return await db.insert(
        'products',
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort, // Abort to notify user of duplicated names
      );
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
        for (var product in products) {
          batch.insert(
            'products',
            product.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
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
}
