import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart'; // ✅ Import flutter_stripe
import 'screens/login_page.dart';
import 'screens/customer/vehicle_listing_page.dart';
import 'screens/admin/admin_dashboard_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/owner/owner_dashboard_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  print('🔵 APP: Starting main()');
  
  WidgetsFlutterBinding.ensureInitialized();
  print('🔵 APP: WidgetsFlutterBinding initialized');
  
  // ✅ Load environment variables FIRST
  try {
    print('🔵 APP: Loading environment variables...');
    await dotenv.load(fileName: ".env");
    print('✅ APP: Environment variables loaded successfully!');
    
    // Verify Stripe keys are loaded (without printing the actual keys!)
    final hasPublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']?.isNotEmpty ?? false;
    final hasSecretKey = dotenv.env['STRIPE_SECRET_KEY']?.isNotEmpty ?? false;
    
    print('🔵 APP: Stripe Publishable Key loaded: $hasPublishableKey');
    print('🔵 APP: Stripe Secret Key loaded: $hasSecretKey');
    
    if (!hasPublishableKey || !hasSecretKey) {
      print('⚠️  WARNING: Stripe keys not found in .env file!');
      print('⚠️  Make sure you have created .env file with your Stripe keys.');
    }
  } catch (e) {
    print('🔴 APP: Failed to load environment variables: $e');
    print('⚠️  Make sure .env file exists in project root!');
    // Continue anyway - app will fail gracefully when trying to use Stripe
  }

  // ✅ Initialize Stripe BEFORE anything else
  try {
    print('🔵 APP: Initializing Stripe...');
    
    final publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    
    if (publishableKey.isEmpty) {
      throw Exception('STRIPE_PUBLISHABLE_KEY not found in .env file');
    }
    
    if (!publishableKey.startsWith('pk_')) {
      throw Exception('Invalid Stripe publishable key format');
    }
    
    // Set the publishable key
    Stripe.publishableKey = publishableKey;
    
    // Optional: Configure merchant details
    Stripe.merchantIdentifier = 'merchant.com.motorent';
    
    // Apply settings
    await Stripe.instance.applySettings();
    
    print('✅ APP: Stripe initialized successfully!');
    print('   Publishable Key: ${publishableKey.substring(0, 15)}...');
    print('   Mode: ${publishableKey.startsWith('pk_test_') ? 'TEST' : 'LIVE'}');
  } catch (e) {
    print('🔴 APP: Stripe initialization FAILED: $e');
    print('⚠️  Payment features will not work!');
  }
  
  await initializeDateFormatting();
  print('🔵 APP: Date formatting initialized');
  
  try {
    print('🔵 APP: About to initialize Firebase');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ APP: Firebase initialized successfully!');
  } catch (e) {
    print('🔴 APP: Firebase initialization FAILED: $e');
  }
  
  print('🔵 APP: Starting app');
  runApp(const MotoRentApp());
}

class MotoRentApp extends StatelessWidget {
  const MotoRentApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotoRent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF1E88E5),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E88E5),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF1E88E5),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
      // home: const VehicleListingPage(), // For customer view
      // home: const AdminDashboardPage(), // For admin view
      // home: const OwnerDashboardPage(), // For Owner view
      // Start with Login Page
      home: const LoginPage(),
    );
  }
}