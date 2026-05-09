import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';
import '../../providers/auth_provider.dart';

/// NavigationSidebar is the primary menu layout for desktop viewports.
/// It displays the brand logo, lists accessible workspace panels, shows the logged-in
/// user profile card, and features a logout action.
class NavigationSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const NavigationSidebar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String username = authProvider.currentUser?.username ?? 'Admin';

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.surface, // Distinct card-like panel
        border: Border(
          right: BorderSide(color: AppColors.surfaceLight, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // 1. Premium Application Brand Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'OrderFlow',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'OFFLINE SYSTEM',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(color: AppColors.surfaceLight, height: 1),
          const SizedBox(height: 16),

          // 2. Main Navigation Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              children: [
                _buildMenuItem(
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  title: 'Dashboard',
                ),
                _buildMenuItem(
                  index: 1,
                  icon: Icons.add_shopping_cart_outlined,
                  activeIcon: Icons.add_shopping_cart,
                  title: 'New Order',
                ),
                _buildMenuItem(
                  index: 2,
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  title: 'Order Ledger',
                ),
                _buildMenuItem(
                  index: 3,
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  title: 'Inventory',
                ),
              ],
            ),
          ),

          // 3. Authenticated Admin Profile Card & Logout Section
          const Divider(color: AppColors.surfaceLight, height: 1),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Minimal profile card
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.surfaceLight,
                      child: Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Text(
                            'Administrator',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Smooth Logout Button
                OutlinedButton.icon(
                  onPressed: () => authProvider.logout(),
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Lock Session', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.surfaceLight),
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Helper widget builder representing a single navigation list option.
  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String title,
  }) {
    final bool isActive = currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: () => onTabSelected(index),
        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
        child: Ink(
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? AppColors.primaryLight : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
