import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/marketplace_home.dart'; // Phase 9
import 'screens/auth/subscription_expired_screen.dart';
import 'screens/super_admin/super_admin_dashboard.dart';
import 'screens/customer/track_order_screen.dart'; // Phase 8

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyAE0OwKyLnxr5VAs45eOOB5HafzqfUbKq4',
      appId: '1:673069079625:android:b7a4b01936aa5f107ef398',
      messagingSenderId: '673069079625',
      projectId: 'digital-plug',
    ),
  );
  
  // Wipe corrupt IndexedDB cache for Web SDK
  try {
    await FirebaseFirestore.instance.clearPersistence();
  } catch (e) {
    print("Persistence clear error (expected on some platforms): $e");
  }

  runApp(const DigitalPlugApp());
}

class DigitalPlugApp extends StatelessWidget {
  const DigitalPlugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital Plug Delivery',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1E3A8A), // Royal Blue from logo
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFFEAB308), // Gold/Yellow from logo
          surface: Colors.white,
          onSurface: const Color(0xFF1F2937), // Dark Gray/Black for text
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1F2937),
          centerTitle: false,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F2937), // Sleek Dark Buttons like the reference
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            elevation: 0,
          ),
        ),
      ),
      // Phase 9: Start customers on the public marketplace
      initialRoute: '/',
      routes: {
        '/': (context) => const MarketplaceHome(),
        '/login': (context) => const LoginScreen(),
        '/subscription_expired': (context) => const SubscriptionExpiredScreen(),
        '/super_admin': (context) => const SuperAdminDashboard(),
        // Add your other screens here so the navigator can find them
        // '/admin': (context) => const AdminDashboard(),
        // '/rider': (context) => const RiderHome(),
      },
      // Phase 8: Intercept dynamic URL for tracking
      onGenerateRoute: (settings) {
        if (settings.name != null && settings.name!.startsWith('/track/')) {
          final orderId = settings.name!.split('/track/').last;
          return MaterialPageRoute(
            builder: (context) => TrackOrderScreen(orderId: orderId),
          );
        }
        return null;
      },
    );
  }
}