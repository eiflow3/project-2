import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';
import '../../providers/merchant_provider.dart';
import '../../providers/backup_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';

/// BrandSettingsScreen offers a dynamic white-label dashboard for store clients.
/// Users can configure their unique Store Name, Tagline, and choose from a set of gorgeous,
/// glowing brand emblems which write directly into SQLite.
class BrandSettingsScreen extends StatefulWidget {
  const BrandSettingsScreen({super.key});

  @override
  State<BrandSettingsScreen> createState() => _BrandSettingsScreenState();
}

class _BrandSettingsScreenState extends State<BrandSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _storeTaglineController = TextEditingController();
  
  String _selectedIconCode = 'STORE'; // Defaults to storefront
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate input controllers with the merchant provider's active SQLite state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
      if (merchantProvider.activeConfig != null) {
        setState(() {
          _storeNameController.text = merchantProvider.activeConfig!.storeName;
          _storeTaglineController.text = merchantProvider.activeConfig!.storeTagline;
          _selectedIconCode = merchantProvider.activeConfig!.storeIcon;
        });
      }
    });
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeTaglineController.dispose();
    super.dispose();
  }

  /// Saves the customized brand parameters to SQLite and alerts the reactive listeners.
  Future<void> _saveBranding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);

    bool success = await merchantProvider.updateBranding(
      _storeNameController.text.trim(),
      _storeTaglineController.text.trim(),
      _selectedIconCode,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('White-label store branding updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update branding config inside local SQLite.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // List of pre-selected high-end visual icon options for white labeling
    final List<Map<String, dynamic>> emblems = [
      {'code': 'STORE', 'label': 'Storefront', 'icon': Icons.storefront_rounded, 'color': Colors.blue},
      {'code': 'GAS', 'label': 'Gas & Fuel', 'icon': Icons.local_fire_department_rounded, 'color': Colors.orange},
      {'code': 'BAG', 'label': 'Shopping Bag', 'icon': Icons.shopping_bag_rounded, 'color': Colors.green},
      {'code': 'CART', 'label': 'Checkout Cart', 'icon': Icons.shopping_cart_rounded, 'color': Colors.purple},
      {'code': 'FOOD', 'label': 'Food & Drinks', 'icon': Icons.fastfood_rounded, 'color': Colors.pink},
      {'code': 'WATER', 'label': 'Pure Water', 'icon': Icons.water_drop_rounded, 'color': Colors.cyan},
    ];

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits smooth container gradients
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Title
              const Text('White-Label Branding', style: AppStyles.heading1),
              const SizedBox(height: 4),
              const Text(
                'Customize the application interface, names, and logos to match your client’s unique business brand.',
                style: AppStyles.bodySecondary,
              ),
              const SizedBox(height: 28),

              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 900;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Left Form Column
                      Expanded(
                        flex: isWide ? 5 : 8,
                        child: Column(
                          children: [
                            // Custom input card
                            GlassCard(
                              margin: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.edit_note_rounded, color: AppColors.primaryLight, size: 20),
                                      SizedBox(width: 8),
                                      Text('Brand Profile Configurations', style: AppStyles.heading2),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  CustomTextField(
                                    controller: _storeNameController,
                                    labelText: 'Client Store Name',
                                    prefixIcon: Icons.business_rounded,
                                    onChanged: (v) => setState(() {}), // Force instant preview repaint
                                    validator: (v) => v!.trim().isEmpty ? 'Store Name is required' : null,
                                  ),
                                  const SizedBox(height: 16),

                                  CustomTextField(
                                    controller: _storeTaglineController,
                                    labelText: 'Store Tagline / Operational Subtitle',
                                    prefixIcon: Icons.subtitles_rounded,
                                    onChanged: (v) => setState(() {}), // Force instant preview repaint
                                    validator: (v) => v!.trim().isEmpty ? 'Tagline is required' : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Emblem selection card
                            GlassCard(
                              margin: EdgeInsets.zero,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.palette_outlined, color: AppColors.primaryLight, size: 20),
                                      SizedBox(width: 8),
                                      Text('Select Brand Emblem', style: AppStyles.heading2),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.4,
                                    ),
                                    itemCount: emblems.length,
                                    itemBuilder: (context, index) {
                                      final item = emblems[index];
                                      final bool isSelected = _selectedIconCode == item['code'];
                                      final Color itemColor = item['color'] as Color;

                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _selectedIconCode = item['code'] as String;
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          decoration: BoxDecoration(
                                            color: isSelected ? itemColor.withOpacity(0.08) : AppColors.surface.withOpacity(0.25),
                                            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                                            border: Border.all(
                                              color: isSelected ? itemColor : AppColors.surfaceLight.withOpacity(0.5),
                                              width: isSelected ? 1.5 : 1.0,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                item['icon'] as IconData,
                                                color: isSelected ? itemColor : AppColors.textSecondary,
                                                size: 24,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                item['label'] as String,
                                                style: TextStyle(
                                                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Data Portability / Backup & Restore Card
                            Consumer<BackupProvider>(
                              builder: (context, backupProvider, child) {
                                return GlassCard(
                                  margin: EdgeInsets.zero,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.sync_rounded, color: AppColors.primaryLight, size: 20),
                                          SizedBox(width: 8),
                                          Text('Data Management & Backups', style: AppStyles.heading2),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Export or import your entire offline workspace (ledger records, products inventory, and custom branding settings) via compressed ZIP archives to easily migrate between devices.',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                      const SizedBox(height: 20),

                                      // Active feedback banner
                                      if (backupProvider.errorMessage != null)
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 16),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                                            border: Border.all(color: AppColors.error.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  backupProvider.errorMessage!,
                                                  style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close, color: AppColors.error, size: 16),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => backupProvider.clearMessages(),
                                              ),
                                            ],
                                          ),
                                        ),

                                      if (backupProvider.successMessage != null)
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 16),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 18),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  backupProvider.successMessage!,
                                                  style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.close, color: AppColors.success, size: 16),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                onPressed: () => backupProvider.clearMessages(),
                                              ),
                                            ],
                                          ),
                                        ),

                                      // Row of Actions
                                      Row(
                                        children: [
                                          // Export Action Button
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: backupProvider.isLoading
                                                  ? null
                                                  : () async {
                                                      await backupProvider.exportBackup();
                                                    },
                                              icon: backupProvider.isLoading
                                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                  : const Icon(Icons.backup_rounded, color: Colors.white, size: 16),
                                              label: const Text(
                                                'EXPORT ZIP BACKUP',
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppColors.primary,
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusMedium)),
                                                elevation: 0,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Import Action Button
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: backupProvider.isLoading
                                                  ? null
                                                  : () async {
                                                      bool success = await backupProvider.importBackup(() async {
                                                        // Callback to reload all providers on success
                                                        final mProv = Provider.of<MerchantProvider>(context, listen: false);
                                                        final pProv = Provider.of<ProductProvider>(context, listen: false);
                                                        final oProv = Provider.of<OrderProvider>(context, listen: false);
                                                        final aProv = Provider.of<AuthProvider>(context, listen: false);

                                                        await mProv.loadBranding();
                                                        await pProv.loadProducts();
                                                        await oProv.loadOrdersAndStats();
                                                        await aProv.checkInitialState();
                                                      });
                                                      
                                                      if (success && mounted) {
                                                        // Force state update to re-populate controllers with the imported config
                                                        final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);
                                                        if (merchantProvider.activeConfig != null) {
                                                          _storeNameController.text = merchantProvider.activeConfig!.storeName;
                                                          _storeTaglineController.text = merchantProvider.activeConfig!.storeTagline;
                                                          _selectedIconCode = merchantProvider.activeConfig!.storeIcon;
                                                          setState(() {});
                                                        }
                                                      }
                                                    },
                                              icon: const Icon(Icons.unarchive_rounded, color: AppColors.primaryLight, size: 16),
                                              label: const Text(
                                                'RESTORE ZIP BACKUP',
                                                style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: AppColors.primary, width: 1.0),
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusMedium)),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                                },
                              ),
                          ],
                        ),
                      ),

                      // 2. Right Real-Time Preview Ticket Column (Sidebar on wide views)
                      if (isWide) ...[
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: _buildRealTimePreview(emblems),
                        ),
                      ],
                    ],
                  );
                },
              ),

              // Bottom fallback panel for vertical screens
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 900;
                  if (!isWide) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: _buildRealTimePreview(emblems),
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

  /// Builds a live interactive rendering mock showing how the brand assets appear in widgets.
  Widget _buildRealTimePreview(List<Map<String, dynamic>> emblems) {
    // Lookup the active selected icon
    final activeEmblemMap = emblems.firstWhere(
      (e) => e['code'] == _selectedIconCode,
      orElse: () => emblems.first,
    );
    final IconData icon = activeEmblemMap['icon'] as IconData;
    final Color color = activeEmblemMap['color'] as Color;

    return GlassCard(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Interface Preview', style: AppStyles.heading2),
          const SizedBox(height: 20),

          // Mock sidebar header design
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              border: Border.all(color: AppColors.surfaceLight.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SIDEBAR PREVIEW',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.8), color],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _storeNameController.text.trim().isEmpty ? 'OrderFlow' : _storeNameController.text.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _storeTaglineController.text.trim().isEmpty ? 'OFFLINE SYSTEM' : _storeTaglineController.text.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Mock welcome card design matching preloading screen style
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              border: Border.all(color: color.withOpacity(0.25), width: 1.0),
            ),
            child: Column(
              children: [
                const Text(
                  'PRELOADER PREVIEW',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.08),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _storeNameController.text.trim().isEmpty ? 'OrderFlow' : _storeNameController.text.trim().toUpperCase(),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                ),
                const SizedBox(height: 4),
                Text(
                  _storeTaglineController.text.trim().isEmpty ? 'OFFLINE SYSTEM' : _storeTaglineController.text.trim().toUpperCase(),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Commit button
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveBranding,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check, color: Colors.white, size: 18),
            label: Text(
              _isSaving ? 'COMMITTING BRAND...' : 'APPLY BRAND IDENTITY',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusMedium)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
