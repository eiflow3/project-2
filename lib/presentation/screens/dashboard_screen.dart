import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';
import '../../core/utils/helpers.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../widgets/glass_card.dart';

/// DashboardScreen is the default home widget showing analytics and store insights.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Rendered inside parent scaffold
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : RefreshIndicator(
              onRefresh: () async {
                await orderProvider.loadOrdersAndStats();
                await productProvider.loadProducts();
              },
              color: AppColors.primaryLight,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Workspace Dashboard', style: AppStyles.heading1),
                            SizedBox(height: 4),
                            Text('Summary of your offline business metrics and inventory health.', style: AppStyles.bodySecondary),
                          ],
                        ),
                        IconButton(
                          onPressed: () {
                            orderProvider.loadOrdersAndStats();
                            productProvider.loadProducts();
                          },
                          icon: const Icon(Icons.refresh_outlined, color: AppColors.primaryLight),
                          tooltip: 'Sync Local Data',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 1. Grid of Premium Metric Cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double cardWidth = (constraints.maxWidth - 32) / 3;
                        if (constraints.maxWidth < 750) {
                          // Column layout on thin windows
                          return Column(
                            children: [
                              _buildMetricCard(
                                title: 'Gross Revenue',
                                value: Helpers.formatCurrency(orderProvider.totalRevenue),
                                icon: Icons.attach_money,
                                gradient: AppColors.primaryGradient,
                              ),
                              _buildMetricCard(
                                title: 'Total Sales Count',
                                value: '${orderProvider.totalOrdersCount} orders',
                                icon: Icons.shopping_bag,
                                color: AppColors.accent,
                              ),
                              _buildMetricCard(
                                title: 'Pending Fulfilment',
                                value: '${orderProvider.pendingOrdersCount} orders',
                                icon: Icons.pending_actions,
                                color: AppColors.warning,
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Gross Revenue',
                                value: Helpers.formatCurrency(orderProvider.totalRevenue),
                                icon: Icons.attach_money,
                                gradient: AppColors.primaryGradient,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Total Sales Count',
                                value: '${orderProvider.totalOrdersCount} orders',
                                icon: Icons.shopping_bag,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Pending Fulfillment',
                                value: '${orderProvider.pendingOrdersCount} orders',
                                icon: Icons.pending_actions,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // 2. Mid Section (Top-Selling items and Quick Catalogue Stats)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 950) {
                          return Column(
                            children: [
                              _buildTopSellingTable(orderProvider),
                              const SizedBox(height: 24),
                              _buildInventoryHealthCard(productProvider),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: _buildTopSellingTable(orderProvider)),
                            const SizedBox(width: 24),
                            Expanded(flex: 2, child: _buildInventoryHealthCard(productProvider)),
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

  /// Helper widget builder for primary metrics summary.
  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    Gradient? gradient,
    Color? color,
  }) {
    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: gradient == null ? (color ?? AppColors.primary).withOpacity(0.1) : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: gradient == null ? (color ?? AppColors.primaryLight) : Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders a beautiful visual summary table of high-volume catalog items.
  Widget _buildTopSellingTable(OrderProvider orderProvider) {
    final list = orderProvider.topProducts;

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star_outline, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text('Top Performing Products', style: AppStyles.heading2),
            ],
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: const Text(
                'Complete store orders to generate insights.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),   // Product Name
                1: FlexColumnWidth(1.2), // Units Sold
                2: FlexColumnWidth(1.5), // Total Sales
              },
              children: [
                // Header row
                const TableRow(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 1.5)),
                  ),
                  children: [
                    Padding(padding: EdgeInsets.symmetric(vertical: 10.0), child: Text('Product', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 10.0), child: Text('Sold', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.symmetric(vertical: 10.0), child: Text('Revenue', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                // Data rows
                ...list.map((row) {
                  return TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.surfaceLight, width: 1)),
                    ),
                    children: [
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text(row['name'] as String, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text('${row['total_sold']} units', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: Text(Helpers.formatCurrency((row['total_revenue'] as num).toDouble()), style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13))),
                    ],
                  );
                }),
              ],
            ),
        ],
      ),
    );
  }

  /// Displays inventory stock details and triggers warn thresholds if products are out-of-stock.
  Widget _buildInventoryHealthCard(ProductProvider productProvider) {
    final list = productProvider.products;
    final int lowStockCount = list.where((p) => p.quantity < 5).length;
    final int outOfStockCount = list.where((p) => p.quantity == 0).length;

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text('Inventory Health', style: AppStyles.heading2),
            ],
          ),
          const SizedBox(height: 24),

          // Total listing count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Items', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text('${list.length} products', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceLight),
          const SizedBox(height: 12),

          // Low stock warning rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Low Stock Alerts (< 5 units)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: lowStockCount > 0 ? AppColors.warning.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$lowStockCount products',
                  style: TextStyle(
                    color: lowStockCount > 0 ? AppColors.warning : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.surfaceLight),
          const SizedBox(height: 12),

          // Out of stock warning rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Out-of-Stock Alerts', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: outOfStockCount > 0 ? AppColors.error.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$outOfStockCount products',
                  style: TextStyle(
                    color: outOfStockCount > 0 ? AppColors.error : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
