/// OrderItemModel represents a single product line item inside a customer's Order transaction.
/// By storing the `unitPrice` snapshot, it ensures that even if product selling prices change in
/// the future, historical sales revenue figures remain consistent and correct.
class OrderItemModel {
  final int? id;               // Unique primary key in SQLite database
  final int? orderId;          // Foreign key referencing orders.id
  final int productId;         // Foreign key referencing products.id
  final int quantity;          // Number of units purchased
  final double unitPrice;      // Product selling price snapshot at checkout time
  final double computedPrice;  // Total computed price for this line item (quantity * unitPrice)
  
  // Joint fields (only loaded when performing INNER JOINS with products)
  final String? productName;

  OrderItemModel({
    this.id,
    this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.computedPrice,
    this.productName,
  });

  /// Factory constructor converting SQLite query Map results into an OrderItemModel instance.
  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as int?,
      orderId: map['order_id'] as int?,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      unitPrice: (map['unit_price'] as num).toDouble(),
      computedPrice: (map['computed_price'] as num).toDouble(),
      productName: map['product_name'] as String?, // Captured during SQL queries with JOINs
    );
  }

  /// Converts the model instance into a raw SQLite table-ready Map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'computed_price': computedPrice,
    };
  }
}
