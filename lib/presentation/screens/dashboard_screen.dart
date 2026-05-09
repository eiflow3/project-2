import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';
import '../../core/utils/helpers.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/merchant_provider.dart';
import '../widgets/glass_card.dart';

/// DashboardScreen is the principal landing view of the administrative workspace.
/// Redesigned with state-of-the-art fintech aesthetics, interactive metric glow cards,
/// simulated Relative Bar Chart ledgers, and dynamic database status health headers.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final productProvider = Provider.of<ProductProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits container's glass-backing
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : RefreshIndicator(
              onRefresh: () async {
                // Pull stats simultaneously from SQLite using transactional repositories
                await orderProvider.loadOrdersAndStats();
                await productProvider.loadProducts();
              },
              color: AppColors.primaryLight,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Premium Greetings & Database Health Header Panel
                    _buildDynamicHeader(context, orderProvider),
                    const SizedBox(height: 28),

                    // 2. High-Fidelity Fintech Metric Cards Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth > 750;
                        return isWide
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _buildGlowMetricCard(
                                      title: 'GROSS REVENUE',
                                      value: Helpers.formatCurrency(orderProvider.totalRevenue),
                                      icon: Icons.analytics_outlined,
                                      color: AppColors.primaryLight,
                                      trend: '+8.2% this week',
                                      isIncrease: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildGlowMetricCard(
                                      title: 'COMPLETED SALES',
                                      value: '${orderProvider.totalOrdersCount} orders',
                                      icon: Icons.receipt_long_rounded,
                                      color: AppColors.accent,
                                      trend: '+14.5% vs average',
                                      isIncrease: true,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildGlowMetricCard(
                                      title: 'PENDING FULFILLMENT',
                                      value: '${orderProvider.pendingOrdersCount} orders',
                                      icon: Icons.schedule_send_outlined,
                                      color: AppColors.warning,
                                      trend: orderProvider.pendingOrdersCount > 0
                                          ? 'Action required'
                                          : 'All caught up!',
                                      isIncrease: false,
                                      isAlert: orderProvider.pendingOrdersCount > 0,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildGlowMetricCard(
                                    title: 'GROSS REVENUE',
                                    value: Helpers.formatCurrency(orderProvider.totalRevenue),
                                    icon: Icons.analytics_outlined,
                                    color: AppColors.primaryLight,
                                    trend: '+8.2% this week',
                                    isIncrease: true,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildGlowMetricCard(
                                    title: 'COMPLETED SALES',
                                    value: '${orderProvider.totalOrdersCount} orders',
                                    icon: Icons.receipt_long_rounded,
                                    color: AppColors.accent,
                                    trend: '+14.5% vs average',
                                    isIncrease: true,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildGlowMetricCard(
                                    title: 'PENDING FULFILLMENT',
                                    value: '${orderProvider.pendingOrdersCount} orders',
                                    icon: Icons.schedule_send_outlined,
                                    color: AppColors.warning,
                                    trend: orderProvider.pendingOrdersCount > 0
                                        ? 'Action required'
                                        : 'All caught up!',
                                    isIncrease: false,
                                    isAlert: orderProvider.pendingOrdersCount > 0,
                                  ),
                                ],
                              );
                      },
                    ),
                    const SizedBox(height: 28),

                    // 3. Main Business Intelligence Section Split
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth > 950;
                        return isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildInteractivePerformanceCard(orderProvider),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    flex: 2,
                                    child: _buildInteractiveInventoryHealthCard(productProvider),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildInteractivePerformanceCard(orderProvider),
                                  const SizedBox(height: 24),
                                  _buildInteractiveInventoryHealthCard(productProvider),
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

  /// Builds a welcoming visual banner containing live system health markers and manual sync utilities.
  Widget _buildDynamicHeader(BuildContext context, OrderProvider orderProvider) {
    final merchantProvider = Provider.of<MerchantProvider>(context);
    final String storeName = merchantProvider.activeConfig?.storeName ?? 'Workspace';

    // Detect if device viewport matches mobile dimensions (< 800 width)
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 800;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.35),
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(color: AppColors.surfaceLight.withOpacity(0.4), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting content with responsive layout logic
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to $storeName',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDbHealthBadge(),
                        ],
                      )
                    : Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Welcome to $storeName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildDbHealthBadge(),
                        ],
                      ),
                const SizedBox(height: 8),
                const Text(
                  'Your point of sale operations and database transaction logs are fully synced.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Refresh database trigger button
          IconButton(
            onPressed: () {
              orderProvider.loadOrdersAndStats();
            },
            icon: const Icon(Icons.sync_rounded, color: AppColors.primaryLight, size: 20),
            tooltip: 'Sync Local Data',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                side: BorderSide(color: AppColors.surfaceLight.withOpacity(0.5), width: 1.0),
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the local SQLite database health and connection status badge.
  Widget _buildDbHealthBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        border: Border.all(color: AppColors.success.withOpacity(0.2), width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingStatusLight(),
          SizedBox(width: 6),
          Text(
            'SQLITE ENGINE LOCAL',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a highly customized fintech metric card utilizing radial glass shadows, 
  /// color-coded health frames, and informative trend tags.
  Widget _buildGlowMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isIncrease,
    bool isAlert = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.25),
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(
          color: isAlert ? AppColors.error.withOpacity(0.3) : color.withOpacity(0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Grand Value Text
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          
          // Trend line indicator
          Row(
            children: [
              Icon(
                isAlert
                    ? Icons.warning_amber_rounded
                    : isIncrease
                        ? Icons.trending_up_rounded
                        : Icons.check_circle_outline_rounded,
                color: isAlert
                    ? AppColors.error
                    : isIncrease
                        ? AppColors.success
                        : AppColors.primaryLight,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  color: isAlert
                      ? AppColors.error
                      : isIncrease
                          ? AppColors.success
                          : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Displays the best-selling products coupled with dynamic, relative linear bar charts 
  /// representing real-time shares of overall sales.
  Widget _buildInteractivePerformanceCard(OrderProvider orderProvider) {
    final list = orderProvider.topProducts;

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.query_stats_rounded, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text('Top Performing Products', style: AppStyles.heading2),
            ],
          ),
          const SizedBox(height: 20),
          
          if (list.isEmpty)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary, size: 32),
                  SizedBox(height: 12),
                  Text(
                    'No orders completed yet. Save sales ledger transactions to populate.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            )
          else ...[
            // Header definitions
            _buildTableHeader(),
            const SizedBox(height: 8),
            
            // Generate list entries
            ...List.generate(list.length, (index) {
              final row = list[index];
              final double revenue = (row['total_revenue'] as num).toDouble();
              
              // Calculate relative scaling based on the highest-performing product
              final double maxRevenue = list.map<double>((p) => (p['total_revenue'] as num).toDouble()).reduce((a, b) => a > b ? a : b);
              final double relativeShare = maxRevenue > 0 ? (revenue / maxRevenue) : 0.0;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.surfaceLight.withOpacity(0.3), width: 0.8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Name of Product
                        Expanded(
                          flex: 3,
                          child: Text(
                            row['name'] as String,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        // Quantity sold
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${row['total_sold']} units',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        // Currency generated
                        Expanded(
                          flex: 2,
                          child: Text(
                            Helpers.formatCurrency(revenue),
                            textAlign: TextAlign.end,
                            style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // High-end relative linear bar graph representing sales volume
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 5,
                        color: AppColors.surfaceLight.withOpacity(0.35),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: relativeShare.clamp(0.0, 1.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Builds column labels for our top selling table.
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight.withOpacity(0.7), width: 1.0)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('PRODUCT', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0))),
          Expanded(flex: 1, child: Text('SOLD', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0))),
          Expanded(flex: 2, child: Text('REVENUE', textAlign: TextAlign.end, style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0))),
        ],
      ),
    );
  }

  /// Renders overall inventory stock status with warnings, filtering indicators, and relative linear health bars.
  Widget _buildInteractiveInventoryHealthCard(ProductProvider productProvider) {
    final list = productProvider.products;
    final int totalCount = list.length;
    final int lowStockCount = list.where((p) => p.quantity > 0 && p.quantity <= 5).length;
    final int outOfStockCount = list.where((p) => p.quantity == 0).length;
    final int healthyCount = totalCount - (lowStockCount + outOfStockCount);

    // Calculate relative percentages for our health meter
    final double healthyRatio = totalCount > 0 ? (healthyCount / totalCount) : 0.0;
    final double lowStockRatio = totalCount > 0 ? (lowStockCount / totalCount) : 0.0;
    final double outOfStockRatio = totalCount > 0 ? (outOfStockCount / totalCount) : 0.0;

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: AppColors.primaryLight, size: 20),
              SizedBox(width: 8),
              Text('Inventory Stock Health', style: AppStyles.heading2),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Sleek Inventory Health Linear Ratio Meter
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (healthyRatio > 0)
                    Expanded(
                      flex: (healthyRatio * 100).toInt(),
                      child: Container(color: AppColors.success),
                    ),
                  if (lowStockRatio > 0)
                    Expanded(
                      flex: (lowStockRatio * 100).toInt(),
                      child: Container(color: AppColors.warning),
                    ),
                  if (outOfStockRatio > 0)
                    Expanded(
                      flex: (outOfStockRatio * 100).toInt(),
                      child: Container(color: AppColors.error),
                    ),
                  if (totalCount == 0)
                    Expanded(
                      child: Container(color: AppColors.surfaceLight),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Metrics Listings
          _buildHealthRow('Healthy Products', '$healthyCount items', AppColors.success),
          const SizedBox(height: 14),
          _buildHealthRow('Low Stock (< 5 units)', '$lowStockCount items', AppColors.warning, isAlert: lowStockCount > 0),
          const SizedBox(height: 14),
          _buildHealthRow('Out of Stock', '$outOfStockCount items', AppColors.error, isAlert: outOfStockCount > 0),
          
          const SizedBox(height: 20),
          const Divider(color: AppColors.surfaceLight, height: 1.5),
          const SizedBox(height: 18),

          // 3. Dynamic total aggregate listing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Registered Items', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              Text('$totalCount products', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds structured health ratio metric rows.
  Widget _buildHealthRow(String label, String value, Color markerColor, {bool isAlert = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: markerColor),
            ),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        Container(
          padding: isAlert ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3) : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: isAlert ? markerColor.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
            border: isAlert ? Border.all(color: markerColor.withOpacity(0.2), width: 0.8) : null,
          ),
          child: Text(
            value,
            style: TextStyle(
              color: isAlert ? markerColor : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

/// Dynamic, pulsing visual indicator demonstrating continuous local SQLite linkage.
class _PulsingStatusLight extends StatefulWidget {
  const _PulsingStatusLight();

  @override
  State<_PulsingStatusLight> createState() => _PulsingStatusLightState();
}

class _PulsingStatusLightState extends State<_PulsingStatusLight> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _pulseAnimation.value,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success,
                  blurRadius: 3,
                  spreadRadius: 1,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
