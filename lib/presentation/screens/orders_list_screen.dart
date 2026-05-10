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

    // Detect if device viewport matches mobile dimensions (< 800 width)
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 800;
    final double paddingVal = isMobile ? 12.0 : 24.0;

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
        padding: EdgeInsets.all(paddingVal),
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

                  // Category Filter Choice Chips wrapped in horizontal scrollbar to prevent mobile overflow
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Main Ledger Database Output
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
                      : isMobile
                          // On mobile, render a stunning modern card list layout
                          ? ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = filteredOrders[index];
                                return _buildMobileOrderCard(order);
                              },
                            )
                          // On desktop, render a complete ledger details database grid
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
                                      ...filteredOrders.map((order) {
                                        return TableRow(
                                          decoration: const BoxDecoration(
                                            border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 1)),
                                          ),
                                          children: [
                                            TableCell(
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: InkWell(
                                                onTap: () => _showOrderDetailsModal(order),
                                                child: Padding(
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
                                              ),
                                            ),
                                            TableCell(
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: InkWell(
                                                onTap: () => _showOrderDetailsModal(order),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                                  child: Text(order.customerAddress, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: InkWell(
                                                onTap: () => _showOrderDetailsModal(order),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                                  child: Text(order.productName ?? '—', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: InkWell(
                                                onTap: () => _showOrderDetailsModal(order),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                                  child: Text(order.quantity.toString(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: InkWell(
                                                onTap: () => _showOrderDetailsModal(order),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                                                  child: Text(Helpers.formatCurrency(order.computedPrice), style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: InkWell(
                                                onTap: () => _showOrderDetailsModal(order),
                                                child: Padding(
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
                                              ),
                                            ),
                                            TableCell(
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: InkWell(
                                                onTap: () => _showOrderDetailsModal(order),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 14.0),
                                                  child: _buildStatusBadge(order.status),
                                                ),
                                              ),
                                            ),
                                            TableCell(
                                              verticalAlignment: TableCellVerticalAlignment.middle,
                                              child: Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                                                child: _buildActionsMenu(order),
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

  /// Opens an interactive modal ticket displaying high-fidelity breakdown details about the order items.
  void _showOrderDetailsModal(OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppStyles.radiusMedium)),
                border: Border.all(color: AppColors.surfaceLight, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppStyles.radiusMedium)),
                child: Column(
                  children: [
                    // Handle indicator
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Modal Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Transaction Ticket Detail', style: AppStyles.heading2),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: AppColors.surfaceLight, height: 1.0),
                    
                    // Main Scrollable Receipt
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20.0),
                        children: [
                          _buildReceiptMetadataItem('Customer Name', order.customerName, Icons.person_outline),
                          const SizedBox(height: 12),
                          _buildReceiptMetadataItem('Fulfillment Address', order.customerAddress, Icons.location_on_outlined),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildReceiptMetadataItem('Logistics Channel', order.fulfillmentType, Icons.local_shipping_outlined),
                              ),
                              if (order.deliveryRider != null && order.deliveryRider!.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildReceiptMetadataItem('Assigned Courier', order.deliveryRider!, Icons.sports_motorsports_outlined),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildReceiptMetadataItem('Transaction Date', Helpers.formatTimestamp(order.createdAt), Icons.calendar_today_outlined),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildReceiptMetadataItem('Current Status', order.status.toUpperCase(), Icons.info_outline, isStatus: true, statusVal: order.status),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          const Text('PRODUCTS LEDGER BREAKDOWN:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          const SizedBox(height: 10),
                          
                          // Items Listing
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.background.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                              border: Border.all(color: AppColors.surfaceLight, width: 1.0),
                            ),
                            child: Column(
                              children: [
                                // Table Header
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  color: AppColors.surfaceLight.withOpacity(0.4),
                                  child: const Row(
                                    children: [
                                      Expanded(flex: 3, child: Text('Product Item', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                                      Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                                      Expanded(flex: 2, child: Text('Unit Price', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                                      Expanded(flex: 2, child: Text('Subtotal', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                                    ],
                                  ),
                                ),
                                // Table Items
                                ...order.items.map((item) {
                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 0.5)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            item.productName ?? 'Product #${item.productId}',
                                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            item.quantity.toString(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            Helpers.formatCurrency(item.unitPrice),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            Helpers.formatCurrency(item.computedPrice),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                
                                // Grand Total Bottom Bar
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.05),
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('GRAND TOTAL BILLING', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5)),
                                      Text(
                                        Helpers.formatCurrency(order.totalPrice),
                                        style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.w900, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Builds individual metadata rows for ticket details
  Widget _buildReceiptMetadataItem(String label, String value, IconData icon, {bool isStatus = false, String? statusVal}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        border: Border.all(color: AppColors.surfaceLight, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                isStatus
                    ? Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusVal == 'COMPLETED'
                                  ? AppColors.success
                                  : statusVal == 'CANCELLED'
                                      ? AppColors.error
                                      : AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            value,
                            style: TextStyle(
                              color: statusVal == 'COMPLETED'
                                  ? AppColors.success
                                  : statusVal == 'CANCELLED'
                                      ? AppColors.error
                                      : statusVal == 'warning' ? AppColors.warning : AppColors.warning,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        value,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a detailed and visually stunning local ledger card optimized for touch targets on mobile.
  Widget _buildMobileOrderCard(OrderModel order) {
    return InkWell(
      onTap: () => _showOrderDetailsModal(order),
      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          border: Border.all(color: AppColors.surfaceLight.withOpacity(0.6), width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Customer profile and order status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.customerName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              Helpers.formatTimestamp(order.createdAt),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppColors.surfaceLight, height: 1.0),
            const SizedBox(height: 12),
  
            // 2. Product items and computed total price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.productName ?? "—",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  Helpers.formatCurrency(order.computedPrice),
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
  
            // 3. Logistics fulfillment channel with icons
            Row(
              children: [
                Icon(
                  order.fulfillmentType == 'DELIVERY' ? Icons.delivery_dining : Icons.storefront,
                  color: order.fulfillmentType == 'DELIVERY' ? AppColors.accent : AppColors.textSecondary,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  order.fulfillmentType,
                  style: TextStyle(
                    color: order.fulfillmentType == 'DELIVERY' ? AppColors.accent : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                if (order.deliveryRider != null && order.deliveryRider!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '• Rider: ${order.deliveryRider}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
  
            // 4. Physical contact address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.textMuted, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.customerAddress,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
  
            const SizedBox(height: 12),
            const Divider(color: AppColors.surfaceLight, height: 1.0),
            const SizedBox(height: 10),
  
            // 5. Tactile status switch controls tailored for direct mobile taps
            Row(
              children: [
                const Text(
                  'UPDATE STATE:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const Spacer(),
                _buildStatusActionButton(order, 'PENDING', Icons.pending_actions, AppColors.warning),
                const SizedBox(width: 8),
                _buildStatusActionButton(order, 'COMPLETED', Icons.check_circle_outline, AppColors.success),
                const SizedBox(width: 8),
                _buildStatusActionButton(order, 'CANCELLED', Icons.cancel_outlined, AppColors.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Renders a responsive status button that updates states with a single tap.
  Widget _buildStatusActionButton(OrderModel order, String status, IconData icon, Color color) {
    final bool isActive = order.status == status;
    return InkWell(
      onTap: isActive ? null : () => _updateStatus(order, status),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? color.withOpacity(0.5) : AppColors.surfaceLight.withOpacity(0.5),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? color : AppColors.textSecondary,
              size: 14,
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
