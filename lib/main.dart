import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/marketplace_home.dart';
import 'screens/auth/subscription_expired_screen.dart';
import 'screens/super_admin/super_admin_dashboard.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/rider/rider_home.dart';
import 'screens/customer/track_order_screen.dart';

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

  try {
    await FirebaseFirestore.instance.clearPersistence();
  } catch (e) {
    // Expected on some platforms
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
        primaryColor: const Color(0xFF1E3A8A),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          primary: const Color(0xFF1E3A8A),
          secondary: const Color(0xFFEAB308),
          surface: Colors.white,
          onSurface: const Color(0xFF1F2937),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1F2937),
          centerTitle: false,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F2937),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            elevation: 0,
          ),
        ),
      ),
      // AuthGate is the root — handles all routing based on auth state + role
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/subscription_expired': (context) => const SubscriptionExpiredScreen(),
        '/super_admin': (context) => const SuperAdminDashboard(),
        '/admin': (context) => const AdminDashboard(),
        '/rider': (context) => const RiderHome(),
        '/': (context) => const MarketplaceHome(),
      },
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

/// AuthGate listens to Firebase auth changes and routes users to
/// the correct screen based on their role. This is the root of the app.
/// Signing out automatically re-triggers this and shows MarketplaceHome.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Still loading auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in — show public marketplace
        final user = authSnapshot.data;
        if (user == null) {
          return const MarketplaceHome();
        }

        // Logged in — look up role in Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!userSnapshot.data!.exists) {
              // User exists in Auth but not Firestore → treat as customer
              return const MarketplaceHome();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            final role = data['role'] as String?;

            switch (role) {
              case 'super_admin':
                return const SuperAdminDashboard();

              case 'admin':
                // Check subscription
                final businessId = data['businessId'];
                if (businessId == null) return const MarketplaceHome();
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('businesses')
                      .doc(businessId)
                      .get(),
                  builder: (context, bizSnapshot) {
                    if (!bizSnapshot.hasData) {
                      return const Scaffold(body: Center(child: CircularProgressIndicator()));
                    }
                    final bizData = bizSnapshot.data!.data() as Map<String, dynamic>?;
                    final status = bizData?['subscriptionStatus'] ?? 'inactive';
                    final subEnd = (bizData?['subscriptionEnd'] as Timestamp?)?.toDate();
                    final isActive = status == 'active' &&
                        (subEnd == null || subEnd.isAfter(DateTime.now()));
                    if (!isActive) return const SubscriptionExpiredScreen();
                    return const AdminDashboard();
                  },
                );

              case 'rider':
                return const RiderHome();

              case 'customer':
              default:
                return const MarketplaceHome();
            }
          },
        );
      },
    );
  }
}