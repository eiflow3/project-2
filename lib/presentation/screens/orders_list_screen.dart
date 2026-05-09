import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../widgets/glass_card.dart';

/// OrdersListScreen renders a table/ledger of all processed sales transactions.
/// It provides advanced searching, category filtering, and in-place status adjustments.
class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'ALL'; // 'ALL', 'PENDING', 'COMPLETED', 'CANCELLED'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Evaluates status change requests in the order list.
  /// Cancelling an order automatically updates product inventory quantities.
  Future<void> _updateStatus(OrderModel order, String newStatus) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    bool success = await orderProvider.changeOrderStatus(order.id!, newStatus, () {
      productProvider.loadProducts(); // Restock reload trigger
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order Status updated to $newStatus successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update status.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    // Filter list based on search key and chip selectors
    final String query = _searchController.text.toLowerCase();
    final List<OrderModel> filteredOrders = orderProvider.orders.where((order) {
      final bool matchesSearch = order.customerName.toLowerCase().contains(query) ||
          order.customerAddress.toLowerCase().contains(query) ||
          (order.productName?.toLowerCase().contains(query) ?? false) ||
          (order.deliveryRider?.toLowerCase().contains(query) ?? false);

      final bool matchesStatus = _statusFilter == 'ALL' || order.status == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Description
            const Text('Order History Ledger', style: AppStyles.heading1),
            const SizedBox(height: 4),
            const Text('Audit and adjust status records of all customer logs in local memory.', style: AppStyles.bodySecondary),
            const SizedBox(height: 24),

            // 1. Live Filter and Search Options Card
            GlassCard(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  Row(
                    children: [
                      // Active search bar
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() {}),
                          style: AppStyles.bodyPrimary,
                          cursorColor: AppColors.primaryLight,
                          decoration: InputDecoration(
                            hintText: 'Search by Customer, Address, Product or Rider...',
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
                      const SizedBox(width: 16),
                      // Export summary placeholder if desired, or clear search button
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear_all, color: AppColors.textSecondary),
                        tooltip: 'Clear Filters',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category Filter Choice Chips
                  Row(
                    children: [
                      const Text('Filter Status:', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      _buildFilterChip('ALL', 'All Logged'),
                      const SizedBox(width: 8),
                      _buildFilterChip('PENDING', 'Pending Payment', badgeColor: AppColors.warning),
                      const SizedBox(width: 8),
                      _buildFilterChip('COMPLETED', 'Completed Sales', badgeColor: AppColors.success),
                      const SizedBox(width: 8),
                      _buildFilterChip('CANCELLED', 'Cancelled Voided', badgeColor: AppColors.error),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Main Ledger Database Table Output
            Expanded(
              child: orderProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                  : filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.surfaceLight),
                              const SizedBox(height: 16),
                              const Text('No transaction matching filters found.', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Place a new customer order to populate logs.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                        )
                      : Container(
                          decoration: AppStyles.glassCardDecoration(),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(1.8), // Customer
                                  1: FlexColumnWidth(2.2), // Address/Contact
                                  2: FlexColumnWidth(1.8), // Product Alias
                                  3: FlexColumnWidth(1.0), // Qty
                                  4: FlexColumnWidth(1.5), // Pricing
                                  5: FlexColumnWidth(1.5), // Fulfillment/Rider
                                  6: FlexColumnWidth(1.4), // Status Badge
                                  7: FlexColumnWidth(1.4), // Actions Selector
                                },
                                children: [
                                  // Table Header Row
                                  TableRow(
                                    decoration: const BoxDecoration(
                                      color: AppColors.surfaceLight,
                                    ),
                                    children: [
                                      _buildTableHeader('Customer Name'),
                                      _buildTableHeader('Address'),
                                      _buildTableHeader('Product'),
                                      _buildTableHeader('Qty'),
                                      _buildTableHeader('Computed Price'),
                                      _buildTableHeader('Fulfillment'),
                                      _buildTableHeader('Status'),
                                      _buildTableHeader('Actions'),
                                    ],
                                  ),
                                  // Table Rows mapping elements
                                  ...filteredOrders.map((order) {
                                    return TableRow(
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 1)),
                                      ),
                                      children: [
                                        // Customer Name & Timestamp
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(order.customerName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                                              const SizedBox(height: 4),
                                              Text(Helpers.formatTimestamp(order.createdAt), style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                        // Customer Address
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                          child: Text(order.customerAddress, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        ),
                                        // Product Name
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                          child: Text(order.productName ?? '—', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                                        ),
                                        // Quantity
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                          child: Text(order.quantity.toString(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                        ),
                                        // Price
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                          child: Text(Helpers.formatCurrency(order.computedPrice), style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                        // Fulfillment Channel
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(order.fulfillmentType, style: TextStyle(color: order.fulfillmentType == 'DELIVERY' ? AppColors.accent : AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11)),
                                              if (order.deliveryRider != null && order.deliveryRider!.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text('Rider: ${order.deliveryRider}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                              ]
                                            ],
                                          ),
                                        ),
                                        // Status badge
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 14.0),
                                          child: _buildStatusBadge(order.status),
                                        ),
                                        // Quick actions popup menu
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                          child: _buildActionsMenu(order),
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

  /// Builds individual chips for header searches.
  Widget _buildFilterChip(String value, String label, {Color? badgeColor}) {
    final bool isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _statusFilter = value);
      },
      selectedColor: (badgeColor ?? AppColors.primary).withOpacity(0.15),
      backgroundColor: Colors.transparent,
      side: BorderSide(color: isSelected ? (badgeColor ?? AppColors.primaryLight) : AppColors.surfaceLight),
      labelStyle: TextStyle(color: isSelected ? (badgeColor ?? AppColors.primaryLight) : AppColors.textSecondary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
  }

  /// Helper header cell builder for Ledger Table layout.
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

  /// Returns a clean visual status tag with appropriate semantic coloring.
  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'COMPLETED':
        color = AppColors.success;
        label = 'Completed';
        break;
      case 'CANCELLED':
        color = AppColors.error;
        label = 'Cancelled';
        break;
      case 'PENDING':
      default:
        color = AppColors.warning;
        label = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Dropdown popup buttons allowing active order status adjustment.
  Widget _buildActionsMenu(OrderModel order) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
      color: AppColors.surface,
      tooltip: 'Modify Order State',
      onSelected: (newStatus) => _updateStatus(order, newStatus),
      itemBuilder: (context) {
        return [
          if (order.status != 'PENDING')
            const PopupMenuItem(
              value: 'PENDING',
              child: Row(
                children: [
                  Icon(Icons.pending_actions, color: AppColors.warning, size: 16),
                  SizedBox(width: 8),
                  Text('Set Pending', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                ],
              ),
            ),
          if (order.status != 'COMPLETED')
            const PopupMenuItem(
              value: 'COMPLETED',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                  SizedBox(width: 8),
                  Text('Mark Complete', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                ],
              ),
            ),
          if (order.status != 'CANCELLED')
            const PopupMenuItem(
              value: 'CANCELLED',
              child: Row(
                children: [
                  Icon(Icons.cancel_outlined, color: AppColors.error, size: 16),
                  SizedBox(width: 8),
                  Text('Cancel (Void)', style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                ],
              ),
            ),
        ];
      },
    );
  }
}
