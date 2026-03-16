import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import 'package:intl/intl.dart';

class VendorLedgerTab extends StatelessWidget {
  final String businessId;

  const VendorLedgerTab({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("No completed sales yet."));

        double totalRevenue = 0;
        final List<OrderModel> completedOrders = [];

        for(var doc in docs) {
          final order = OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          completedOrders.add(order);
          totalRevenue += order.totalPrice; // Assuming shop keeps total price minus delivery fee, or shop keeps food price. The deliveryFee is usually separate.
        }
        
        // Locally sort to avoid requiring composite indexes for 'status' + 'createdAt'
        completedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981), // Green
              ),
              child: Column(
                children: [
                  const Text("Gross Revenue", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("MMK ${totalRevenue.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("${completedOrders.length} Completed Orders", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: completedOrders.length,
                itemBuilder: (context, index) {
                  final order = completedOrders[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200))
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(DateFormat('MMM dd, yyyy').format(order.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("+ MMK ${order.totalPrice.toStringAsFixed(0)}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text((order.paymentMethod == 'Cash') ? 'Cash on Delivery' : 'Paid Online', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        );
      },
    );
  }
}
