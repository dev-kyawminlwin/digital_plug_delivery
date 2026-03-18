import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final _orders = FirebaseFirestore.instance.collection('orders');

  // Admin: Create new order
  Future<void> createOrder(OrderModel order) async {
    await _orders.add(order.toMap());
  }

  // Admin: Get all orders live for specific business
  Stream<List<OrderModel>> getOrders(String businessId) {
    return _orders
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
           final list = snapshot.docs
              .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
              .toList();
           list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
           return list;
        });
  }

  // Phase 9: Public available orders for broadcast dispatch
  Stream<List<OrderModel>> getAvailableOrders() {
    return _orders
        .where('status', isEqualTo: 'looking_for_rider')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Rider: Get only assigned/picked/arrived orders live
  Stream<List<OrderModel>> getRiderOrders(String uid) {
    return _orders
        .where('assignedRider', isEqualTo: uid)
        .where('status', whereIn: ['assigned', 'picked_up', 'arrived'])
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  // Phase 9: Safely Accept a Broadcasted Order
  Future<bool> acceptOrder(String orderId, String riderId, String riderName) async {
    final orderRef = _orders.doc(orderId);
    
    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);
      if (!snapshot.exists) return false;
      
      final currentStatus = snapshot.data()?['status'];
      
      // Concurrency check: Make sure no one else claimed it!
      if (currentStatus == 'looking_for_rider') {
        transaction.update(orderRef, {
          'status': 'assigned',
          'riderId': riderId,
          'assignedRider': riderId, // Keeping both fields for legacy compatibility
          'riderName': riderName,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false; // Someone else beat them to it!
    });
  }

  // Global: Update status (assigned -> picked_up -> arrived -> completed)
  Future<void> updateStatus(OrderModel order, String newStatus) async {
    final orderRef = _orders.doc(order.id);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // 1. Update the order document
      transaction.update(orderRef, {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. If completed, reward the rider AND the customer
      if (newStatus == 'completed') {
        // Reward Rider
        if (order.assignedRider.isNotEmpty) {
          final riderRef = FirebaseFirestore.instance.collection('users').doc(order.assignedRider);
          
          final Map<String, dynamic> riderUpdates = {
            'walletBalance': FieldValue.increment(order.deliveryFee),
          };

          if (order.paymentMethod == 'Cash') {
            riderUpdates['collectedCash'] = FieldValue.increment(order.totalPrice);
          }

          transaction.update(riderRef, riderUpdates);
        }

        // Reward Customer with Gamified Points (e.g. 50 points for 5000 THB order)
        if (order.customerId.isNotEmpty) {
          final customerRef = FirebaseFirestore.instance.collection('users').doc(order.customerId);
          int pointsEarned = (order.totalPrice / 100).floor();
          
          transaction.set(customerRef, {
            'points': FieldValue.increment(pointsEarned),
          }, SetOptions(merge: true));
        }
      }
    });
  }
}
