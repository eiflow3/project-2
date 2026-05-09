import 'dart:convert';

/// ProductModel represents a store item in the inventory catalog.
/// It accommodates custom-defined attribute columns dynamically by storing them in
/// [extraColumns] and serializing them into/from a raw JSON string in the SQLite database.
class ProductModel {
  final int? id;
  final String name;
  final double unitCost;
  final double sellingPrice;
  final int quantity; // Available stock, default to 1
  final Map<String, dynamic> extraColumns; // Stores custom attributes (e.g. {"Size": "Large", "Color": "Blue"})
  final String createdAt;

  ProductModel({
    this.id,
    required this.name,
    required this.unitCost,
    required this.sellingPrice,
    this.quantity = 1,
    required this.extraColumns,
    required this.createdAt,
  });

  /// Factory method to convert an SQLite row Map into a ProductModel.
  /// Decodes 'extra_columns_json' from a raw String back into a structured Map.
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> extraCols = {};
    if (map['extra_columns_json'] != null && (map['extra_columns_json'] as String).isNotEmpty) {
      try {
        extraCols = json.decode(map['extra_columns_json'] as String) as Map<String, dynamic>;
      } catch (e) {
        // Fallback in case of JSON decoding issues
        extraCols = {};
      }
    }

    return ProductModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      unitCost: (map['unit_cost'] as num).toDouble(),
      sellingPrice: (map['selling_price'] as num).toDouble(),
      quantity: map['quantity'] as int? ?? 1,
      extraColumns: extraCols,
      createdAt: map['created_at'] as String,
    );
  }

  /// Converts the ProductModel back into an SQLite map row.
  /// Encodes the 'extraColumns' Map into a clean serialized JSON string.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'unit_cost': unitCost,
      'selling_price': sellingPrice,
      'quantity': quantity,
      'extra_columns_json': json.encode(extraColumns),
      'created_at': createdAt,
    };
  }
}
