import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/style.dart';
import '../../../providers/merchant_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_text_field.dart';
import 'setup_admin_screen.dart';

/// SetupBrandingScreen is Step 1 of the new 3-Step Setup Wizard.
/// It enables clients to fully white-label and customize the interface
/// (Store Name, tagline, and brand logo) before configuring their login credentials.
class SetupBrandingScreen extends StatefulWidget {
  const SetupBrandingScreen({super.key});

  @override
  State<SetupBrandingScreen> createState() => _SetupBrandingScreenState();
}

class _SetupBrandingScreenState extends State<SetupBrandingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _storeTaglineController = TextEditingController();

  String _selectedIconCode = 'STORE'; // Default selected brand logo
  bool _isSaving = false;

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeTaglineController.dispose();
    super.dispose();
  }

  /// Registers user's chosen white-label branding configurations to local SQLite.
  Future<void> _submitBranding() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final merchantProvider = Provider.of<MerchantProvider>(context, listen: false);

    // Save configurations to local DB
    bool success = await merchantProvider.updateBranding(
      _storeNameController.text.trim(),
      _storeTaglineController.text.trim(),
      _selectedIconCode,
    );

    setState(() => _isSaving = false);

    if (success) {
      if (mounted) {
        // Update the global onboarding step context to transition smoothly to Step 2
        Provider.of<AuthProvider>(context, listen: false).setOnboardingStep(2);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to initialize store configurations in local SQLite.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    // Emblem options matching brand settings screen configuration
    final List<Map<String, dynamic>> emblems = [
      {'code': 'STORE', 'label': 'Storefront', 'icon': Icons.storefront_rounded, 'color': Colors.blue},
      {'code': 'GAS', 'label': 'Gas & Fuel', 'icon': Icons.local_fire_department_rounded, 'color': Colors.orange},
      {'code': 'BAG', 'label': 'Shopping Bag', 'icon': Icons.shopping_bag_rounded, 'color': Colors.green},
      {'code': 'CART', 'label': 'Checkout Cart', 'icon': Icons.shopping_cart_rounded, 'color': Colors.purple},
      {'code': 'FOOD', 'label': 'Food & Drinks', 'icon': Icons.fastfood_rounded, 'color': Colors.pink},
      {'code': 'WATER', 'label': 'Pure Water', 'icon': Icons.water_drop_rounded, 'color': Colors.cyan},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Sleek 3-Step Wizard Progress Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                        ),
                        child: const Text(
                          'Step 1 of 3',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Store Identity & White-labeling',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Twin Panel Design Layout
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth > 750;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Form Inputs Card (Left Panel)
                          Expanded(
                            flex: isWide ? 5 : 8,
                            child: Column(
                              children: [
                                GlassCard(
                                  padding: const EdgeInsets.all(24.0),
                                  margin: EdgeInsets.zero,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Configure Your Brand',
                                        style: AppStyles.heading1,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Let\'s build your customized offline platform. Type in your store name and select a beautiful branding emblem below.',
                                        style: AppStyles.bodySecondary,
                                      ),
                                      const SizedBox(height: 24),

                                      // Store Name Input
                                      CustomTextField(
                                        controller: _storeNameController,
                                        labelText: 'Store Name',
                                        prefixIcon: Icons.business_rounded,
                                        onChanged: (_) => setState(() {}), // Force real-time preview sync
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'Store name is required.';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),

                                      // Store Tagline Input
                                      CustomTextField(
                                        controller: _storeTaglineController,
                                        labelText: 'Store Tagline / Subtitle',
                                        prefixIcon: Icons.subtitles_rounded,
                                        onChanged: (_) => setState(() {}), // Force real-time preview sync
                                        validator: (val) {
                                          if (val == null || val.trim().isEmpty) {
                                            return 'Store tagline is required.';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Emblem selections Card
                                GlassCard(
                                  padding: const EdgeInsets.all(24.0),
                                  margin: EdgeInsets.zero,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Select Brand Emblem', style: AppStyles.heading2),
                                      const SizedBox(height: 16),

                                      GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
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
                                                    size: 22,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    item['label'] as String,
                                                    style: TextStyle(
                                                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                                      fontSize: 10,
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
                              ],
                            ),
                          ),

                          // Real-Time Preview Column (Right Panel)
                          if (isWide) ...[
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 3,
                              child: _buildRealTimePreview(emblems),
                            ),
                          ],
                        ],
                      );
                    },
                  ),

                  // Preview fallback for narrow/vertical views
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isWide = constraints.maxWidth > 750;
                      if (!isWide) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20.0),
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
        ),
      ),
    );
  }

  /// Builds a real-time live-preview widget matching brand_settings_screen styles.
  Widget _buildRealTimePreview(List<Map<String, dynamic>> emblems) {
    // Look up matching emblem config
    final activeEmblemMap = emblems.firstWhere(
      (e) => e['code'] == _selectedIconCode,
      orElse: () => emblems.first,
    );
    final IconData icon = activeEmblemMap['icon'] as IconData;
    final Color color = activeEmblemMap['color'] as Color;

    return GlassCard(
      padding: const EdgeInsets.all(24.0),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Preview', style: AppStyles.heading2),
          const SizedBox(height: 16),

          // Sidebar header preview box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              border: Border.all(color: AppColors.surfaceLight.withOpacity(0.4)),
            ),
            child: Row(
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
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _storeNameController.text.trim().isEmpty ? 'My Store' : _storeNameController.text.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _storeTaglineController.text.trim().isEmpty ? 'OFFLINE SYSTEM' : _storeTaglineController.text.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Preloader preview box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              border: Border.all(color: color.withOpacity(0.25), width: 1.0),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.08),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _storeNameController.text.trim().isEmpty ? 'MY STORE' : _storeNameController.text.trim().toUpperCase(),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _storeTaglineController.text.trim().isEmpty ? 'OFFLINE SYSTEM' : _storeTaglineController.text.trim().toUpperCase(),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit & Continue trigger
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
            ),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submitBranding,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue to Credentials',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
