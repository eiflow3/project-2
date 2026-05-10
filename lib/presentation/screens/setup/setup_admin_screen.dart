import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/style.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_text_field.dart';
import 'setup_products_screen.dart';

/// SetupAdminScreen is the first screen shown if no administrative user is configured.
/// It collects credentials (Username + PIN or Password) and hashes them in local SQLite.
class SetupAdminScreen extends StatefulWidget {
  const SetupAdminScreen({super.key});

  @override
  State<SetupAdminScreen> createState() => _SetupAdminScreenState();
}

class _SetupAdminScreenState extends State<SetupAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'admin');
  final _credentialController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isPinMode = true; // True if using 4-6 digit numeric PIN, false if full password
  bool _obscureText = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _credentialController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Validates and submits the administrative credentials to the AuthProvider.
  /// If successful, transitions to the next setup phase (SetupProductsScreen) in the same tree.
  Future<void> _submitSetup() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String username = _usernameController.text.trim();
    final String credential = _credentialController.text;

    // Call AuthProvider to register master account on disk
    bool success = await authProvider.completeAdminSetup(username, credential, _isPinMode);
    
    if (success && mounted) {
      // No-op: global AuthRouteGuard handles transitioning to Step 3 automatically
    } else if (mounted) {
      // Display error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.loginError ?? "Database setup failure."),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Sleek Step Progress Indicator
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
                          'Step 2 of 3',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Initialize Master Account',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Main Setup Card
                  GlassCard(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome to OrderFlow',
                          style: AppStyles.heading1,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Let\'s configure your offline administrative credentials. Since this is an offline-only application, these details will be stored securely on your local device.',
                          style: AppStyles.bodySecondary,
                        ),
                        const SizedBox(height: 32),

                        // Username Input
                        CustomTextField(
                          controller: _usernameController,
                          labelText: 'Master Username',
                          prefixIcon: Icons.person_outline,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Username is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Auth Mode Selector Toggle
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Security Mode:',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Numeric PIN', style: TextStyle(fontSize: 12)),
                              selected: _isPinMode,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _isPinMode = true;
                                    _credentialController.clear();
                                    _confirmController.clear();
                                  });
                                }
                              },
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              side: BorderSide(color: _isPinMode ? AppColors.primary : AppColors.surfaceLight),
                              labelStyle: TextStyle(color: _isPinMode ? AppColors.primaryLight : AppColors.textSecondary),
                              backgroundColor: Colors.transparent,
                            ),
                            ChoiceChip(
                              label: const Text('Alpha-numeric Password', style: TextStyle(fontSize: 12)),
                              selected: !_isPinMode,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _isPinMode = false;
                                    _credentialController.clear();
                                    _confirmController.clear();
                                  });
                                }
                              },
                              selectedColor: AppColors.primary.withOpacity(0.2),
                              side: BorderSide(color: !_isPinMode ? AppColors.primary : AppColors.surfaceLight),
                              labelStyle: TextStyle(color: !_isPinMode ? AppColors.primaryLight : AppColors.textSecondary),
                              backgroundColor: Colors.transparent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Primary Credential Input
                        CustomTextField(
                          controller: _credentialController,
                          labelText: _isPinMode ? 'Enter Security PIN (4-6 digits)' : 'Enter Master Password',
                          prefixIcon: _isPinMode ? Icons.pin : Icons.lock_outline,
                          obscureText: _obscureText,
                          keyboardType: _isPinMode ? TextInputType.number : TextInputType.text,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary, size: 20),
                            onPressed: () => setState(() => _obscureText = !_obscureText),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Field cannot be empty.';
                            }
                            if (_isPinMode) {
                              if (val.length < 4 || val.length > 6 || int.tryParse(val) == null) {
                                return 'PIN must be between 4 and 6 numeric digits.';
                              }
                            } else {
                              if (val.length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Confirm Credential Input
                        CustomTextField(
                          controller: _confirmController,
                          labelText: _isPinMode ? 'Confirm Security PIN' : 'Confirm Master Password',
                          prefixIcon: Icons.lock_clock_outlined,
                          obscureText: _obscureText,
                          keyboardType: _isPinMode ? TextInputType.number : TextInputType.text,
                          validator: (val) {
                            if (val != _credentialController.text) {
                              return 'Entered credentials do not match.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Submit Setup Button with visual Gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: ElevatedButton(
                            onPressed: _submitSetup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size.fromHeight(56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Continue to Product Loading',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
