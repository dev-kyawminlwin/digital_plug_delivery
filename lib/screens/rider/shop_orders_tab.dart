import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';

class ShopOrdersTab extends StatelessWidget {
  final String businessId;
  const ShopOrdersTab({super.key, required this.businessId});

  static const Color _kPrimary = Color(0xFFFF5E1E);
  static const Color _kDark = Color(0xFF1F2937);

  Color _statusColor(OrderStatus s) => switch (s) {
        OrderStatus.lookingForRider => const Color(0xFFF59E0B),
        OrderStatus.assigned => const Color(0xFF3B82F6),
        OrderStatus.pickedUp => _kPrimary,
        OrderStatus.arrived => const Color(0xFF8B5CF6),
        OrderStatus.completed => const Color(0xFF10B981),
        OrderStatus.cancelled => const Color(0xFFEF4444),
      };

  String _statusLabel(OrderStatus s) => switch (s) {
        OrderStatus.lookingForRider => '🔔 New Order',
        OrderStatus.assigned => '🏍 Assigned',
        OrderStatus.pickedUp => '📦 Picked Up',
        OrderStatus.arrived => '📍 Arrived',
        OrderStatus.completed => '✅ Delivered',
        OrderStatus.cancelled => '❌ Cancelled',
      };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              indicatorColor: _kPrimary,
              labelColor: _kPrimary,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ordersList(active: true),
                _ordersList(active: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ordersList({required bool active}) {
    final activeStatuses = [
      OrderStatus.lookingForRider.name,
      OrderStatus.assigned.name,
      OrderStatus.pickedUp.name,
      OrderStatus.arrived.name,
    ];

    Stream<QuerySnapshot> stream;
    if (active) {
      stream = FirebaseFirestore.instance
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .where('status', whereIn: activeStatuses)
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;
        // For history, filter to completed/cancelled only
        final filtered = active
            ? docs
            : docs.where((d) {
                final s = (d.data() as Map)['status'] as String? ?? '';
                return s == OrderStatus.completed.name || s == OrderStatus.cancelled.name;
              }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(active ? Icons.inbox_rounded : Icons.history_rounded,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(active ? 'No active orders right now' : 'No order history yet',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
            ]),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final data = filtered[i].data() as Map<String, dynamic>;
            final orderId = filtered[i].id;
            final status = OrderStatus.values.firstWhere(
              (s) => s.name == data['status'],
              orElse: () => OrderStatus.lookingForRider,
            );
            final items = (data['items'] as List? ?? []);
            final total = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
            final customer = data['customerName'] as String? ?? 'Customer';
            final address = data['deliveryAddress'] as String? ?? '';

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('#${orderId.substring(0, 6).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.w900,
                              fontSize: 13, color: _kDark, letterSpacing: 1)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_statusLabel(status),
                            style: TextStyle(
                                color: _statusColor(status),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(customer, style: const TextStyle(fontSize: 13, color: _kDark)),
                  ]),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(address,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                  const SizedBox(height: 10),
                  // Items
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: items.take(3).map((item) {
                      final name = item['name'] as String? ?? '';
                      final qty = item['quantity'] as int? ?? 1;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${qty}x $name',
                            style: const TextStyle(fontSize: 11, color: _kDark)),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${items.length} items',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    Text('THB ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _kPrimary)),
                  ]),
                  // Action button for new orders
                  if (status == OrderStatus.lookingForRider) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('orders')
                              .doc(orderId)
                              .update({'status': OrderStatus.assigned.name});
                        },
                        icon: const Icon(Icons.motorcycle_rounded, size: 18),
                        label: const Text('Accept & Dispatch'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
