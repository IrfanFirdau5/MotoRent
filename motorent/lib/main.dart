import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
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
  
  // ✅ STRIPE INITIALIZATION - FIXED VERSION
  try {
    print('🔵 APP: About to initialize Stripe');
    
    // ⚠️ REPLACE WITH YOUR ACTUAL PUBLISHABLE KEY
    Stripe.publishableKey = 'pk_test_51Sh0vdDJJKjBR2ZQQa36I9pC9vqTdh7ZRsZYu34hSgNrMZxuO9TvXe3v1GaWOf8Sum0nxfwCt8wA5SdknSynXJiu007leYOhFH';  // REPLACE THIS!
    
    // ✅ CRITICAL: Set merchant identifier for Android
    Stripe.merchantIdentifier = 'motorent.merchant';
    
    // ✅ CRITICAL: Apply settings to properly initialize
    await Stripe.instance.applySettings();
    
    print('✅ APP: Stripe initialized successfully!');
  } catch (e) {
    print('🔴 APP: Stripe initialization FAILED: $e');
    // Don't crash the app, just log the error
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
      home: const LoginPage(),
    );
  }
}