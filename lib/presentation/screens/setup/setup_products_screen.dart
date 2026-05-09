import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/style.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_text_field.dart';

/// SetupProductsScreen allows merchants to register their inventory items during first-time launch.
/// It supports dynamic custom columns (weight, color, etc.) using key-value pair forms,
/// presenting additions in a live staging table before executing a SQL batch insert.
class SetupProductsScreen extends StatefulWidget {
  const SetupProductsScreen({super.key});

  @override
  State<SetupProductsScreen> createState() => _SetupProductsScreenState();
}

class _SetupProductsScreenState extends State<SetupProductsScreen> {
  final _productFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  // Staged products waiting for SQLite database bulk write
  final List<ProductModel> _stagedProducts = [];

  // Dynamic Custom Column Fields Stage
  final List<MapEntry<TextEditingController, TextEditingController>> _customColumnControllers = [];

  @override
  void dispose() {
    _nameController.dispose();
    _unitCostController.dispose();
    _sellingPriceController.dispose();
    _quantityController.dispose();
    for (var entry in _customColumnControllers) {
      entry.key.dispose();
      entry.value.dispose();
    }
    super.dispose();
  }

  /// Adds a new custom column key-value staging input.
  void _addCustomColumn() {
    setState(() {
      _customColumnControllers.add(
        MapEntry(TextEditingController(), TextEditingController()),
      );
    });
  }

  /// Removes a custom column staging input.
  void _removeCustomColumn(int index) {
    setState(() {
      final entry = _customColumnControllers.removeAt(index);
      entry.key.dispose();
      entry.value.dispose();
    });
  }

  /// Validates the form and pushes a compiled ProductModel into our [_stagedProducts] list.
  void _stageProduct() {
    if (!_productFormKey.currentState!.validate()) return;

    final String name = _nameController.text.trim();
    final double unitCost = double.parse(_unitCostController.text);
    final double sellingPrice = double.parse(_sellingPriceController.text);
    final int quantity = int.parse(_quantityController.text);

    // Build the dynamic custom attributes map from user controllers
    final Map<String, dynamic> extraColumns = {};
    for (var controllerPair in _customColumnControllers) {
      final String key = controllerPair.key.text.trim();
      final String val = controllerPair.value.text.trim();
      if (key.isNotEmpty && val.isNotEmpty) {
        extraColumns[key] = val;
      }
    }

    setState(() {
      _stagedProducts.add(
        ProductModel(
          name: name,
          unitCost: unitCost,
          sellingPrice: sellingPrice,
          quantity: quantity,
          extraColumns: extraColumns,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      // Clear standard controllers for the next product entry
      _nameController.clear();
      _unitCostController.clear();
      _sellingPriceController.clear();
      _quantityController.text = '1';
      
      // Clear and release memory of dynamic attribute controllers
      for (var entry in _customColumnControllers) {
        entry.key.dispose();
        entry.value.dispose();
      }
      _customColumnControllers.clear();
    });
  }

  /// Submits the staged product array to our SQLite DB via the ProductProvider.
  /// On completion, re-evaluates AuthProvider state to unlock the application panel.
  Future<void> _completeSetup() async {
    if (_stagedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please stage at least one product to finalize database setup."),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    bool success = await productProvider.setupInitialProducts(_stagedProducts);

    if (success && mounted) {
      // Setup complete! Since we added products, we reload the parent widgets
      // which will trigger the AuthStatus checker, transitioning to authenticated!
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(productProvider.errorMessage ?? "Failed to finalize database setup."),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Hand Panel: Form to input products (Scrollable)
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Step 2 of 2',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Populate Catalog',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Stage Your Products', style: AppStyles.heading1),
                  const SizedBox(height: 8),
                  const Text(
                    'Add products that you currently sell. You can specify names, costs, selling prices, stock quantities, and even add custom dynamic attributes (like Size, Color, or Category) on the fly.',
                    style: AppStyles.bodySecondary,
                  ),
                  const SizedBox(height: 32),

                  Form(
                    key: _productFormKey,
                    child: GlassCard(
                      padding: const EdgeInsets.all(24.0),
                      margin: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Product Details', style: AppStyles.heading2),
                          const SizedBox(height: 24),

                          CustomTextField(
                            controller: _nameController,
                            labelText: 'Product Name (e.g. Classic T-Shirt)',
                            prefixIcon: Icons.shopping_bag_outlined,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Product name is required.';
                              }
                              // Prevent duplicates in staged list
                              if (_stagedProducts.any((p) => p.name.toLowerCase() == val.trim().toLowerCase())) {
                                return 'A product with this name is already staged.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: CustomTextField(
                                  controller: _unitCostController,
                                  labelText: 'Unit Cost (Capital)',
                                  prefixIcon: Icons.money,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Cost is required.';
                                    if (double.tryParse(val) == null) return 'Must be numeric.';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: CustomTextField(
                                  controller: _sellingPriceController,
                                  labelText: 'Selling Price (Retail)',
                                  prefixIcon: Icons.sell_outlined,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Price is required.';
                                    if (double.tryParse(val) == null) return 'Must be numeric.';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          CustomTextField(
                            controller: _quantityController,
                            labelText: 'Stated Stock Quantity (Default to 1)',
                            prefixIcon: Icons.inventory_2_outlined,
                            keyboardType: TextInputType.number,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Quantity is required.';
                              if (int.tryParse(val) == null) return 'Must be a whole number.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Dynamic Column Attributes Form
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Custom Attributes (Optional)',
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              TextButton.icon(
                                onPressed: _addCustomColumn,
                                icon: const Icon(Icons.add, size: 16, color: AppColors.primaryLight),
                                label: const Text('Add Column', style: TextStyle(fontSize: 12, color: AppColors.primaryLight)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_customColumnControllers.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: AppColors.background.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                              ),
                              child: const Text(
                                'No custom columns added. Click "Add Column" to record custom data (e.g. Color: Blue, Size: XL).',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ),

                          // Render dynamic row controller elements
                          ...List.generate(_customColumnControllers.length, (index) {
                            final controllers = _customColumnControllers[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      controller: controllers.key,
                                      labelText: 'Property (e.g. Size)',
                                      prefixIcon: Icons.label_outline,
                                      validator: (v) => v!.isEmpty ? 'Enter key' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_right_alt, color: AppColors.textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomTextField(
                                      controller: controllers.value,
                                      labelText: 'Value (e.g. Large)',
                                      prefixIcon: Icons.description_outlined,
                                      validator: (v) => v!.isEmpty ? 'Enter value' : null,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                                    onPressed: () => _removeCustomColumn(index),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 32),

                          // Add Product to Staging Table Button
                          OutlinedButton.icon(
                            onPressed: _stageProduct,
                            icon: const Icon(Icons.playlist_add, size: 20),
                            label: const Text('Stage Product in List', style: TextStyle(fontSize: 14)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryLight,
                              side: const BorderSide(color: AppColors.primary),
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Divider Line
          const VerticalDivider(color: AppColors.surfaceLight, width: 1),

          // Right Hand Panel: Live Staging Table and Setup Actions
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(32.0),
              color: AppColors.surface.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Staged Catalog List', style: AppStyles.heading2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_stagedProducts.length} Items Staged',
                          style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Products Staged Table
                  Expanded(
                    child: _stagedProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.surfaceLight),
                                const SizedBox(height: 16),
                                const Text(
                                  'Your staged catalogue is empty.',
                                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Fill in the product details on the left and click\n"Stage Product in List" to build your inventory catalog.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
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
                                    0: FlexColumnWidth(3), // Name
                                    1: FlexColumnWidth(1.5), // Cost
                                    2: FlexColumnWidth(1.5), // Retail
                                    3: FlexColumnWidth(1.2), // Qty
                                    4: FlexColumnWidth(1), // Actions
                                  },
                                  children: [
                                    // Table Header Row
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        color: AppColors.surfaceLight,
                                      ),
                                      children: [
                                        _buildTableHeader('Name'),
                                        _buildTableHeader('Cost'),
                                        _buildTableHeader('Retail'),
                                        _buildTableHeader('Stock'),
                                        _buildTableHeader(''),
                                      ],
                                    ),
                                    // Table Body Rows
                                    ...List.generate(_stagedProducts.length, (index) {
                                      final product = _stagedProducts[index];
                                      return TableRow(
                                        decoration: const BoxDecoration(
                                          border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 1)),
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(product.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                                if (product.extraColumns.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 4.0),
                                                    child: Text(
                                                      product.extraColumns.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                                                      style: const TextStyle(color: AppColors.primaryLight, fontSize: 10),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  )
                                              ],
                                            ),
                                          ),
                                          Padding(padding: const EdgeInsets.all(12.0), child: Text(Helpers.formatCurrency(product.unitCost), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                                          Padding(padding: const EdgeInsets.all(12.0), child: Text(Helpers.formatCurrency(product.sellingPrice), style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13))),
                                          Padding(padding: const EdgeInsets.all(12.0), child: Text(product.quantity.toString(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                            onPressed: () => setState(() => _stagedProducts.removeAt(index)),
                                          ),
                                        ],
                                      );
                                    })
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _completeSetup,
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'Save & Initialize Application',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Helper header cell builder for Table layout.
  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
