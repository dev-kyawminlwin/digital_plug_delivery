import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/order_model.dart';
import 'package:intl/intl.dart';
import 'track_order_screen.dart';

class CustomerOrderHistoryTab extends StatefulWidget {
  const CustomerOrderHistoryTab({super.key});

  @override
  State<CustomerOrderHistoryTab> createState() => _CustomerOrderHistoryTabState();
}

class _CustomerOrderHistoryTabState extends State<CustomerOrderHistoryTab> {
  static const Color _kPrimary = Color(0xFFFF5E1E);
  int _tabIndex = 0; // 0 = Active, 1 = Past

  void _showRatingDialog(BuildContext context, OrderModel order) {
    int rating = 5;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text("Rate Your Order", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("How was the food?", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => rating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                            color: const Color(0xFFEAB308),
                            size: 38,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('orders').doc(order.id).update({'rating': rating});
                    await FirebaseFirestore.instance
                        .collection('businesses')
                        .doc(order.businessId)
                        .collection('reviews')
                        .add({
                      'rating': rating,
                      'customerId': FirebaseAuth.instance.currentUser!.uid,
                      'orderId': order.id,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Submit", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bottomPad = MediaQuery.of(context).padding.bottom + 96;

    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text("Please log in to see your order history.",
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Tab Switcher
        SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tabIndex == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _tabIndex == 0 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                      ),
                      child: Center(child: Text("Active Orders", style: TextStyle(fontWeight: FontWeight.bold, color: _tabIndex == 0 ? _kPrimary : Colors.grey.shade500))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tabIndex = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tabIndex == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _tabIndex == 1 ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))] : [],
                      ),
                      child: Center(child: Text("Past Orders", style: TextStyle(fontWeight: FontWeight.bold, color: _tabIndex == 1 ? const Color(0xFF1F2937) : Colors.grey.shade500))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('customerId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final allDocs = snapshot.data!.docs.toList();
              
              // Filter active vs past
              final activeStatuses = ['pending', 'accepted', 'looking_for_rider', 'assigned', 'picked_up', 'arrived'];
              final docs = allDocs.where((d) {
                final status = (d.data() as Map<String, dynamic>)['status'] as String? ?? '';
                if (_tabIndex == 0) return activeStatuses.contains(status);
                return !activeStatuses.contains(status);
              }).toList();

              // Sort newest first
              docs.sort((a, b) {
                final tA = (a.data() as Map<String, dynamic>)['createdAt'];
                final tB = (b.data() as Map<String, dynamic>)['createdAt'];
                final dateA = tA is Timestamp ? tA.toDate() : (tA is String ? DateTime.tryParse(tA) ?? DateTime.now() : DateTime.now());
                final dateB = tB is Timestamp ? tB.toDate() : (tB is String ? DateTime.tryParse(tB) ?? DateTime.now() : DateTime.now());
                return dateB.compareTo(dateA);
              });

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_tabIndex == 0 ? Icons.electric_moped_rounded : Icons.history_rounded, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(_tabIndex == 0 ? "No active orders right now." : "No past orders found.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.6)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPad),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final order = OrderModel.fromMap(data, docs[index].id);
                  final bool isCompleted = order.status == 'completed';
                  final hasRated = data.containsKey('rating');
                  final statusColor = OrderModel.getStatusColor(order.status);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Status Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.08),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                                style: const TextStyle(color: Color(0xFF1F2937), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.2), blurRadius: 4)]
                                ),
                                child: Text(
                                  order.status.toUpperCase().replaceAll('_', ' '),
                                  style: TextStyle(
                                      color: statusColor, fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Shop name lookup
                              FutureBuilder<DocumentSnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('businesses')
                                    .doc(order.businessId)
                                    .get(),
                                builder: (context, bizSnap) {
                                  final bizName = bizSnap.hasData && bizSnap.data!.exists
                                      ? (bizSnap.data!.data() as Map<String, dynamic>)['name'] ?? 'Restaurant'
                                      : 'Restaurant';
                                  return Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
                                        child: const Icon(Icons.storefront_rounded, size: 18, color: _kPrimary),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        bizName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1F2937)),
                                      ),
                                    ],
                                  );
                                },
                              ),

                              // Items preview
                              if (data['itemsSummary'] != null && data['itemsSummary'].toString().trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Text(
                                    data['itemsSummary'].toString().trim(),
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5, fontWeight: FontWeight.w500),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Total Paid", style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                      Text(
                                        "฿${(order.totalPrice + order.deliveryFee).toStringAsFixed(0)}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900, color: Color(0xFF1F2937), fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  if (isCompleted && !hasRated)
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.star_rounded, size: 16),
                                      label: const Text("Rate Order", style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFFBEB),
                                        foregroundColor: const Color(0xFFD97706),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      onPressed: () => _showRatingDialog(context, order),
                                    )
                                  else if (hasRated)
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 18),
                                        const SizedBox(width: 4),
                                        Text("${data['rating']}/5 rated",
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFFD97706))),
                                      ],
                                    )
                                  else if (!isCompleted && order.status != 'cancelled')
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.map_rounded, size: 16),
                                      label: const Text("Track", style: TextStyle(fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _kPrimary,
                                        foregroundColor: Colors.white,
                                        elevation: 8,
                                        shadowColor: _kPrimary.withValues(alpha: 0.4),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => TrackOrderScreen(orderId: order.id)),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
