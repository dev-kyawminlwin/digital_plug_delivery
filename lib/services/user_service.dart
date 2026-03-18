import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Future<void> createSuperAdmin(String uid, String email) async {
    await _db.collection('users').doc(uid).set({
      'name': 'Master Admin',
      'email': email,
      'role': 'super_admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
