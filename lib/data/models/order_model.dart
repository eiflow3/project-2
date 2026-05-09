/// OrderModel represents a customer's transaction order log.
/// It models the sale of a product, capturing billing, shipping, and fulfillment.
class OrderModel {
  final int? id;
  final String customerName;
  final String customerAddress;
  final int productId;
  final int quantity;
  final double computedPrice; // Quantity * sellingPrice, auto-calculated on transaction
  final String fulfillmentType; // 'DELIVERY' or 'WALKIN'
  final String? deliveryRider;  // Optional courier name
  final String status;          // 'PENDING', 'COMPLETED', 'CANCELLED'
  final String createdAt;

  // Joint field: Helpful when reading order logs in a SQL JOIN query
  final String? productName;

  OrderModel({
    this.id,
    required this.customerName,
    required this.customerAddress,
    required this.productId,
    required this.quantity,
    required this.computedPrice,
    required this.fulfillmentType,
    this.deliveryRider,
    this.status = 'PENDING',
    required this.createdAt,
    this.productName,
  });

  /// Factory method to convert an SQLite JOIN query row Map into an OrderModel instance.
  /// Captures both the order columns and joined product columns seamlessly.
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as int?,
      customerName: map['customer_name'] as String,
      customerAddress: map['customer_address'] as String,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      computedPrice: (map['computed_price'] as num).toDouble(),
      fulfillmentType: map['fulfillment_type'] as String,
      deliveryRider: map['delivery_rider'] as String?,
      status: map['status'] as String? ?? 'PENDING',
      createdAt: map['created_at'] as String,
      productName: map['product_name'] as String?, // Available only during custom SQL JOINS
    );
  }

  /// Converts the OrderModel instance into a raw SQLite table-ready Map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'product_id': productId,
      'quantity': quantity,
      'computed_price': computedPrice,
      'fulfillment_type': fulfillmentType,
      'delivery_rider': deliveryRider,
      'status': status,
      'created_at': createdAt,
    };
  }
}
