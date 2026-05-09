import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

// Core Themes
import 'core/theme/colors.dart';
import 'core/theme/style.dart';

// Storage and Repository Providers
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';

// Authentication & Onboarding Screens
import 'presentation/screens/setup/setup_admin_screen.dart';
import 'presentation/screens/login_screen.dart';

// Core App Functional Screens
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/order_entry_screen.dart';
import 'presentation/screens/orders_list_screen.dart';
import 'presentation/screens/products_list_screen.dart';
import 'presentation/screens/brand_settings_screen.dart';

// Storage and Repository Providers
import 'providers/merchant_provider.dart';

// Shared Presentation Widgets
import 'presentation/widgets/navigation_sidebar.dart';
import 'presentation/widgets/app_preloading_screen.dart';

void main() {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // HIGHLY IMPORTANT FOR MULTI-PLATFORM COMPILATION:
  // If compiling for Web (Chrome), we load the SQLite WASM IndexedDB driver.
  // If desktop, we load the FFI system bindings.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    // Global MultiProvider declaration provides state contexts down the widget tree
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MerchantProvider()),
      ],
      child: const OrderFlowApp(),
    ),
  );
}

/// OrderFlowApp defines the root MaterialApp.
/// Configures premium theme presets and handles root navigation logic.
class OrderFlowApp extends StatelessWidget {
  const OrderFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OrderFlow Offline System',
      debugShowCheckedModeBanner: false,
      
      // Core premium dark-themed Material Design properties
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primary,
          secondary: AppColors.accent,
          background: AppColors.background,
          surface: AppColors.surface,
        ),
        
        // Customized typography mappings
        textTheme: const TextTheme(
          displayLarge: AppStyles.heading1,
          titleMedium: AppStyles.heading2,
          bodyLarge: AppStyles.bodyPrimary,
          bodyMedium: AppStyles.bodySecondary,
        ),
      ),
      
      // Root routing matches user authentication states
      home: const AuthRouteGuard(),
    );
  }
}

/// AuthRouteGuard acts as a security barrier, listening to [AuthProvider] changes
/// to direct traffic into Setup Wizards, Lock screens, or the Main Workspace.
class AuthRouteGuard extends StatelessWidget {
  const AuthRouteGuard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Evaluate the admin setup and login status
    switch (authProvider.status) {
      case AuthStatus.loading:
        return const AppPreloadingScreen();
      case AuthStatus.unregistered:
        // No administrative master account present, show Setup Wizard
        return const SetupAdminScreen();
      case AuthStatus.unauthenticated:
        // Admin registered, but active session is locked, show Login Screen
        return const LoginScreen();
      case AuthStatus.authenticated:
        // Fully validated, show core application dashboard
        return const MainWorkspacePanel();
    }
  }
}

/// MainWorkspacePanel is the structural layout enclosing our core panels.
/// It implements a horizontal split view optimized for desktop viewports.
class MainWorkspacePanel extends StatefulWidget {
  const MainWorkspacePanel({super.key});

  @override
  State<MainWorkspacePanel> createState() => _MainWorkspacePanelState();
}

class _MainWorkspacePanelState extends State<MainWorkspacePanel> {
  int _activeTabIndex = 0;

  // Swappable screens reflecting the selected index
  final List<Widget> _workspaceScreens = const [
    DashboardScreen(),
    OrderEntryScreen(),
    OrdersListScreen(),
    ProductsListScreen(),
    BrandSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 800;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isMobile
          ? AppBar(
              backgroundColor: AppColors.surface,
              title: const Text(
                'OrderFlow',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_forever_outlined, color: AppColors.error, size: 20),
                  tooltip: 'Reset Application',
                  onPressed: () => _showResetDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
                  tooltip: 'Lock Session',
                  onPressed: () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                ),
              ],
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(1.5),
                child: Divider(color: AppColors.surfaceLight, height: 1.5),
              ),
            )
          : null,
      body: Row(
        children: [
          // Left side: Stationary sidebar menu panel (only on Desktop/Widescreen Laptop layouts)
          if (!isMobile)
            NavigationSidebar(
              currentIndex: _activeTabIndex,
              onTabSelected: (index) {
                setState(() {
                  _activeTabIndex = index;
                });
              },
            ),
          
          // Right side: Active workspace view with smooth animations
          Expanded(
            child: Container(
              color: AppColors.background,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_activeTabIndex),
                  child: _workspaceScreens[_activeTabIndex],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: AppColors.surface,
                indicatorColor: AppColors.primary.withOpacity(0.15),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold);
                  }
                  return const TextStyle(color: AppColors.textSecondary, fontSize: 11);
                }),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(color: AppColors.primaryLight, size: 22);
                  }
                  return const IconThemeData(color: AppColors.textSecondary, size: 20);
                }),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(color: AppColors.surfaceLight, height: 1.5),
                  NavigationBar(
                    selectedIndex: _activeTabIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _activeTabIndex = index;
                      });
                    },
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard),
                        label: 'Dashboard',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.add_shopping_cart_outlined),
                        selectedIcon: Icon(Icons.add_shopping_cart),
                        label: 'New Order',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.receipt_long_outlined),
                        selectedIcon: Icon(Icons.receipt_long),
                        label: 'Ledger',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.inventory_2_outlined),
                        selectedIcon: Icon(Icons.inventory_2),
                        label: 'Inventory',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.palette_outlined),
                        selectedIcon: Icon(Icons.palette),
                        label: 'Branding',
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Reset Application?'),
            ],
          ),
          content: const Text(
            'This will permanently delete all your sales ledger entries, products catalog, and custom admin credentials. The application will be restored back to first-time setup.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Provider.of<AuthProvider>(context, listen: false).resetApplication();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.radiusSmall)),
              ),
              child: const Text('Reset Everything', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        );
      },
    );
  }
}
