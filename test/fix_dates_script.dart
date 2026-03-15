import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  print('Fixing Businesses collection...');
  final bizSnap = await FirebaseFirestore.instance.collection('businesses').get();
  for (final doc in bizSnap.docs) {
    final data = doc.data();
    final updates = <String, dynamic>{};
    
    if (data['createdAt'] is String) {
      updates['createdAt'] = Timestamp.fromDate(DateTime.parse(data['createdAt']));
      print('Fixed createdAt for business ${doc.id}');
    }
    if (data['subscriptionEnd'] is String) {
      updates['subscriptionEnd'] = Timestamp.fromDate(DateTime.parse(data['subscriptionEnd']));
      print('Fixed subscriptionEnd for business ${doc.id}');
    }
    
    if (updates.isNotEmpty) {
      await doc.reference.update(updates);
    }
  }

  print('Fixing Users collection...');
  final userSnap = await FirebaseFirestore.instance.collection('users').get();
  for (final doc in userSnap.docs) {
    final data = doc.data();
    final updates = <String, dynamic>{};
    
    if (data['createdAt'] is String) {
      updates['createdAt'] = Timestamp.fromDate(DateTime.parse(data['createdAt']));
      print('Fixed createdAt for user ${doc.id}');
    }
    if (data['subscriptionEnd'] is String) {
      updates['subscriptionEnd'] = Timestamp.fromDate(DateTime.parse(data['subscriptionEnd']));
      print('Fixed subscriptionEnd for user ${doc.id}');
    }
    
    if (updates.isNotEmpty) {
      await doc.reference.update(updates);
    }
  }

  print('Done fixing Firestore!');
}
