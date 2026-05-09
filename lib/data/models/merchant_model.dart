import 'package:flutter/material.dart';

/// MerchantConfigModel represents the dynamic branding parameters of a store client.
/// It enables full white-labeling of the POS system by storing custom store names,
/// taglines, and active emblem definitions in SQLite.
class MerchantConfigModel {
  final int? id;
  final String storeName;
  final String storeTagline;
  final String storeIcon; // Codename of the emblem, e.g. "FLAME", "STORE", "BAG", "CART", "FOOD"
  final String updatedAt;

  const MerchantConfigModel({
    this.id,
    required this.storeName,
    required this.storeTagline,
    required this.storeIcon,
    required this.updatedAt,
  });

  /// Maps SQLite key-value data maps to dynamic model fields.
  factory MerchantConfigModel.fromMap(Map<String, dynamic> map) {
    return MerchantConfigModel(
      id: map['id'] as int?,
      storeName: map['store_name'] as String? ?? 'OrderFlow',
      storeTagline: map['store_tagline'] as String? ?? 'OFFLINE SYSTEM',
      storeIcon: map['store_icon'] as String? ?? 'STORE',
      updatedAt: map['updated_at'] as String? ?? '',
    );
  }

  /// Converts the active branding model fields into a writeable SQLite map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'store_name': storeName,
      'store_tagline': storeTagline,
      'store_icon': storeIcon,
      'updated_at': updatedAt,
    };
  }

  /// Maps the codename string from SQLite directly to beautiful, modern Material Icons.
  IconData getMaterialIcon() {
    switch (storeIcon.toUpperCase()) {
      case 'FLAME':
      case 'GAS':
        return Icons.local_fire_department_rounded;
      case 'STORE':
        return Icons.storefront_rounded;
      case 'BAG':
        return Icons.shopping_bag_rounded;
      case 'CART':
        return Icons.shopping_cart_rounded;
      case 'FOOD':
        return Icons.fastfood_rounded;
      case 'WATER':
        return Icons.water_drop_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }
}
