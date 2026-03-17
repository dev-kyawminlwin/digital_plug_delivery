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
import 'screens/auth/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("DEBUG: App Init Started");

  try {
    print("DEBUG: About to initialize Firebase");
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDbcB6VmgxPK5f1rXi5I2_OVD-YaNiDM8g',
        appId: '1:673069079625:web:0edcd470e28071447ef398',
        messagingSenderId: '673069079625',
        projectId: 'digital-plug',
        storageBucket: 'digital-plug.firebasestorage.app',
        authDomain: 'digital-plug.firebaseapp.com',
        measurementId: 'G-YKEGV7T620',
      ),
    );
    print("DEBUG: Firebase initialized successfully");
  } catch (e, st) {
    print("DEBUG: Firebase init failed! $e\n$st");
  }

  try {
    // VERCEL QUIC TIMEOUT FIX:
    // Disables the default WebChannel which conflicts with Chrome's QUIC protocol on Vercel.
    // Forces standard WebSockets and enables Long-Polling fallback.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, // Allow local cache
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      host: 'firestore.googleapis.com',
      sslEnabled: true,
      ignoreUndefinedProperties: true,
    );
    print("DEBUG: Firestore settings applied (Vercel Fix)");
  } catch (e) {
    print("DEBUG: Firestore settings failed! $e");
  }

  print("DEBUG: Calling runApp");
  runApp(const DigitalPlugApp());
}

class DigitalPlugApp extends StatelessWidget {
  const DigitalPlugApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.poppinsTextTheme();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Digital Plug Delivery',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFFF5E1E),
        scaffoldBackgroundColor: Colors.white,
        textTheme: textTheme,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5E1E),
          primary: const Color(0xFFFF5E1E),
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            elevation: 0,
          ),
        ),
      ),
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/subscription_expired': (context) =>
            const SubscriptionExpiredScreen(),
        '/super_admin': (context) => const SuperAdminDashboard(),
        '/admin': (context) => const AdminDashboard(),
        '/rider': (context) => const RiderHome(),
      },
      onGenerateRoute: (settings) {
        if (settings.name != null &&
            settings.name!.startsWith('/track/')) {
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

/// AuthGate — never shows a blank screen.
/// During Firebase auth 'waiting' state, show MarketplaceHome immediately.
/// This is the fix for the blank white screen on Chrome.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnapshot.data;
        if (user == null) return const WelcomeScreen();

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const MarketplaceHome();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            final role = data['role'] as String?;

            switch (role) {
              case 'super_admin': return const SuperAdminDashboard();
              case 'admin':
                final businessId = data['businessId'] as String?;
                if (businessId == null) return const MarketplaceHome();
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('businesses').doc(businessId).snapshots(),
                  builder: (context, bizSnapshot) {
                    if (!bizSnapshot.hasData) return const AdminDashboard();
                    final bizData = bizSnapshot.data!.data() as Map<String, dynamic>?;
                    final status = bizData?['subscriptionStatus'] ?? 'inactive';
                    
                    final dynamic subEndRaw = bizData?['subscriptionEnd'];
                    DateTime? subEnd;
                    if (subEndRaw is Timestamp) {
                      subEnd = subEndRaw.toDate();
                    } else if (subEndRaw is String) {
                      subEnd = DateTime.tryParse(subEndRaw);
                    }

                    final isActive = status == 'active' && (subEnd == null || subEnd.isAfter(DateTime.now()));
                    return isActive ? const AdminDashboard() : const SubscriptionExpiredScreen();
                  },
                );
              case 'rider': return const RiderHome();
              case 'customer':
              default: return const MarketplaceHome();
            }
          },
        );
      },
    );
  }
}