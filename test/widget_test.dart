// This is a robust widget test for the Offline Order Management Application.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:offline_order_manager/main.dart';
import 'package:offline_order_manager/providers/auth_provider.dart';
import 'package:offline_order_manager/providers/product_provider.dart';
import 'package:offline_order_manager/providers/order_provider.dart';
import 'package:offline_order_manager/providers/merchant_provider.dart';
import 'package:offline_order_manager/providers/backup_provider.dart';

void main() {
  testWidgets('Offline application loads with step-by-step master setup screen', (WidgetTester tester) async {
    // Build our app with mock/re-initialized providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => MerchantProvider()),
          ChangeNotifierProvider(create: (_) => BackupProvider()),
        ],
        child: const OrderFlowApp(),
      ),
    );

    // Settle all asynchronous tasks and microtasks (like initial Auth checking futures)
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Verify that the application successfully starts in Setup Onboarding Step 1 (unregistered state)
    // because no database exists yet in the test environment
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('Configure Your Brand'), findsOneWidget);
    expect(find.text('Store Name'), findsOneWidget);
    expect(find.text('Store Tagline / Subtitle'), findsOneWidget);
  });
}

