import 'package:flutter/material.dart';
import '../data/models/product_model.dart';
import '../data/repository/product_repository.dart';

/// ProductProvider coordinates the active catalog of items.
/// It maintains lists of products in memory, eliminating redundant database query roundtrips,
/// while providing reactive updates to listening widget trees.
class ProductProvider with ChangeNotifier {
  final ProductRepository _productRepo = ProductRepository();

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProductProvider() {
    loadProducts();
  }

  /// Reloads the entire list of products from the local SQLite database.
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productRepo.getAllProducts();
    } catch (e) {
      _errorMessage = "Failed to load product catalog from database.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a single new product and refreshes the in-memory cache list.
  Future<bool> addProduct(ProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    int id = await _productRepo.insertProduct(product);
    _isLoading = false;

    if (id > 0) {
      await loadProducts(); // Re-sync local cache
      return true;
    } else {
      _errorMessage = "Product with this name already exists in the local database.";
      notifyListeners();
      return false;
    }
  }

  /// Transactionally saves a batch list of products.
  /// Typically called at the finalization of the product loading step in the Setup Wizard.
  Future<bool> setupInitialProducts(List<ProductModel> products) async {
    _isLoading = true;
    notifyListeners();

    bool success = await _productRepo.batchInsertProducts(products);
    _isLoading = false;

    if (success) {
      await loadProducts();
    } else {
      _errorMessage = "Failed to save initial product catalog.";
      notifyListeners();
    }
    return success;
  }

  /// Updates pricing, name, and stock metrics of an existing product.
  Future<bool> editProduct(ProductModel product) async {
    _isLoading = true;
    notifyListeners();

    bool success = await _productRepo.updateProduct(product);
    _isLoading = false;

    if (success) {
      await loadProducts();
    } else {
      _errorMessage = "Failed to save product updates.";
      notifyListeners();
    }
    return success;
  }

  /// Deletes a product from the database.
  /// If the product is linked to existing transactions, SQLite blocks the action
  /// and this method returns false, notifying the UI elegantly.
  Future<bool> removeProduct(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool success = await _productRepo.deleteProduct(id);
    _isLoading = false;

    if (success) {
      await loadProducts();
    } else {
      _errorMessage = "Cannot delete this product as it is currently linked to existing customer orders.";
      notifyListeners();
    }
    return success;
  }

  /// Helper getter: Extracts all unique custom column names (like "Size", "Color", "Weight")
  /// that have been defined across all products in the database.
  /// This is dynamic and extremely useful for building customizable tables.
  List<String> get dynamicColumnKeys {
    final Set<String> keys = {};
    for (var product in _products) {
      keys.addAll(product.extraColumns.keys);
    }
    return keys.toList();
  }
}
