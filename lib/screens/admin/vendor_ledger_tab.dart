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
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 72, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text('No sales yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                const SizedBox(height: 6),
                Text('Completed orders appear here 📋', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              ],
            ),
          );
        }

        double totalRevenue = 0;
        final List<OrderModel> completedOrders = [];

        for (var doc in docs) {
          final order = OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          completedOrders.add(order);
          totalRevenue += order.totalPrice;
        }

        // Locally sort to avoid composite index
        completedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return Column(
          children: [
            // ── Premium Revenue Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gross Revenue',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'THB ${totalRevenue.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 15),
                          const SizedBox(width: 6),
                          Text('${completedOrders.length} completed orders',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                        ]),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Builder(
                      builder: (innerCtx) => IconButton(
                        icon: Icon(Icons.cleaning_services_rounded, color: Colors.white.withValues(alpha: 0.6)),
                        tooltip: 'Clear Ledger Data',
                        onPressed: () {
                          showDialog(
                            context: innerCtx,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: const Text('Clear Shop Ledger?'),
                              content: const Text('This permanently deletes all completed orders for your shop. Cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(innerCtx), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  onPressed: () async {
                                    Navigator.pop(innerCtx);
                                    final snap = await FirebaseFirestore.instance
                                        .collection('orders')
                                        .where('businessId', isEqualTo: businessId)
                                        .where('status', isEqualTo: 'completed')
                                        .get();
                                    for (var doc in snap.docs) {
                                      await doc.reference.delete();
                                    }
                                  },
                                  child: const Text('Clear Data'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Transaction List ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                itemCount: completedOrders.length,
                itemBuilder: (context, index) {
                  final order = completedOrders[index];
                  final isCash = order.paymentMethod == 'Cash';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38, height: 38,
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCash ? Icons.payments_rounded : Icons.credit_card_rounded,
                            color: Colors.green.shade600,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.customerName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937))),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+ THB ${order.totalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isCash ? Colors.orange.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isCash ? 'Cash' : 'Online',
                                style: TextStyle(
                                  color: isCash ? Colors.orange.shade700 : Colors.blue.shade700,
                                  fontSize: 10, fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
