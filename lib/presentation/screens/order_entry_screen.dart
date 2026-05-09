import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/merchant_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';

/// OrderEntryScreen implements a state-of-the-art interactive Point of Sale (POS) form.
/// Designed with premium fintech-style visual tokens, tactile toggle buttons, a quick-tap product tray,
/// and an authentic thermal receipt checkout ticket that dynamically recalculates prices.
class OrderEntryScreen extends StatefulWidget {
  const OrderEntryScreen({super.key});

  @override
  State<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends State<OrderEntryScreen> {
  // Form and inputs coordination
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _riderController = TextEditingController();

  ProductModel? _selectedProduct;
  String _fulfillmentType = 'WALKIN'; // 'WALKIN' or 'DELIVERY'
  String _orderStatus = 'PENDING';     // 'PENDING' or 'COMPLETED'
  double _computedPrice = 0.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _quantityController.dispose();
    _riderController.dispose();
    super.dispose();
  }

  /// Recalculates order subtotal in real-time based on selected product and quantity.
  void _recalculatePrice() {
    if (_selectedProduct == null) {
      setState(() => _computedPrice = 0.0);
      return;
    }
    final int qty = int.tryParse(_quantityController.text) ?? 1;
    setState(() {
      _computedPrice = _selectedProduct!.sellingPrice * qty;
    });
  }

  /// Commits the customer order to SQLite via native FFI transaction bindings.
  /// Automatically rolls back on validation or inventory failure.
  Future<void> _submitOrder() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product from the catalog.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final int qty = int.parse(_quantityController.text);
    if (_selectedProduct!.quantity < qty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient stock. Only ${_selectedProduct!.quantity} units available.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    // Formulate database matching schema model
    final OrderModel newOrder = OrderModel(
      customerName: _customerNameController.text.trim(),
      customerAddress: _customerAddressController.text.trim(),
      productId: _selectedProduct!.id!,
      quantity: qty,
      computedPrice: _computedPrice,
      fulfillmentType: _fulfillmentType,
      deliveryRider: _fulfillmentType == 'DELIVERY' ? _riderController.text.trim() : null,
      status: _orderStatus,
      createdAt: DateTime.now().toIso8601String(),
    );

    // Execute safe database transaction
    bool success = await orderProvider.createOrder(newOrder, () {
      productProvider.loadProducts(); // Load updated stock level in parallel
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer transaction logged successfully!'), backgroundColor: AppColors.success),
      );
      
      // Flush inputs for the next transaction
      setState(() {
        _customerNameController.clear();
        _customerAddressController.clear();
        _quantityController.text = '1';
        _riderController.clear();
        _selectedProduct = null;
        _fulfillmentType = 'WALKIN';
        _orderStatus = 'PENDING';
        _computedPrice = 0.0;
        _isSubmitting = false;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(orderProvider.errorMessage ?? 'Transaction log failure.')),
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

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits smooth background gradient
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sleek Modern Page Header
              const Text('Record New Order', style: AppStyles.heading1),
              const SizedBox(height: 4),
              const Text(
                'Register custom customer checkout, logs, and billing ledger entries in real-time.',
                style: AppStyles.bodySecondary,
              ),
              const SizedBox(height: 28),

              // 2. Responsive POS Layout Split Panel
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 950;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Form entry left side
                      Expanded(
                        flex: isWide ? 5 : 8,
                        child: Column(
                          children: [
                            // Quick-select product catalog carousel
                            _buildProductTray(productProvider.products),
                            const SizedBox(height: 24),
                            _buildFormFields(productProvider.products),
                          ],
                        ),
                      ),
                      // Thermal Receipt Panel (Pushed below in vertical compact viewports)
                      if (isWide) ...[
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: _buildReceiptSummary(),
                        ),
                      ],
                    ],
                  );
                },
              ),
              
              // Bottom anchor for vertical/mobile screen layouts
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 950;
                  if (!isWide) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: _buildReceiptSummary(),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Horizontal scrolling ribbon showing product stocks with visual color markers.
  /// Facilitates instant click-to-populate features typical of professional tablets.
  Widget _buildProductTray(List<ProductModel> products) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.stars, color: AppColors.primaryLight, size: 16),
            const SizedBox(width: 6),
            const Text(
              'QUICK-TAP CATALOG',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 85,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final product = products[index];
              final bool isSelected = _selectedProduct?.id == product.id;
              final bool isOutOfStock = product.quantity <= 0;
              final bool isLowStock = product.quantity > 0 && product.quantity <= 5;

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: InkWell(
                  onTap: isOutOfStock
                      ? null
                      : () {
                          setState(() {
                            _selectedProduct = product;
                            _recalculatePrice();
                          });
                        },
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 145,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.08)
                          : isOutOfStock
                              ? AppColors.surface.withOpacity(0.15)
                              : AppColors.surface.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceLight.withOpacity(0.5),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3))]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isOutOfStock ? AppColors.textSecondary.withOpacity(0.4) : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Helpers.formatCurrency(product.sellingPrice),
                              style: TextStyle(
                                color: isOutOfStock ? AppColors.textSecondary.withOpacity(0.4) : AppColors.primaryLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // Stock Health Status Dot
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Builds core input form cards.
  Widget _buildFormFields(List<ProductModel> catalog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section: Customer Profile Info
        GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment_ind_outlined, color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text('Customer Profile Ledger', style: AppStyles.heading2),
                ],
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _customerNameController,
                labelText: 'Customer Full Name',
                prefixIcon: Icons.person_outline,
                validator: (v) => v!.trim().isEmpty ? 'Customer name is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _customerAddressController,
                labelText: 'Delivery Address / Contact Number',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => v!.trim().isEmpty ? 'Address / Contact information is required' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: Product Transaction Info
        GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text('Product Transaction Details', style: AppStyles.heading2),
                ],
              ),
              const SizedBox(height: 20),
              
              // Dropdown item selector with custom decoration
              DropdownButtonFormField<ProductModel>(
                value: _selectedProduct,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                decoration: AppStyles.customInputDecoration(
                  labelText: 'Select Catalog Product',
                  prefixIcon: Icons.inventory_2_outlined,
                ),
                dropdownColor: AppColors.surface,
                style: AppStyles.bodyPrimary,
                items: catalog.map((product) {
                  return DropdownMenuItem<ProductModel>(
                    value: product,
                    child: Text(
                      '${product.name} — ${Helpers.formatCurrency(product.sellingPrice)} (Available: ${product.quantity})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (product) {
                  setState(() {
                    _selectedProduct = product;
                    _recalculatePrice();
                  });
                },
                validator: (v) => v == null ? 'Product catalog selection is required' : null,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _quantityController,
                labelText: 'Purchased Quantity',
                prefixIcon: Icons.add_circle_outline_rounded,
                keyboardType: TextInputType.number,
                onChanged: (v) => _recalculatePrice(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Quantity required';
                  final int? val = int.tryParse(v);
                  if (val == null || val <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section: Fulfillment Logistics
        GlassCard(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text('Fulfillment Logistics', style: AppStyles.heading2),
                ],
              ),
              const SizedBox(height: 20),
              
              // Grid Row for distribution toggles (Store Walk-In vs Delivery)
              Row(
                children: [
                  Expanded(
                    child: _buildTactileFulfillmentButton(
                      title: 'Store Walk-In',
                      subtitle: 'Direct counter payment',
                      icon: Icons.storefront,
                      isSelected: _fulfillmentType == 'WALKIN',
                      onTap: () => setState(() => _fulfillmentType = 'WALKIN'),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTactileFulfillmentButton(
                      title: 'Rider Delivery',
                      subtitle: 'Direct home courier',
                      icon: Icons.delivery_dining_rounded,
                      isSelected: _fulfillmentType == 'DELIVERY',
                      onTap: () => setState(() => _fulfillmentType = 'DELIVERY'),
                    ),
                  ),
                ],
              ),
              
              // Collapsible Courier field details
              if (_fulfillmentType == 'DELIVERY') ...[
                const SizedBox(height: 16),
                AnimatedOpacity(
                  opacity: _fulfillmentType == 'DELIVERY' ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: CustomTextField(
                    controller: _riderController,
                    labelText: 'Delivery Rider / Dispatch Name (Optional)',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              const Divider(color: AppColors.surfaceLight, height: 1.5),
              const SizedBox(height: 20),

              // Tactile initial payment status selector
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Initial Checkout Status:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  _buildTactileStatusChip(
                    title: 'Pending Log',
                    icon: Icons.schedule_rounded,
                    color: AppColors.warning,
                    isSelected: _orderStatus == 'PENDING',
                    onTap: () => setState(() => _orderStatus = 'PENDING'),
                  ),
                  const SizedBox(width: 10),
                  _buildTactileStatusChip(
                    title: 'Completed Sales',
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
      ],
    );
  }

  /// Helper button builder for high-fidelity tactile logistics choice.
  Widget _buildTactileFulfillmentButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.06) : AppColors.surface.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceLight.withOpacity(0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper chip builder for high-fidelity initial payment selections.
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 14),
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

  /// Builds details display receipt sidebar card designed to look like a thermal ticket.
  Widget _buildReceiptSummary() {
    final merchantProvider = Provider.of<MerchantProvider>(context);
    final String storeName = merchantProvider.activeConfig?.storeName ?? 'OrderFlow';
    final String storeTagline = merchantProvider.activeConfig?.storeTagline ?? 'OFFLINE SYSTEM';

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Receipt Header
          Center(
            child: Column(
              children: [
                const Icon(Icons.receipt_long_rounded, color: AppColors.textSecondary, size: 28),
                const SizedBox(height: 10),
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
          const SizedBox(height: 20),
          
          _buildReceiptDivider(),
          const SizedBox(height: 16),

          // Total checkout display with high fintech visual impact
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GRAND TOTAL',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
                ),
                Text(
                  Helpers.formatCurrency(_computedPrice),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Aligned ledger items
          _buildReceiptRow('Product Catalog Name', _selectedProduct?.name ?? '—'),
          const SizedBox(height: 10),
          _buildReceiptRow('Unit Selling Price', _selectedProduct != null ? Helpers.formatCurrency(_selectedProduct!.sellingPrice) : '—'),
          const SizedBox(height: 10),
          _buildReceiptRow('Purchased Quantity', _quantityController.text.isEmpty ? '0' : _quantityController.text),
          const SizedBox(height: 10),
          _buildReceiptRow('Logistics Channel', _fulfillmentType == 'WALKIN' ? 'Store Walk-In' : 'Rider Delivery'),
          if (_fulfillmentType == 'DELIVERY' && _riderController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildReceiptRow('Assigned Courier', _riderController.text.trim()),
          ],
          
          const SizedBox(height: 20),
          _buildReceiptDivider(),
          const SizedBox(height: 16),

          // Simulated transaction barcode matching premium local POS terminals
          _buildSimulatedBarcode(),
          const SizedBox(height: 24),

          // Save transaction button
          ElevatedButton.icon(
            onPressed: _submitOrder,
            icon: const Icon(Icons.print_outlined, color: Colors.white, size: 18),
            label: const Text(
              'FINALIZE & CHECKOUT',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusMedium)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a real-time transaction barcode dynamically.
  Widget _buildSimulatedBarcode() {
    final List<double> barWidths = [1.5, 3.5, 2.0, 1.0, 4.0, 1.5, 2.5, 3.0, 1.0, 2.5, 1.0, 4.0, 2.0, 1.0, 3.0, 1.5, 2.0, 4.0, 1.0, 2.5, 1.0, 3.0];
    final String timestampSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: barWidths.map((width) {
              return Container(
                width: width,
                height: 32,
                color: AppColors.textSecondary.withOpacity(0.35),
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
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

  /// Helper receipt row builder inside thermal summary ticket.
  Widget _buildReceiptRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            val,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  /// Dotted line divider resembling the serrated edge of actual thermal receipts.
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
