import 'package:sqflite/sqflite.dart';
import '../database/database_service.dart';
import '../models/order_model.dart';

/// OrderRepository manages SQL operations for sales orders.
/// It wraps sensitive operations (such as order placements and stock changes) in
/// rigorous SQLite database Transactions.
class OrderRepository {
  final DatabaseService _dbService = DatabaseService();

  /// Retrieves all orders from the database, performing an INNER JOIN with the
  /// `products` table to capture the product names for rendering in lists and tables.
  Future<List<OrderModel>> getAllOrders() async {
    final db = await _dbService.database;
    
    // We query with a JOIN to get 'products.name' as 'product_name'
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT orders.*, products.name AS product_name
      FROM orders
      INNER JOIN products ON orders.product_id = products.id
      ORDER BY orders.created_at DESC
    ''');

    return results.map((row) => OrderModel.fromMap(row)).toList();
  }

  /// Places a customer order. Runs in an SQL Transaction:
  /// 1. Inserts the order record into the `orders` table.
  /// 2. Queries and decrements the corresponding product stock quantity in `products` table.
  /// If anything fails, the entire block is rolled back automatically.
  Future<bool> placeOrder(OrderModel order) async {
    final db = await _dbService.database;

    try {
      return await db.transaction<bool>((txn) async {
        // 1. Fetch current product details to verify stock availability
        final List<Map<String, dynamic>> products = await txn.query(
          'products',
          where: 'id = ?',
          whereArgs: [order.productId],
        );

        if (products.isEmpty) {
          throw Exception("Product not found");
        }

        final int currentQty = products.first['quantity'] as int;
        
        // If stock is sufficient (or if stock is default/unlimited, e.g., 9999)
        // We decrement the stock by the ordered quantity.
        // (Note: If stock is 1 and user orders, we check if they want to block,
        // or just let the stock go negative or cap at 0. Let's cap at 0 or prevent overflow)
        final int newQty = (currentQty - order.quantity).clamp(0, 999999);

        // 2. Decrement the product stock
        await txn.update(
          'products',
          {'quantity': newQty},
          where: 'id = ?',
          whereArgs: [order.productId],
        );

        // 3. Write order record
        final int id = await txn.insert('orders', order.toMap());
        
        return id > 0;
      });
    } catch (e) {
      // Transaction failed or rolled back
      return false;
    }
  }

  /// Updates an order status (e.g. from PENDING to COMPLETED or CANCELLED).
  /// If status changes to CANCELLED, the product inventory stock is incremented back!
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    final db = await _dbService.database;

    try {
      return await db.transaction<bool>((txn) async {
        // Fetch current order status
        final List<Map<String, dynamic>> orders = await txn.query(
          'orders',
          where: 'id = ?',
          whereArgs: [orderId],
        );

        if (orders.isEmpty) return false;
        final String oldStatus = orders.first['status'] as String;
        final int productId = orders.first['product_id'] as int;
        final int quantity = orders.first['quantity'] as int;

        // If the order is being cancelled, return the items to the inventory stock
        if (newStatus == 'CANCELLED' && oldStatus != 'CANCELLED') {
          final List<Map<String, dynamic>> products = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [productId],
          );
          if (products.isNotEmpty) {
            final int currentQty = products.first['quantity'] as int;
            await txn.update(
              'products',
              {'quantity': currentQty + quantity},
              where: 'id = ?',
              whereArgs: [productId],
            );
          }
        }
        // If restoring from CANCELLED back to PENDING/COMPLETED, re-decrement stock
        else if (oldStatus == 'CANCELLED' && newStatus != 'CANCELLED') {
          final List<Map<String, dynamic>> products = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [productId],
          );
          if (products.isNotEmpty) {
            final int currentQty = products.first['quantity'] as int;
            final int newQty = (currentQty - quantity).clamp(0, 999999);
            await txn.update(
              'products',
              {'quantity': newQty},
              where: 'id = ?',
              whereArgs: [productId],
            );
          }
        }

        // Update the order status columns
        final int count = await txn.update(
          'orders',
          {'status': newStatus},
          where: 'id = ?',
          whereArgs: [orderId],
        );

        return count > 0;
      });
    } catch (_) {
      return false;
    }
  }

  /// AGGREGATED STATS QUERY: Returns total revenue generated from completed orders.
  Future<double> getTotalRevenue() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT SUM(computed_price) as total FROM orders WHERE status = 'COMPLETED'
    ''');
    if (result.isNotEmpty && result.first['total'] != null) {
      return (result.first['total'] as num).toDouble();
    }
    return 0.0;
  }

  /// AGGREGATED STATS QUERY: Returns total counts of all orders.
  Future<int> getTotalOrdersCount() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT COUNT(id) as count FROM orders
    ''');
    if (result.isNotEmpty && result.first['count'] != null) {
      return result.first['count'] as int;
    }
    return 0;
  }

  /// AGGREGATED STATS QUERY: Returns total pending order count.
  Future<int> getPendingOrdersCount() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT COUNT(id) as count FROM orders WHERE status = 'PENDING'
    ''');
    if (result.isNotEmpty && result.first['count'] != null) {
      return result.first['count'] as int;
    }
    return 0;
  }

  /// AGGREGATED STATS QUERY: Returns a top-performing product ranked by orders quantity sold.
  Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
    final db = await _dbService.database;
    return await db.rawQuery('''
      SELECT products.name as name, SUM(orders.quantity) as total_sold, SUM(orders.computed_price) as total_revenue
      FROM orders
      INNER JOIN products ON orders.product_id = products.id
      WHERE orders.status = 'COMPLETED'
      GROUP BY orders.product_id
      ORDER BY total_sold DESC
      LIMIT 5
    ''');
  }
}
