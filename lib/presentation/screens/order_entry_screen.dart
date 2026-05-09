import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';

/// OrderEntryScreen is a comprehensive order placement form.
/// It dynamically computes pricing on changes and performs transactions in the SQL layer.
class OrderEntryScreen extends StatefulWidget {
  const OrderEntryScreen({super.key});

  @override
  State<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends State<OrderEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _riderController = TextEditingController();

  ProductModel? _selectedProduct;
  String _fulfillmentType = 'WALKIN'; // 'WALKIN' or 'DELIVERY'
  String _orderStatus = 'PENDING';     // 'PENDING', 'COMPLETED'
  double _computedPrice = 0.0;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerAddressController.dispose();
    _quantityController.dispose();
    _riderController.dispose();
    super.dispose();
  }

  /// Triggered whenever product or quantity selections change.
  /// Dynamically computes total price in real-time.
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

  /// Triggers SQL transaction to place the customer order.
  /// Automatically rolls back on failure or insufficient stock.
  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product from the catalog.'), backgroundColor: AppColors.warning),
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

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

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

    // Call Provider to insert order and decrement stock
    bool success = await orderProvider.createOrder(newOrder, () {
      productProvider.loadProducts(); // Refresh stock metrics in parallel
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!'), backgroundColor: AppColors.success),
      );
      
      // Clear all form controllers on success
      setState(() {
        _customerNameController.clear();
        _customerAddressController.clear();
        _quantityController.text = '1';
        _riderController.clear();
        _selectedProduct = null;
        _fulfillmentType = 'WALKIN';
        _orderStatus = 'PENDING';
        _computedPrice = 0.0;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(orderProvider.errorMessage ?? 'Failed to submit order.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title
              const Text('Record New Order', style: AppStyles.heading1),
              const SizedBox(height: 4),
              const Text('Add customer and transaction logs directly into your local database.', style: AppStyles.bodySecondary),
              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  // Two columns on wider viewports
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: _buildFormFields(productProvider.products)),
                        const SizedBox(width: 24),
                        Expanded(flex: 3, child: _buildReceiptSummary()),
                      ],
                    );
                  }
                  // Single column on narrow windows
                  return Column(
                    children: [
                      _buildFormFields(productProvider.products),
                      const SizedBox(height: 24),
                      _buildReceiptSummary(),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds core input form cards.
  Widget _buildFormFields(List<ProductModel> catalog) {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Profile', style: AppStyles.heading2),
          const SizedBox(height: 24),

          CustomTextField(
            controller: _customerNameController,
            labelText: 'Customer Full Name',
            prefixIcon: Icons.person_outline,
            validator: (v) => v!.trim().isEmpty ? 'Customer name is required' : null,
          ),
          const SizedBox(height: 20),

          CustomTextField(
            controller: _customerAddressController,
            labelText: 'Customer Delivery Address / Contact',
            prefixIcon: Icons.location_on_outlined,
            validator: (v) => v!.trim().isEmpty ? 'Address is required' : null,
          ),
          const SizedBox(height: 32),

          const Text('Product Transaction Details', style: AppStyles.heading2),
          const SizedBox(height: 24),

          // Searchable/Selectable Product Dropdown
          DropdownButtonFormField<ProductModel>(
            value: _selectedProduct,
            decoration: AppStyles.customInputDecoration(
              labelText: 'Select Purchased Product',
              prefixIcon: Icons.shopping_bag_outlined,
            ),
            dropdownColor: AppColors.surface,
            style: AppStyles.bodyPrimary,
            items: catalog.map((product) {
              return DropdownMenuItem<ProductModel>(
                value: product,
                child: Text('${product.name} — ${Helpers.formatCurrency(product.sellingPrice)} (Stock: ${product.quantity})'),
              );
            }).toList(),
            onChanged: (product) {
              setState(() {
                _selectedProduct = product;
                _recalculatePrice();
              });
            },
            validator: (v) => v == null ? 'Please select a product' : null,
          ),
          const SizedBox(height: 20),

          // Quantity Input
          CustomTextField(
            controller: _quantityController,
            labelText: 'Quantity to purchase',
            prefixIcon: Icons.tag,
            keyboardType: TextInputType.number,
            onChanged: (v) => _recalculatePrice(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Quantity required';
              final int? val = int.tryParse(v);
              if (val == null || val <= 0) return 'Must be greater than 0';
              return null;
            },
          ),
          const SizedBox(height: 32),

          const Text('Fulfillment Options', style: AppStyles.heading2),
          const SizedBox(height: 24),

          // Distribution Toggles (Walk-In or Delivery)
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  avatar: Icon(Icons.storefront, color: _fulfillmentType == 'WALKIN' ? Colors.white : AppColors.textSecondary, size: 16),
                  label: const Text('Store Walk-In', style: TextStyle(fontSize: 13)),
                  selected: _fulfillmentType == 'WALKIN',
                  onSelected: (selected) {
                    if (selected) setState(() => _fulfillmentType = 'WALKIN');
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background.withOpacity(0.5),
                  labelStyle: TextStyle(color: _fulfillmentType == 'WALKIN' ? Colors.white : AppColors.textSecondary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusSmall)),
                  side: BorderSide(color: _fulfillmentType == 'WALKIN' ? AppColors.primary : AppColors.surfaceLight),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ChoiceChip(
                  avatar: Icon(Icons.local_shipping_outlined, color: _fulfillmentType == 'DELIVERY' ? Colors.white : AppColors.textSecondary, size: 16),
                  label: const Text('Rider Delivery', style: TextStyle(fontSize: 13)),
                  selected: _fulfillmentType == 'DELIVERY',
                  onSelected: (selected) {
                    if (selected) setState(() => _fulfillmentType = 'DELIVERY');
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.background.withOpacity(0.5),
                  labelStyle: TextStyle(color: _fulfillmentType == 'DELIVERY' ? Colors.white : AppColors.textSecondary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusSmall)),
                  side: BorderSide(color: _fulfillmentType == 'DELIVERY' ? AppColors.primary : AppColors.surfaceLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Conditional Rider Name Field (Only visible during Delivery fulfillment mode)
          if (_fulfillmentType == 'DELIVERY')
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: CustomTextField(
                controller: _riderController,
                labelText: 'Delivery Courier / Rider Name (Optional)',
                prefixIcon: Icons.directions_bike_outlined,
              ),
            ),

          // Order status selection
          Row(
            children: [
              const Text('Initial Order Status:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Pending Payment/Log', style: TextStyle(fontSize: 12)),
                selected: _orderStatus == 'PENDING',
                onSelected: (selected) {
                  if (selected) setState(() => _orderStatus = 'PENDING');
                },
                selectedColor: AppColors.warning.withOpacity(0.15),
                labelStyle: TextStyle(color: _orderStatus == 'PENDING' ? AppColors.warning : AppColors.textSecondary),
                side: BorderSide(color: _orderStatus == 'PENDING' ? AppColors.warning : AppColors.surfaceLight),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Completed Sales', style: TextStyle(fontSize: 12)),
                selected: _orderStatus == 'COMPLETED',
                onSelected: (selected) {
                  if (selected) setState(() => _orderStatus = 'COMPLETED');
                },
                selectedColor: AppColors.success.withOpacity(0.15),
                labelStyle: TextStyle(color: _orderStatus == 'COMPLETED' ? AppColors.success : AppColors.textSecondary),
                side: BorderSide(color: _orderStatus == 'COMPLETED' ? AppColors.success : AppColors.surfaceLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds details display receipt sidebar card.
  Widget _buildReceiptSummary() {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Invoice Summary', style: AppStyles.heading2),
          const SizedBox(height: 24),

          // Total Price Card with high visual impact
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Computed Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  Helpers.formatCurrency(_computedPrice),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Small ledger items
          _buildReceiptRow('Product Name', _selectedProduct?.name ?? '—'),
          const SizedBox(height: 12),
          _buildReceiptRow('Unit Cost', _selectedProduct != null ? Helpers.formatCurrency(_selectedProduct!.sellingPrice) : '—'),
          const SizedBox(height: 12),
          _buildReceiptRow('Purchased Quantity', _quantityController.text),
          const SizedBox(height: 12),
          _buildReceiptRow('Fulfillment Channel', _fulfillmentType == 'WALKIN' ? 'Store Walk-In' : 'Rider Delivery'),
          const SizedBox(height: 32),

          // Save transaction button
          ElevatedButton.icon(
            onPressed: _submitOrder,
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('Finalize Customer Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusMedium)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper row builder inside invoice summary panel.
  Widget _buildReceiptRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(val, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
