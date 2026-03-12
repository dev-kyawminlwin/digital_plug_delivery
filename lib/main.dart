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

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAE0OwKyLnxr5VAs45eOOB5HafzqfUbKq4',
        authDomain: 'digital-plug.firebaseapp.com',
        appId: '1:673069079625:android:b7a4b01936aa5f107ef398',
        messagingSenderId: '673069079625',
        projectId: 'digital-plug',
        storageBucket: 'digital-plug.firebasestorage.app',
      ),
    );
    // ignore: avoid_print
    print('[DPD] Firebase initialized OK');
  } catch (e) {
    // ignore: avoid_print
    print('[DPD] Firebase init error: $e');
  }

  // Safe settings — some FlutterFire 3.x web builds reject this
  try {
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
    // ignore: avoid_print
    print('[DPD] Firestore settings set');
  } catch (e) {
    // ignore: avoid_print
    print('[DPD] Firestore settings error: $e');
  }

  // ignore: avoid_print
  print('[DPD] Calling runApp');
  runApp(const DigitalPlugApp());
  // ignore: avoid_print
  print('[DPD] runApp returned');
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
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/subscription_expired': (context) => const SubscriptionExpiredScreen(),
        '/super_admin': (context) => const SuperAdminDashboard(),
        '/admin': (context) => const AdminDashboard(),
        '/rider': (context) => const RiderHome(),
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

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // While auth resolves, show a loading scaffold (not blank)
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const MarketplaceHome();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const MarketplaceHome();
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>;
            final role = data['role'] as String?;

            switch (role) {
              case 'super_admin':
                return const SuperAdminDashboard();

              case 'admin':
                final businessId = data['businessId'] as String?;
                if (businessId == null) return const MarketplaceHome();
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('businesses')
                      .doc(businessId)
                      .snapshots(),
                  builder: (context, bizSnapshot) {
                    if (!bizSnapshot.hasData) return const AdminDashboard();
                    final bizData =
                        bizSnapshot.data!.data() as Map<String, dynamic>?;
                    final status =
                        bizData?['subscriptionStatus'] ?? 'inactive';
                    final subEnd =
                        (bizData?['subscriptionEnd'] as Timestamp?)?.toDate();
                    final isActive = status == 'active' &&
                        (subEnd == null || subEnd.isAfter(DateTime.now()));
                    return isActive
                        ? const AdminDashboard()
                        : const SubscriptionExpiredScreen();
                  },
                );

              case 'rider':
                return const RiderHome();

              default:
                return const MarketplaceHome();
            }
          },
        );
      },
    );
  }
}

/// Visible loading state — shows a branded splash while Firebase auth resolves.
/// If you see this stuck on screen, Firebase Auth stream is not emitting.
class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E3A8A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_dining_rounded, color: Colors.white, size: 64),
            SizedBox(height: 24),
            Text(
              'Digital Plug Delivery',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}