import 'package:flutter/material.dart';
import '../data/models/merchant_model.dart';
import '../data/repository/merchant_repository.dart';

/// MerchantProvider manages the active state of white-labeled store branding details.
/// It reactive-loads SQLite configs and triggers UI updates automatically across all listeners on change.
class MerchantProvider with ChangeNotifier {
  final MerchantRepository _merchantRepo = MerchantRepository();

  MerchantConfigModel? _activeConfig;
  bool _isLoading = false;

  MerchantConfigModel? get activeConfig => _activeConfig;
  bool get isLoading => _isLoading;

  MerchantProvider() {
    loadBranding(); // Fetch SQLite configurations on provider bootstrap
  }

  /// Queries the active store name, tagline, and emblem from SQLite.
  Future<void> loadBranding() async {
    _isLoading = true;
    notifyListeners();

    try {
      _activeConfig = await _merchantRepo.getBranding();
    } catch (_) {
      // Direct safe fallback if database is not fully set up yet
      _activeConfig = MerchantConfigModel(
        storeName: 'OrderFlow',
        storeTagline: 'OFFLINE LEDGER & POS SYSTEM',
        storeIcon: 'STORE',
        updatedAt: DateTime.now().toIso8601String(),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Atomically commits a customized brand parameters map to SQLite.
  /// Instantly triggers a complete workspace repaint for a seamless white-labeled transition.
  Future<bool> updateBranding(String storeName, String storeTagline, String storeIcon) async {
    _isLoading = true;
    notifyListeners();

    final MerchantConfigModel newConfig = MerchantConfigModel(
      storeName: storeName.trim().isEmpty ? 'OrderFlow' : storeName.trim(),
      storeTagline: storeTagline.trim().isEmpty ? 'OFFLINE SYSTEM' : storeTagline.trim(),
      storeIcon: storeIcon,
      updatedAt: DateTime.now().toIso8601String(),
    );

    bool success = await _merchantRepo.updateBranding(newConfig);
    if (success) {
      _activeConfig = newConfig;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
