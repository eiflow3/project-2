import 'order_item_model.dart';

/// OrderModel represents a customer's transaction order log.
/// It models the sale of multiple products, capturing billing, shipping, and fulfillment.
class OrderModel {
  final int? id;
  final String customerName;
  final String customerAddress;
  final String fulfillmentType; // 'DELIVERY' or 'WALKIN'
  final String? deliveryRider;  // Optional courier name
  final String status;          // 'PENDING', 'COMPLETED', 'CANCELLED'
  final String createdAt;
  final double totalPrice;       // Grand total of all line items
  final List<OrderItemModel> items; // Nested list of purchased products

  OrderModel({
    this.id,
    required this.customerName,
    required this.customerAddress,
    required this.fulfillmentType,
    this.deliveryRider,
    this.status = 'PENDING',
    required this.totalPrice,
    required this.createdAt,
    required this.items,
  });

  /// Backward-compatibility getter mapping computedPrice back to totalPrice
  double get computedPrice => totalPrice;

  /// Backward-compatibility getter fetching the main/first product ID
  int get productId => items.isNotEmpty ? items.first.productId : 0;

  /// Backward-compatibility getter counting total item units in order
  int get quantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Backward-compatibility getter displaying a readable summary of items
  String? get productName {
    if (items.isEmpty) return null;
    if (items.length == 1) return items.first.productName ?? 'Product #${items.first.productId}';
    final int extraCount = items.length - 1;
    final String mainName = items.first.productName ?? 'Product #${items.first.productId}';
    return '$mainName (+$extraCount item${extraCount > 1 ? "s" : ""})';
  }

  /// Factory method to convert an SQLite row Map into an OrderModel instance.
  /// Receives hydrated line items from the repository during queries.
  factory OrderModel.fromMap(Map<String, dynamic> map, {List<OrderItemModel> items = const []}) {
    return OrderModel(
      id: map['id'] as int?,
      customerName: map['customer_name'] as String,
      customerAddress: map['customer_address'] as String,
      fulfillmentType: map['fulfillment_type'] as String,
      deliveryRider: map['delivery_rider'] as String?,
      status: map['status'] as String? ?? 'PENDING',
      totalPrice: (map['total_price'] as num? ?? map['computed_price'] as num? ?? 0.0).toDouble(),
      createdAt: map['created_at'] as String,
      items: items,
    );
  }

  /// Converts the OrderModel instance into a raw SQLite table-ready Map.
  /// Inserts header details only. Line items are inserted into a separate table.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_name': customerName,
      'customer_address': customerAddress,
      'fulfillment_type': fulfillmentType,
      'delivery_rider': deliveryRider,
      'status': status,
      'total_price': totalPrice,
      'created_at': createdAt,
    };
  }
}

