import 'package:flutter/material.dart';
import '../data/models/order_model.dart';
import '../data/repository/order_repository.dart';

/// OrderProvider coordinates customer order submissions and analytics.
/// It works alongside the repositories to keep the dashboard metrics and table listings
/// in full reactive synchrony.
class OrderProvider with ChangeNotifier {
  final OrderRepository _orderRepo = OrderRepository();

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Real-time Dashboard Analytics Fields
  double _totalRevenue = 0.0;
  int _totalOrdersCount = 0;
  int _pendingOrdersCount = 0;
  List<Map<String, dynamic>> _topProducts = [];

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Analytics Getters
  double get totalRevenue => _totalRevenue;
  int get totalOrdersCount => _totalOrdersCount;
  int get pendingOrdersCount => _pendingOrdersCount;
  List<Map<String, dynamic>> get topProducts => _topProducts;

  OrderProvider() {
    loadOrdersAndStats();
  }

  /// Refreshes both the order transactional log and the aggregated dashboard analytical tables.
  Future<void> loadOrdersAndStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderRepo.getAllOrders();
      _totalRevenue = await _orderRepo.getTotalRevenue();
      _totalOrdersCount = await _orderRepo.getTotalOrdersCount();
      _pendingOrdersCount = await _orderRepo.getPendingOrdersCount();
      _topProducts = await _orderRepo.getTopSellingProducts();
    } catch (e) {
      _errorMessage = "Failed to load orders or statistics from the local database.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submits a new customer transaction order. Runs stock decrement internally in an SQL transaction.
  /// If successful, also re-triggers product reload via a callback to sync stock values on screen!
  Future<bool> createOrder(OrderModel order, VoidCallback onStockUpdated) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool success = await _orderRepo.placeOrder(order);
    _isLoading = false;

    if (success) {
      onStockUpdated(); // Re-trigger ProductProvider reload
      await loadOrdersAndStats(); // Re-sync analytical stats and lists
      return true;
    } else {
      _errorMessage = "Failed to place order. Please verify if inventory stock is sufficient.";
      notifyListeners();
      return false;
    }
  }

  /// Updates an order status (e.g., Pending -> Completed or Cancelled).
  /// If cancelling, automatically restocks products in the database and triggers local widget reloads.
  Future<bool> changeOrderStatus(int orderId, String newStatus, VoidCallback onStockUpdated) async {
    _isLoading = true;
    notifyListeners();

    bool success = await _orderRepo.updateOrderStatus(orderId, newStatus);
    _isLoading = false;

    if (success) {
      onStockUpdated(); // Restocked trigger
      await loadOrdersAndStats();
      return true;
    } else {
      _errorMessage = "Failed to update order status.";
      notifyListeners();
      return false;
    }
  }
}
