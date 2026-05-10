import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_item_model.dart';
import '../../data/models/product_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/merchant_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';

/// OrderEntryScreen implements a state-of-the-art interactive Point of Sale (POS) system.
/// It features a dual-panel layout:
/// - Left: A debounced, searchable product catalog grid categorized by dynamic tags.
/// - Right: A thermal ticket Shopping Cart that calculates totals, verifies real-time stock levels,
///   handles fulfillment details (such as assigning delivery riders), and checks out orders atomically.
class OrderEntryScreen extends StatefulWidget {
  const OrderEntryScreen({super.key});

  @override
  State<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends State<OrderEntryScreen> {
  // Key inputs controllers
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _riderController = TextEditingController();
  final _searchController = TextEditingController();

  // Active Cart: Map of productId -> quantityOrdered
  final Map<int, int> _cart = {};

  // Settings states
  String _fulfillmentType = 'WALKIN'; // 'WALKIN' or 'DELIVERY'
  String _orderStatus = 'PENDING';     // 'PENDING' or 'COMPLETED'
  bool _isSubmitting = false;
  String _activeCategory = 'ALL';      // dynamic category filter

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _riderController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Increments product count inside the POS cart, validating against actual database stock.
  void _addToCart(ProductModel product) {
    final int currentCartQty = _cart[product.id!] ?? 0;
    
    if (product.quantity <= currentCartQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot add more units. Only ${product.quantity} items of ${product.name} are in stock.'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _cart[product.id!] = currentCartQty + 1;
    });
  }

  /// Decrements item quantities, completely removing the item if the count reaches zero.
  void _removeFromCart(ProductModel product) {
    final int currentCartQty = _cart[product.id!] ?? 0;
    if (currentCartQty <= 0) return;

    setState(() {
      if (currentCartQty == 1) {
        _cart.remove(product.id!);
      } else {
        _cart[product.id!] = currentCartQty - 1;
      }
    });
  }

  /// Calculates the grand total cost of all products added to the shopping cart.
  double _calculateGrandTotal(List<ProductModel> catalog) {
    double total = 0.0;
    _cart.forEach((productId, quantity) {
      final product = _findProductById(catalog, productId);
      if (product != null) {
        total += product.sellingPrice * quantity;
      }
    });
    return total;
  }

  /// Helper method to safely locate a product inside the cached Provider list.
  ProductModel? _findProductById(List<ProductModel> catalog, int id) {
    try {
      return catalog.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Commits the multi-product checkout transaction to SQLite inside a database Transaction.
  /// Rollbacks immediately if any stock constraints are breached.
  Future<void> _submitOrder() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your Shopping Cart is empty. Select products from the catalog first.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    // 1. Build line items (OrderItemModels) and compute prices
    final List<OrderItemModel> items = [];
    double grandTotal = 0.0;

    for (var entry in _cart.entries) {
      final product = _findProductById(productProvider.products, entry.key);
      if (product == null) continue;

      final double subtotal = product.sellingPrice * entry.value;
      grandTotal += subtotal;

      items.add(OrderItemModel(
        productId: product.id!,
        quantity: entry.value,
        unitPrice: product.sellingPrice,
        computedPrice: subtotal,
        productName: product.name,
      ));
    }

    // 2. Draft complete Order model mapping the 1-to-many header
    final OrderModel newOrder = OrderModel(
      customerName: _customerNameController.text.trim(),
      customerAddress: _customerAddressController.text.trim(),
      fulfillmentType: _fulfillmentType,
      deliveryRider: _fulfillmentType == 'DELIVERY' ? _riderController.text.trim() : null,
      status: _orderStatus,
      totalPrice: grandTotal,
      createdAt: DateTime.now().toIso8601String(),
      items: items,
    );

    // 3. Dispatch action through state controllers
    bool success = await orderProvider.createOrder(newOrder, () {
      productProvider.loadProducts(); // Sync catalog stock limits reactively
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Multi-product transaction logged successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Flush inputs and cart upon successful receipt creation
      setState(() {
        _customerNameController.clear();
        _customerAddressController.clear();
        _riderController.clear();
        _cart.clear();
        _fulfillmentType = 'WALKIN';
        _orderStatus = 'PENDING';
        _isSubmitting = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.errorMessage ?? 'Transaction validation failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 950;
    final double paddingVal = isMobile ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(paddingVal),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              const Text('Record New Order', style: AppStyles.heading1),
              const SizedBox(height: 4),
              const Text(
                'Register multi-product checkouts, client logistics, and billing ledger entries reactively.',
                style: AppStyles.bodySecondary,
              ),
              const SizedBox(height: 24),

              // Responsive split POS layout
              isMobile
                  ? Column(
                      children: [
                        _buildCatalogPanel(productProvider.products),
                        const SizedBox(height: 24),
                        _buildCheckoutReceiptPanel(productProvider.products),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Pane: Searchable Catalog
                        Expanded(
                          flex: 5,
                          child: _buildCatalogPanel(productProvider.products),
                        ),
                        const SizedBox(width: 24),
                        // Right Pane: Thermal Receipt Summary & Profiles
                        Expanded(
                          flex: 4,
                          child: _buildCheckoutReceiptPanel(productProvider.products),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the left-side POS product catalog displaying categorized items with searchable terms.
  Widget _buildCatalogPanel(List<ProductModel> catalog) {
    final query = _searchController.text.toLowerCase().trim();
    
    // 1. Collect all unique custom attribute values dynamically from active products in the catalog
    final Set<String> customPropertyValues = {};
    for (var product in catalog) {
      if (product.extraColumns.isNotEmpty) {
        for (var val in product.extraColumns.values) {
          final String str = val.toString().trim();
          if (str.isNotEmpty) {
            customPropertyValues.add(str);
          }
        }
      }
    }

    // 2. Filter products dynamically based on active custom tab selection and search query keywords
    final filteredCatalog = catalog.where((product) {
      final String nameLower = product.name.toLowerCase();
      
      bool matchesCategory = _activeCategory == 'ALL';
      if (!matchesCategory) {
        // Match product if any of its custom attributes has a value matching the active tab selection
        for (var val in product.extraColumns.values) {
          if (val.toString().trim().toUpperCase() == _activeCategory.toUpperCase()) {
            matchesCategory = true;
            break;
          }
        }
      }
      
      final bool matchesSearch = nameLower.contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Search Bar
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() {}),
          style: AppStyles.bodyPrimary,
          cursorColor: AppColors.primaryLight,
          decoration: InputDecoration(
            hintText: 'Search catalog items...',
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
            filled: true,
            fillColor: AppColors.background.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              borderSide: const BorderSide(color: AppColors.surfaceLight, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
              borderSide: const BorderSide(color: AppColors.primaryLight, width: 2.0),
            ),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 16),
                    onPressed: () => setState(() => _searchController.clear()),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),

        // 2. Dynamic Custom Property Filter Tabs (render only if catalog has custom attribute entries)
        if (customPropertyValues.isNotEmpty) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildCategoryTab('ALL', 'All Items', Icons.all_inclusive),
                ...customPropertyValues.map((value) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: _buildCategoryTab(value.trim().toUpperCase(), value.trim(), Icons.tag),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 3. Grid Catalog
        filteredCatalog.isEmpty
            ? Container(
                height: 300,
                alignment: Alignment.center,
                decoration: AppStyles.glassCardDecoration(),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory, size: 48, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text('No products found matching criteria.', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Check spelling or adjust dynamic categories.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: filteredCatalog.length,
                itemBuilder: (context, index) {
                  final product = filteredCatalog[index];
                  final int cartQty = _cart[product.id!] ?? 0;
                  final bool isOutOfStock = product.quantity <= 0;
                  final bool isLowStock = product.quantity > 0 && product.quantity <= 5;

                  return Container(
                    decoration: AppStyles.glassCardDecoration(
                      hasGlow: cartQty > 0,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        // Price
                        Text(
                          Helpers.formatCurrency(product.sellingPrice),
                          style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        
                        // Stock Indicator Capsule
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOutOfStock
                                    ? AppColors.error
                                    : isLowStock
                                        ? AppColors.warning
                                        : AppColors.success,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                isOutOfStock
                                    ? 'Out of Stock'
                                    : 'Stock: ${product.quantity - cartQty}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),

                        // Cart Controls Overlay
                        cartQty > 0
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _removeFromCart(product),
                                    icon: const Icon(Icons.remove_circle, color: AppColors.error, size: 22),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Text(
                                    '$cartQty',
                                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _addToCart(product),
                                    icon: const Icon(Icons.add_circle, color: AppColors.success, size: 22),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              )
                            : ElevatedButton(
                                onPressed: isOutOfStock ? null : () => _addToCart(product),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.surfaceLight.withOpacity(0.3),
                                  minimumSize: const Size.fromHeight(32),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusSmall)),
                                  elevation: 0,
                                ),
                                child: Text(
                                  isOutOfStock ? 'UNAVAILABLE' : '+ ADD TO CART',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  /// Builds a dynamic custom category selection tab widget.
  Widget _buildCategoryTab(String category, String label, IconData icon) {
    final bool isSelected = _activeCategory == category;
    return InkWell(
      onTap: () => setState(() => _activeCategory = category),
      borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : AppColors.surface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.surfaceLight,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryLight : AppColors.textSecondary, size: 14),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the right-side summary panels consisting of profile fields and the thermal ticket checkout drawer.
  Widget _buildCheckoutReceiptPanel(List<ProductModel> catalog) {
    final merchantProvider = Provider.of<MerchantProvider>(context);
    final String storeName = merchantProvider.activeConfig?.storeName ?? 'OrderFlow';
    final String storeTagline = merchantProvider.activeConfig?.storeTagline ?? 'OFFLINE SYSTEM';
    final double grandTotal = _calculateGrandTotal(catalog);

    return Column(
      children: [
        // 1. Customer Profiles Form Card
        GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_ind_outlined, color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text('Customer Ledger Details', style: AppStyles.heading2),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _customerNameController,
                labelText: 'Customer Full Name',
                prefixIcon: Icons.person_outline,
                validator: (v) => v!.trim().isEmpty ? 'Customer name is required' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _customerAddressController,
                labelText: 'Delivery Address / Contact Number',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => v!.trim().isEmpty ? 'Address information is required' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Fulfillment Logistics & Initial Status Card
        GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text('Logistics & Payments', style: AppStyles.heading2),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTactileButton(
                      title: 'Walk-In',
                      icon: Icons.storefront,
                      isSelected: _fulfillmentType == 'WALKIN',
                      onTap: () => setState(() => _fulfillmentType = 'WALKIN'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTactileButton(
                      title: 'Delivery',
                      icon: Icons.delivery_dining_rounded,
                      isSelected: _fulfillmentType == 'DELIVERY',
                      onTap: () => setState(() => _fulfillmentType = 'DELIVERY'),
                    ),
                  ),
                ],
              ),
              
              if (_fulfillmentType == 'DELIVERY') ...[
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _riderController,
                  labelText: 'Delivery Rider / Dispatch Name (Optional)',
                  prefixIcon: Icons.person_outline_rounded,
                ),
              ],
              
              const SizedBox(height: 16),
              const Divider(color: AppColors.surfaceLight, height: 1.0),
              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Checkout State:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  _buildTactileStatusChip(
                    title: 'Pending COD',
                    icon: Icons.schedule_rounded,
                    color: AppColors.warning,
                    isSelected: _orderStatus == 'PENDING',
                    onTap: () => setState(() => _orderStatus = 'PENDING'),
                  ),
                  _buildTactileStatusChip(
                    title: 'Paid Complete',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    isSelected: _orderStatus == 'COMPLETED',
                    onTap: () => setState(() => _orderStatus = 'COMPLETED'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 3. Simulated POS Thermal Ticket Cart Summary
        GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket Header
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: AppColors.textSecondary, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      storeName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      storeTagline.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildReceiptDivider(),
              const SizedBox(height: 16),

              // Capsule Display Grand Total with premium visual depth
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GRAND TOTAL',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                    ),
                    Text(
                      Helpers.formatCurrency(grandTotal),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Dynamic Cart Items Listing
              const Text('CART LINE ITEMS:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _cart.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text(
                          'No products in checkout cart.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final entry = _cart.entries.elementAt(index);
                        final product = _findProductById(catalog, entry.key);
                        if (product == null) return const SizedBox.shrink();
                        final double subtotal = product.sellingPrice * entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${entry.value} x ${Helpers.formatCurrency(product.sellingPrice)}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                Helpers.formatCurrency(subtotal),
                                style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 16),
              _buildReceiptDivider(),
              const SizedBox(height: 16),

              // Barcode simulation
              _buildSimulatedBarcode(),
              const SizedBox(height: 24),

              // Checkout Button
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitOrder,
                icon: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.print_outlined, color: Colors.white, size: 18),
                label: Text(
                  _isSubmitting ? 'PROCESSING...' : 'FINALIZE & CHECKOUT',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusMedium)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds custom tactile icon text selection buttons.
  Widget _buildTactileButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          border: Border.all(
            color: isSelected ? AppColors.primaryLight : AppColors.surfaceLight,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryLight : AppColors.textSecondary, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper status badge builder.
  Widget _buildTactileStatusChip({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          border: Border.all(
            color: isSelected ? color : AppColors.surfaceLight.withOpacity(0.5),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 13),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Serializes dynamic simulated barcodes matching modern receipt rolls.
  Widget _buildSimulatedBarcode() {
    final List<double> barWidths = [1.5, 3.5, 2.0, 1.0, 4.0, 1.5, 2.5, 3.0, 1.0, 2.5, 1.0, 4.0, 2.0, 1.0, 3.0, 1.5, 2.0, 4.0, 1.0, 2.5, 1.0, 3.0];
    final String timestampSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: barWidths.map((width) {
              return Container(
                width: width,
                height: 28,
                color: AppColors.textSecondary.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            'TXN-${DateTime.now().year}-$timestampSuffix',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Courier',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Dotted serrated line divider.
  Widget _buildReceiptDivider() {
    return Row(
      children: List.generate(
        35,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            height: 1.5,
            color: AppColors.surfaceLight.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}
