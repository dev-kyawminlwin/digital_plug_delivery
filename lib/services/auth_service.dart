import 'dart:convert';
import 'package:http/http.dart' as http;
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
  // Using Firebase Auth and Firestore REST API to create accounts and documents
  // without affecting the primary web session's IndexedDB state (which normally crashes streams).
  Future<Map<String, String>> _provisionAccountHidden(String email, String password) async {
    final apiKey = Firebase.app().options.apiKey;
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'uid': data['localId'],
        'idToken': data['idToken'],
      };
    } else {
      final errorData = jsonDecode(response.body);
      throw 'Provisioning failed: ${errorData['error']?['message'] ?? response.body}';
    }
  }

  Future<void> createAdminAsSuperAdmin({
    required String email,
    required String password,
    required String businessName,
    required String adminName,
  }) async {
    try {
      // 1. Create user via REST to avoid corrupting primary Web Session
      final authData = await _provisionAccountHidden(email, password);
      final String uid = authData['uid']!;
      final String idToken = authData['idToken']!;
      final String businessId = 'biz_${DateTime.now().millisecondsSinceEpoch}';

      final String projectId = Firebase.app().options.projectId;

      // 2. Write the business document via REST (ownerUid == this new uid)
      final bizUrl = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/businesses/$businessId');
      final bizResponse = await http.patch(
        bizUrl,
        headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'fields': {
            'name': {'stringValue': businessName},
            'ownerUid': {'stringValue': uid},
            'subscriptionStatus': {'stringValue': 'active'},
            'subscriptionEnd': {'timestampValue': DateTime.now().add(const Duration(days: 30)).toUtc().toIso8601String()},
            'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
          }
        }),
      );

      if (bizResponse.statusCode != 200) throw 'Failed to write business doc: ${bizResponse.body}';

      // 3. Write the users document via REST (userId == this new uid)
      final userUrl = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid');
      final userResponse = await http.patch(
        userUrl,
        headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'fields': {
            'name': {'stringValue': adminName},
            'role': {'stringValue': 'admin'},
            'businessId': {'stringValue': businessId},
            'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
          }
        }),
      );

      if (userResponse.statusCode != 200) throw 'Failed to write user doc: ${userResponse.body}';
      
      print("SuperAdmin successfully provisioned Admin via REST: $adminName ($uid)");
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
      final authData = await _provisionAccountHidden(email, password);
      final String uid = authData['uid']!;
      final String idToken = authData['idToken']!;

      final String projectId = Firebase.app().options.projectId;

      final userUrl = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid');
      final userResponse = await http.patch(
        userUrl,
        headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'fields': {
            'name': {'stringValue': riderName},
            'role': {'stringValue': 'rider'},
            'businessId': {'stringValue': businessId},
            'earnings': {'integerValue': "0"},
            'deliveriesCount': {'integerValue': "0"},
            'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
          }
        }),
      );

      if (userResponse.statusCode != 200) throw 'Failed to write rider doc: ${userResponse.body}';
      
      print("SuperAdmin successfully provisioned Rider via REST: $riderName ($uid)");
    } catch (e) {
      print("SuperAdmin Rider Creation Error: $e");
      rethrow;
    }
  }

  Future<String?> createCustomerAsSuperAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final authData = await _provisionAccountHidden(email, password);
      final String uid = authData['uid']!;
      final String idToken = authData['idToken']!;

      final String projectId = Firebase.app().options.projectId;

      final userUrl = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/users/$uid');
      final userResponse = await http.patch(
        userUrl,
        headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
        body: jsonEncode({
          'fields': {
            'name': {'stringValue': name},
            'phone': {'stringValue': phone},
            'email': {'stringValue': email},
            'role': {'stringValue': 'customer'},
            'points': {'integerValue': "0"},
            'address': {'stringValue': ''},
            'createdAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
          }
        }),
      );

      if (userResponse.statusCode != 200) throw 'Failed to write customer doc: ${userResponse.body}';

      return uid;
    } catch (e) {
      print("SuperAdmin Customer Creation Error: $e");
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