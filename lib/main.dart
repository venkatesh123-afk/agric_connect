import 'package:agri_marketplace_app/add_product_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/product_provider.dart';
import 'shop.dart';
import 'my_orders_page.dart';
import 'farmer_orders_page.dart';

// Screens
import 'splash.dart';
import 'login.dart';
import 'buyer_dashboard.dart';
import 'farmer_dashboard.dart';
import 'privacy_policy.dart';
import 'terms_conditions.dart';
import 'checkout_success.dart';
import 'available_products_page.dart' hide AddProductPage;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Wrap MyApp with ChangeNotifierProvider for ProductProvider
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ProductProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agri Connect',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const SplashScreen(), // Start at Splash Screen
      routes: {
        '/PrivacyPolicy': (context) => const PrivacyPolicyPage(),
        '/TermsAndConditions': (context) => const TermsAndConditionsPage(),
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        // Named routes for key pages
        '/shop': (context) =>
            const ShopPage(selectedProduct: '', selectedPrice: ''),
        '/my-orders': (context) => const MyOrdersPage(),
        '/farmer-orders': (context) => const FarmerOrdersPage(),

        '/my-products': (context) => const MyProductsPage(),
        '/add-product': (context) =>
            const AddProductPage(existingProductId: '', existingData: {}),
        '/available-products': (context) => const AvailableProductsPage(),
        '/checkout-success': (context) =>
            const CheckoutSuccessPage(orderDetails: {}),
        BuyerDashboard.routeName: (context) => const BuyerDashboard(),
        FarmerDashboard.routeName: (context) => const FarmerDashboard(),
      },
    );
  }
}
