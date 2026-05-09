import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/user_model.dart';
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
                const SizedBox(height: 8),
                // Danger Reset Application Button
                OutlinedButton.icon(
                  onPressed: () => _showResetDialog(context),
                  icon: const Icon(Icons.delete_forever_outlined, size: 16),
                  label: const Text('Reset Application', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withOpacity(0.5), width: 1.2),
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

  void _showResetDialog(BuildContext context) {
    // Controller to capture PIN/Password input
    final TextEditingController verifyController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false, // Force active choice to avoid accidental clicks
      builder: (BuildContext dialogContext) {
        UserModel? masterAccount;
        String? validationError;
        bool isLoadingMaster = true;

        return StatefulBuilder(
          builder: (context, setState) {
            // Load master account on first dialog build
            if (isLoadingMaster) {
              Provider.of<AuthProvider>(context, listen: false)
                  .getMasterAccount()
                  .then((user) {
                setState(() {
                  masterAccount = user;
                  isLoadingMaster = false;
                });
              });
            }

            return AlertDialog(
              backgroundColor: AppColors.surface,
              // Use precise Swiss style border matching our global theme refactor
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                side: const BorderSide(color: AppColors.surfaceLight, width: 1.0),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Confirm Reset Database',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This will permanently delete all sales ledgers, products catalogs, and administrative credentials. The application will be completely restored back to the clean first-time setup wizard.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    if (isLoadingMaster)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: CircularProgressIndicator(color: AppColors.primaryLight, strokeWidth: 2),
                        ),
                      )
                    else ...[
                      Text(
                        masterAccount?.authType == 'PIN'
                            ? 'Enter Administrator PIN to authorize:'
                            : 'Enter Administrator Password to authorize:',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: verifyController,
                        obscureText: true,
                        cursorColor: AppColors.primaryLight,
                        style: AppStyles.bodyPrimary,
                        keyboardType: masterAccount?.authType == 'PIN'
                            ? TextInputType.number
                            : TextInputType.text,
                        decoration: AppStyles.customInputDecoration(
                          labelText: masterAccount?.authType == 'PIN' ? 'Confirm PIN' : 'Confirm Password',
                          prefixIcon: masterAccount?.authType == 'PIN' ? Icons.dialpad : Icons.lock_outline,
                        ).copyWith(
                          errorText: validationError,
                          errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    verifyController.dispose();
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
                ElevatedButton(
                  onPressed: isLoadingMaster
                      ? null
                      : () async {
                          final input = verifyController.text;
                          if (input.isEmpty) {
                            setState(() {
                              validationError = masterAccount?.authType == 'PIN'
                                  ? 'Please enter your administrator PIN.'
                                  : 'Please enter your administrator password.';
                            });
                            return;
                          }

                          // Hash and verify credentials securely matching database entries
                          final inputHash = Helpers.hashSha256(input);
                          final correctHash = masterAccount?.authType == 'PIN'
                              ? masterAccount?.pinHash
                              : masterAccount?.passwordHash;

                          if (inputHash == correctHash) {
                            // Dispose first to avoid resource leaks
                            verifyController.dispose();
                            Navigator.of(dialogContext).pop();
                            
                            // Perform database deletion
                            await Provider.of<AuthProvider>(context, listen: false).resetApplication();
                            
                            // Notify user of successful database purge
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Application reset successfully! Database cleared.'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } else {
                            setState(() {
                              validationError = masterAccount?.authType == 'PIN'
                                  ? 'Incorrect administrative PIN.'
                                  : 'Incorrect administrative password.';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusSmall)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text(
                    'Reset Everything',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
