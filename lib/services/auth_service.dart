import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> registerNewBusiness({
    required String email,
    required String password,
    required String businessName,
    required String adminName,
  }) async {
    try {
      // 1. Create the Auth User
      UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = res.user!.uid;

      // 2. Generate a Unique Business ID (e.g., biz_1710293)
      String businessId = 'biz_${DateTime.now().millisecondsSinceEpoch}';

      // 3. Create the Business Document
      await _db.collection('businesses').doc(businessId).set({
        'name': businessName,
        'ownerUid': uid,
        'subscriptionStatus': 'active',
        'subscriptionEnd': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Create the User Document with the linked BusinessId
      await _db.collection('users').doc(uid).set({
        'name': adminName,
        'role': 'admin',
        'businessId': businessId, // The "SaaS Anchor"
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("SaaS Onboarding Complete for $businessName");
    } catch (e) {
      print("Error during onboarding: $e");
      rethrow;
    }
  }

  // --- SUPER ADMIN PROVISIONING WORKAROUND ---
  // Firebase SDK normally signs out the current user when creating a new account.
  // We use a secondary App instance to bypass this behavior.
  Future<String> _provisionAccountHidden(String email, String password) async {
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      UserCredential res = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = res.user!.uid;
      await tempApp.delete();
      return uid;
    } catch (e) {
      await tempApp.delete();
      rethrow;
    }
  }

  Future<void> createAdminAsSuperAdmin({
    required String email,
    required String password,
    required String businessName,
    required String adminName,
  }) async {
    try {
      String uid = await _provisionAccountHidden(email, password);
      String businessId = 'biz_${DateTime.now().millisecondsSinceEpoch}';

      await _db.collection('businesses').doc(businessId).set({
        'name': businessName,
        'ownerUid': uid,
        'subscriptionStatus': 'active',
        'subscriptionEnd': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _db.collection('users').doc(uid).set({
        'name': adminName,
        'role': 'admin',
        'businessId': businessId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("SuperAdmin Admin Creation Error: $e");
      rethrow;
    }
  }

  Future<void> createRiderAsSuperAdmin({
    required String email,
    required String password,
    required String riderName,
    required String businessId,
  }) async {
    try {
      String uid = await _provisionAccountHidden(email, password);
      
      await _db.collection('users').doc(uid).set({
        'name': riderName,
        'role': 'rider',
        'businessId': businessId,
        'walletBalance': 0,
        'collectedCash': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("SuperAdmin Rider Creation Error: $e");
      rethrow;
    }
  }

  // --- CUSTOMER (END-USER) AUTHENTICATION ---
  
  Future<void> registerCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      UserCredential res = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = res.user!.uid;

      // Save to 'users' collection with 'role': 'customer' to avoid Permission Denied on new collections
      await _db.collection('users').doc(uid).set({
        'name': name,
        'phone': phone,
        'address': address,
        'email': email,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Customer Registration Error: $e");
      rethrow;
    }
  }

  Future<void> loginCustomer({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Customer Login Error: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}