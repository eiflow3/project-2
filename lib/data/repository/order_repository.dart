import '../database/database_service.dart';
import '../models/order_model.dart';
import '../models/order_item_model.dart';

/// OrderRepository manages SQL operations for sales orders.
/// It wraps sensitive operations (such as multi-product checkout placements and stock changes) in
/// rigorous SQLite database Transactions.
class OrderRepository {
  final DatabaseService _dbService = DatabaseService();

  /// Retrieves all orders from the database. It first queries order headers,
  /// then fetches all order items mapped with product definitions in a single fast,
  /// N+1-avoiding query, grouping them efficiently in memory.
  Future<List<OrderModel>> getAllOrders() async {
    final db = await _dbService.database;
    
    // 1. Fetch all order headers
    final List<Map<String, dynamic>> orderHeaders = await db.query(
      'orders',
      orderBy: 'created_at DESC',
    );

    if (orderHeaders.isEmpty) return [];

    // 2. Fetch all order items linked with their respective product names using JOINs
    final List<Map<String, dynamic>> orderItemsRaw = await db.rawQuery('''
      SELECT order_items.*, products.name AS product_name
      FROM order_items
      INNER JOIN products ON order_items.product_id = products.id
    ''');

    // 3. Group order items in memory by parent order_id
    final Map<int, List<OrderItemModel>> itemsMap = {};
    for (var row in orderItemsRaw) {
      final int orderId = row['order_id'] as int;
      final OrderItemModel item = OrderItemModel.fromMap(row);
      itemsMap.putIfAbsent(orderId, () => []).add(item);
    }

    // 4. Hydrate the order headers with their corresponding items
    return orderHeaders.map((header) {
      final int orderId = header['id'] as int;
      final List<OrderItemModel> items = itemsMap[orderId] ?? <OrderItemModel>[];
      return OrderModel.fromMap(header, items: items);
    }).toList();
  }

  /// Places a customer order containing multiple products. Runs in an SQL Transaction:
  /// 1. Validates stock availability for ALL items in the order.
  /// 2. If valid, decrements product stock values in `products` catalog.
  /// 3. Inserts the order header into the `orders` table.
  /// 4. Inserts all ordered items into the `order_items` table.
  /// If anything fails, the entire transaction is rolled back automatically.
  Future<bool> placeOrder(OrderModel order) async {
    final db = await _dbService.database;

    try {
      return await db.transaction<bool>((txn) async {
        // 1. First pass: Validate stock availability for all products in the cart
        for (var item in order.items) {
          final List<Map<String, dynamic>> products = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [item.productId],
          );

          if (products.isEmpty) {
            throw Exception("Product not found");
          }

          final int currentQty = products.first['quantity'] as int;
          
          if (currentQty < item.quantity) {
            throw Exception(
              "Insufficient stock for product '${products.first['name']}': "
              "$currentQty units available, but requested ${item.quantity}."
            );
          }
        }

        // 2. Second pass: Safely decrement product stocks
        for (var item in order.items) {
          final List<Map<String, dynamic>> products = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [item.productId],
          );
          final int currentQty = products.first['quantity'] as int;
          final int newQty = currentQty - item.quantity;

          await txn.update(
            'products',
            {'quantity': newQty},
            where: 'id = ?',
            whereArgs: [item.productId],
          );
        }

        // 3. Write Order header to the database
        final int orderId = await txn.insert('orders', order.toMap());

        // 4. Write all line items to the database
        for (var item in order.items) {
          final Map<String, dynamic> itemMap = item.toMap();
          itemMap['order_id'] = orderId; // Link back to parent Order ID
          await txn.insert('order_items', itemMap);
        }
        
        return orderId > 0;
      });
    } catch (e) {
      // Transaction automatically rolled back
      return false;
    }
  }

  /// Updates an order status (e.g. PENDING to COMPLETED or CANCELLED).
  /// Safely manages stocking rules for all products inside the order:
  /// - Cancelling: Increments back product quantities for all items in the order.
  /// - Restoring: Checks and decrements stock for all items.
  Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    final db = await _dbService.database;

    try {
      return await db.transaction<bool>((txn) async {
        // 1. Fetch current order status
        final List<Map<String, dynamic>> orders = await txn.query(
          'orders',
          where: 'id = ?',
          whereArgs: [orderId],
        );

        if (orders.isEmpty) return false;
        final String oldStatus = orders.first['status'] as String;

        // If no change, return immediately
        if (oldStatus == newStatus) return true;

        // 2. Fetch all order items associated with this transaction
        final List<Map<String, dynamic>> orderItems = await txn.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [orderId],
        );

        // CASE A: Order is being CANCELLED. Return all quantities back to products stock.
        if (newStatus == 'CANCELLED' && oldStatus != 'CANCELLED') {
          for (var itemMap in orderItems) {
            final int productId = itemMap['product_id'] as int;
            final int quantity = itemMap['quantity'] as int;

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
        }
        // CASE B: Restoring from CANCELLED. We must validate and decrement stock for all items.
        else if (oldStatus == 'CANCELLED' && newStatus != 'CANCELLED') {
          // B1. First pass: Validate stock availability
          for (var itemMap in orderItems) {
            final int productId = itemMap['product_id'] as int;
            final int quantity = itemMap['quantity'] as int;

            final List<Map<String, dynamic>> products = await txn.query(
              'products',
              where: 'id = ?',
              whereArgs: [productId],
            );
            if (products.isEmpty) throw Exception("Product matching ID $productId not found.");
            final int currentQty = products.first['quantity'] as int;
            if (currentQty < quantity) {
              throw Exception(
                "Insufficient stock to restore this order: '${products.first['name']}' "
                "has $currentQty units, but requested $quantity."
              );
            }
          }

          // B2. Second pass: Re-decrement stock
          for (var itemMap in orderItems) {
            final int productId = itemMap['product_id'] as int;
            final int quantity = itemMap['quantity'] as int;

            final List<Map<String, dynamic>> products = await txn.query(
              'products',
              where: 'id = ?',
              whereArgs: [productId],
            );
            final int currentQty = products.first['quantity'] as int;
            await txn.update(
              'products',
              {'quantity': currentQty - quantity},
              where: 'id = ?',
              whereArgs: [productId],
            );
          }
        }

        // 3. Update the order status column
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
      SELECT SUM(total_price) as total FROM orders WHERE status = 'COMPLETED'
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

  /// AGGREGATED STATS QUERY: Returns top-performing products ranked by sales quantity sold.
  Future<List<Map<String, dynamic>>> getTopSellingProducts() async {
    final db = await _dbService.database;
    return await db.rawQuery('''
      SELECT products.name as name, SUM(order_items.quantity) as total_sold, SUM(order_items.computed_price) as total_revenue
      FROM order_items
      INNER JOIN products ON order_items.product_id = products.id
      INNER JOIN orders ON order_items.order_id = orders.id
      WHERE orders.status = 'COMPLETED'
      GROUP BY order_items.product_id
      ORDER BY total_sold DESC
      LIMIT 5
    ''');
  }
}
