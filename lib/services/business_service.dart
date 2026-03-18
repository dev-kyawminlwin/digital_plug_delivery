import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getBusinessData(String businessId) async {
    final doc = await _db.collection('businesses').doc(businessId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  bool isSubscriptionActive(Map<String, dynamic>? bizData) {
    if (bizData == null) return false;
    final status = bizData['subscriptionStatus'] ?? 'inactive';
    final dynamic sl = bizData['subscriptionEnd'];
    final subEnd = sl is Timestamp ? sl.toDate() : (sl is String ? DateTime.tryParse(sl) : null);
    
    if (status != 'active') return false;
    if (subEnd != null && subEnd.isBefore(DateTime.now())) return false;
    
    return true;
  }
}
