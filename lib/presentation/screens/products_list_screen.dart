import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/product_model.dart';
import '../../providers/product_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';

/// ProductsListScreen enables management of stock inventory items.
/// Includes creation overlays, pricing adjustment modals, and custom-defined columns rendering.
class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Triggers dialog overlay to create or edit product parameters.
  void _showProductDialog({ProductModel? product}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) {
        return _ProductFormDialog(product: product);
      },
    );
  }

  /// Submits delete request. Handles DB exceptions on restricted links.
  Future<void> _deleteProduct(ProductModel product) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Product?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      bool success = await provider.removeProduct(product.id!);
      
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? "Cannot delete. Linked orders active."),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted successfully.'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);

    // Filter catalogue list based on search keywords
    final String query = _searchController.text.toLowerCase();
    final List<ProductModel> filteredProducts = productProvider.products.where((p) {
      return p.name.toLowerCase().contains(query) ||
          p.extraColumns.values.any((val) => val.toString().toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header configuration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Inventory Catalogue', style: AppStyles.heading1),
                    SizedBox(height: 4),
                    Text('Manage your core product listings, update costs, pricing and inspect current stocks.', style: AppStyles.bodySecondary),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showProductDialog(),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text('Add New Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusSmall)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search filtering inputs
            GlassCard(
              margin: EdgeInsets.zero,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {}),
                      style: AppStyles.bodyPrimary,
                      cursorColor: AppColors.primaryLight,
                      decoration: InputDecoration(
                        hintText: 'Search product names or custom attributes...',
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Products list table
            Expanded(
              child: productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.surfaceLight),
                              const SizedBox(height: 16),
                              const Text('No products matching query found.', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : Container(
                          decoration: AppStyles.glassCardDecoration(),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                            child: SingleChildScrollView(
                              child: Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(2.5), // Name + custom cols
                                  1: FlexColumnWidth(1.2), // Cost (Capital)
                                  2: FlexColumnWidth(1.2), // Price (Retail)
                                  3: FlexColumnWidth(1.0), // Margin profit
                                  4: FlexColumnWidth(1.0), // Stock Qty
                                  5: FlexColumnWidth(1.2), // Actions
                                },
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(color: AppColors.surfaceLight),
                                    children: [
                                      _buildTableHeader('Product Details'),
                                      _buildTableHeader('Cost (Capital)'),
                                      _buildTableHeader('Selling Price'),
                                      _buildTableHeader('Profit Margin'),
                                      _buildTableHeader('Stock Qty'),
                                      _buildTableHeader('Actions'),
                                    ],
                                  ),
                                  ...filteredProducts.map((product) {
                                    final double profit = product.sellingPrice - product.unitCost;
                                    final bool isLowStock = product.quantity < 5;
                                    final bool isOutOfStock = product.quantity == 0;

                                    return TableRow(
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 1)),
                                      ),
                                      children: [
                                        // Product details & Custom Columns details
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(product.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                              if (product.extraColumns.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  product.extraColumns.entries.map((e) => '${e.key}: ${e.value}').join(' | '),
                                                  style: const TextStyle(color: AppColors.primaryLight, fontSize: 11),
                                                )
                                              ]
                                            ],
                                          ),
                                        ),
                                        // Cost
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                          child: Text(Helpers.formatCurrency(product.unitCost), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                        ),
                                        // Price
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                          child: Text(Helpers.formatCurrency(product.sellingPrice), style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                        // Profit margin markup
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                          child: Text('+${Helpers.formatCurrency(profit)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13)),
                                        ),
                                        // Stock Quantity alert
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                          child: Row(
                                            children: [
                                              Text(product.quantity.toString(), style: TextStyle(color: isOutOfStock ? AppColors.error : (isLowStock ? AppColors.warning : AppColors.textPrimary), fontWeight: FontWeight.bold, fontSize: 13)),
                                              if (isOutOfStock) ...[
                                                const SizedBox(width: 6),
                                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(4)), child: const Text('OUT', style: TextStyle(color: AppColors.error, fontSize: 8, fontWeight: FontWeight.bold))),
                                              ] else if (isLowStock) ...[
                                                const SizedBox(width: 6),
                                                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.warning.withOpacity(0.12), borderRadius: BorderRadius.circular(4)), child: const Text('LOW', style: TextStyle(color: AppColors.warning, fontSize: 8, fontWeight: FontWeight.bold))),
                                              ]
                                            ],
                                          ),
                                        ),
                                        // Actions Trigger Buttons
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_note, color: AppColors.primaryLight, size: 20),
                                                onPressed: () => _showProductDialog(product: product),
                                                tooltip: 'Edit Parameters',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                                onPressed: () => _deleteProduct(product),
                                                tooltip: 'Remove Listing',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList()
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header table helper.
  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Modal Pop-up form managing Product addition and editing fields.
class _ProductFormDialog extends StatefulWidget {
  final ProductModel? product;

  const _ProductFormDialog({this.product});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _costController;
  late TextEditingController _priceController;
  late TextEditingController _qtyController;

  final List<MapEntry<TextEditingController, TextEditingController>> _customColumnControllers = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _costController = TextEditingController(text: widget.product?.unitCost.toString() ?? '');
    _priceController = TextEditingController(text: widget.product?.sellingPrice.toString() ?? '');
    _qtyController = TextEditingController(text: widget.product?.quantity.toString() ?? '1');

    // Load any existing custom column keys
    if (widget.product != null) {
      widget.product!.extraColumns.forEach((key, val) {
        _customColumnControllers.add(
          MapEntry(TextEditingController(text: key), TextEditingController(text: val.toString())),
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _costController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    for (var pair in _customColumnControllers) {
      pair.key.dispose();
      pair.value.dispose();
    }
    super.dispose();
  }

  void _addCustomColumn() {
    setState(() {
      _customColumnControllers.add(MapEntry(TextEditingController(), TextEditingController()));
    });
  }

  void _removeCustomColumn(int index) {
    setState(() {
      final pair = _customColumnControllers.removeAt(index);
      pair.key.dispose();
      pair.value.dispose();
    });
  }

  /// Processes edits or creations and dispatches back to ProductProvider.
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final String name = _nameController.text.trim();
    final double cost = double.parse(_costController.text);
    final double price = double.parse(_priceController.text);
    final int qty = int.parse(_qtyController.text);

    final Map<String, dynamic> extraColumns = {};
    for (var pair in _customColumnControllers) {
      final String k = pair.key.text.trim();
      final String v = pair.value.text.trim();
      if (k.isNotEmpty && v.isNotEmpty) {
        extraColumns[k] = v;
      }
    }

    final provider = Provider.of<ProductProvider>(context, listen: false);
    bool success;

    if (widget.product == null) {
      // Process Creation
      success = await provider.addProduct(
        ProductModel(
          name: name,
          unitCost: cost,
          sellingPrice: price,
          quantity: qty,
          extraColumns: extraColumns,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    } else {
      // Process Edit
      success = await provider.editProduct(
        ProductModel(
          id: widget.product!.id,
          name: name,
          unitCost: cost,
          sellingPrice: price,
          quantity: qty,
          extraColumns: extraColumns,
          createdAt: widget.product!.createdAt,
        ),
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.product == null ? 'Product added successfully!' : 'Product updated successfully!'), backgroundColor: AppColors.success),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'An error occurred during submission.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.product != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 680),
        decoration: AppStyles.glassCardDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          child: Column(
            children: [
              // Header title
              Container(
                color: AppColors.surfaceLight,
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isEdit ? 'Edit Product Parameters' : 'Register New Product', style: AppStyles.heading2),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: AppColors.textSecondary)),
                  ],
                ),
              ),

              // Form fields
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: _nameController,
                          labelText: 'Product Name',
                          prefixIcon: Icons.shopping_bag_outlined,
                          validator: (v) => v!.trim().isEmpty ? 'Name required' : null,
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _costController,
                                labelText: 'Unit Cost (Capital)',
                                prefixIcon: Icons.money,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) => v!.isEmpty || double.tryParse(v) == null ? 'Enter valid cost' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _priceController,
                                labelText: 'Selling Price (Retail)',
                                prefixIcon: Icons.sell_outlined,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) => v!.isEmpty || double.tryParse(v) == null ? 'Enter valid price' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        CustomTextField(
                          controller: _qtyController,
                          labelText: 'Current Stock Quantity',
                          prefixIcon: Icons.inventory_2_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty || int.tryParse(v) == null ? 'Enter whole quantity number' : null,
                        ),
                        const SizedBox(height: 24),

                        // Custom columns sub-section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Dynamic Column Attributes', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                            TextButton.icon(onPressed: _addCustomColumn, icon: const Icon(Icons.add, size: 14), label: const Text('Add Attribute', style: TextStyle(fontSize: 11))),
                          ],
                        ),
                        const SizedBox(height: 8),

                        ...List.generate(_customColumnControllers.length, (index) {
                          final pair = _customColumnControllers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(child: CustomTextField(controller: pair.key, labelText: 'Property', prefixIcon: Icons.label_outline, validator: (v) => v!.isEmpty ? 'Enter key' : null)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_right_alt, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(child: CustomTextField(controller: pair.value, labelText: 'Value', prefixIcon: Icons.description_outlined, validator: (v) => v!.isEmpty ? 'Enter value' : null)),
                                IconButton(icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 18), onPressed: () => _removeCustomColumn(index)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),

              // Action buttons footer
              Container(
                padding: const EdgeInsets.all(20),
                color: AppColors.background.withOpacity(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.surfaceLight), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusSmall))),
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Text('Cancel', style: TextStyle(fontSize: 13))),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusSmall))),
                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
