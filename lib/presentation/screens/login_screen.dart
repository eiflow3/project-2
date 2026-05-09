import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/style.dart';
import '../../providers/auth_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_text_field.dart';

/// LoginScreen locks the application viewport until valid master administrative
/// credentials (PIN or Password) are provided, matching the database record.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'admin');
  final _credentialController = TextEditingController();

  bool _obscureText = true;
  bool _isChecking = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _credentialController.dispose();
    super.dispose();
  }

  /// Dispatches the inputs to AuthProvider. If validated, pushes to the main panel.
  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isChecking = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String username = _usernameController.text.trim();
    final String credential = _credentialController.text;
    
    // Check master account details to detect mode dynamically (PIN or PASSWORD)
    final master = await authProvider.getMasterAccount();
    final bool isPin = master?.authType == 'PIN';

    bool success = await authProvider.login(username, credential, isPin);

    setState(() => _isChecking = false);

    if (success) {
      _credentialController.clear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.loginError ?? "Incorrect security credentials."),
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
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 1. Brand Logo Badge
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Icon(Icons.storefront, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'OrderFlow Desktop',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'OFFLINE ADMINISTRATIVE SESSION',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2. Authentication Input Card
                  FutureBuilder(
                    future: Provider.of<AuthProvider>(context, listen: false).getMasterAccount(),
                    builder: (context, snapshot) {
                      final bool isPinMode = snapshot.hasData && snapshot.data?.authType == 'PIN';
                      
                      return GlassCard(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sign In', style: AppStyles.heading2),
                            const SizedBox(height: 8),
                            const Text(
                              'Provide credentials to unlock access.',
                              style: AppStyles.bodySecondary,
                            ),
                            const SizedBox(height: 28),

                            // Username Field
                            CustomTextField(
                              controller: _usernameController,
                              labelText: 'Username',
                              prefixIcon: Icons.person_outline,
                              validator: (v) => v!.trim().isEmpty ? 'Username required' : null,
                            ),
                            const SizedBox(height: 20),

                            // PIN or Password Field
                            CustomTextField(
                              controller: _credentialController,
                              labelText: isPinMode ? 'Enter Security PIN' : 'Enter Password',
                              prefixIcon: isPinMode ? Icons.pin_outlined : Icons.lock_outline,
                              obscureText: _obscureText,
                              keyboardType: isPinMode ? TextInputType.number : TextInputType.text,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary, size: 18),
                                onPressed: () => setState(() => _obscureText = !_obscureText),
                              ),
                              validator: (v) => v!.isEmpty ? 'Field required' : null,
                            ),
                            const SizedBox(height: 32),

                            // Unlock button
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                              ),
                              child: ElevatedButton(
                                onPressed: _isChecking ? null : _submitLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                                  ),
                                ),
                                child: _isChecking
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Unlock Application',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.lock_open, color: Colors.white, size: 20),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      );
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
}
