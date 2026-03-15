import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/location_service.dart';
import 'rider_fleet_map_screen.dart';
import '../shared/chat_screen.dart';

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  LocationService? _locationService;
  late String uid;
  late TabController _tabController;
  int _tabIndex = 0;

  // Dark Green Rider Theme
  static const Color _kBg = Color(0xFF0F172A);      // Near-black background
  static const Color _kGreen = Color(0xFF10B981);    // Emerald green
  static const Color _kGreenDark = Color(0xFF059669);
  static const Color _kCard = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() => _tabIndex = _tabController.index));
    if (uid.isNotEmpty) {
      _locationService = LocationService(uid: uid);
      _locationService!.startTracking().catchError((e) {});
    }
  }

  @override
  void dispose() {
    _locationService?.stopTracking();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    _locationService?.stopTracking();
    await FirebaseAuth.instance.signOut();
    // AuthGate handles redirect
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, riderSnapshot) {
        if (!riderSnapshot.hasData) return const Scaffold(backgroundColor: _kBg, body: Center(child: CircularProgressIndicator(color: _kGreen)));

        final data = riderSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final businessId = data['businessId'];
        final walletBalance = (data['walletBalance'] as num?)?.toDouble() ?? 0.0;
        final collectedCash = (data['collectedCash'] as num?)?.toDouble() ?? 0.0;
        final riderName = data['name'] as String? ?? 'Rider';
        final isAvailable = data['isAvailable'] as bool? ?? false;

        if (businessId == null) {
          return Scaffold(
            backgroundColor: _kBg,
            body: Center(
              child: Text("No business assigned. Contact your admin.",
                  style: const TextStyle(color: Colors.white60, fontSize: 15)),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: Column(
            children: [
              // ── Dark Header ──────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.motorcycle_rounded, color: _kGreen, size: 18),
                                    SizedBox(width: 6),
                                    Text("RIDER PANEL",
                                        style: TextStyle(color: _kGreen, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(riderName,
                                    style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Row(
                              children: [
                                // Online/Offline toggle pill
                                GestureDetector(
                                  onTap: () async {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .update({'isAvailable': !isAvailable});
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isAvailable
                                          ? _kGreen.withValues(alpha: 0.2)
                                          : Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isAvailable ? _kGreen : Colors.white24,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8, height: 8,
                                          decoration: BoxDecoration(
                                            color: isAvailable ? _kGreen : Colors.white38,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isAvailable ? "Online" : "Offline",
                                          style: TextStyle(
                                            color: isAvailable ? _kGreen : Colors.white60,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Logout
                                GestureDetector(
                                  onTap: _logout,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.logout_rounded, color: Colors.white60, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Wallet Quick View
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _walletChip("💰 Wallet", "MMK ${walletBalance.toStringAsFixed(0)}", _kGreen),
                            const SizedBox(width: 12),
                            _walletChip("💵 Cash to Drop", "MMK ${collectedCash.toStringAsFixed(0)}", Colors.redAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tab Bar
                      TabBar(
                        controller: _tabController,
                        indicatorColor: _kGreen,
                        indicatorWeight: 3,
                        labelColor: _kGreen,
                        unselectedLabelColor: Colors.white38,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        tabs: const [
                          Tab(icon: Icon(Icons.delivery_dining_rounded, size: 20), text: "My Orders"),
                          Tab(icon: Icon(Icons.radar_rounded, size: 20), text: "Radar"),
                          Tab(icon: Icon(Icons.map_rounded, size: 20), text: "Fleet Map"),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // ── Body ─────────────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMyDeliveriesTab(businessId, data, walletBalance, collectedCash),
                    _buildOrderRadarTab(riderName, businessId),
                    const RiderFleetMapScreen(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _walletChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRadarTab(String riderName, String businessId) {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getAvailableOrders(businessId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final availableOrders = snapshot.data!;

        if (availableOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radar_rounded, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text("All quiet! No new orders right now. 🛋️",
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: availableOrders.length,
          itemBuilder: (context, index) {
            final order = availableOrders[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _kGreen.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(color: _kGreen.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                         ),
                          child: const Text("NEW ORDER",
                              style: TextStyle(color: _kGreen, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                        const Spacer(),
                        Text("MMK ${order.totalPrice.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(order.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("📍 ${order.address}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    Text("💳 ${order.paymentMethod}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () async {
                          bool success = await _orderService.acceptOrder(order.id, uid, riderName);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? "✅ Order accepted! Check My Orders."
                                    : "⚡ Too slow! Another rider claimed it."),
                                backgroundColor: success ? Colors.green : Colors.orange,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text("⚡ ACCEPT ORDER",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyDeliveriesTab(String businessId, Map<String, dynamic> data, double walletBalance, double collectedCash) {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getRiderOrders(uid, businessId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final orders = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Settle Balances button
            if (collectedCash > 0 || walletBalance > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text("Settle Balances with Shop"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreenDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                      'walletBalance': 0,
                      'collectedCash': 0,
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Balances settled ✓"),
                          backgroundColor: _kGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  },
                ),
              ),

            const Text("Active Deliveries",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kBg)),
            const SizedBox(height: 12),

            if (orders.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded, size: 72, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text("No active deliveries. Check the Radar! 📡",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                    ],
                  ),
                ),
              ),

            ...orders.map((order) {
              final statusColor = OrderModel.getStatusColor(order.status);
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.07),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(order.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(order.status.toUpperCase().replaceAll('_', ' '),
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📍 ${order.address}", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text("📞 ${order.phone}",
                              style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(
                            "💰 MMK ${order.totalPrice.toStringAsFixed(0)} • ${order.paymentMethod}",
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                iconSize: 20,
                                icon: const Icon(Icons.chat_rounded, color: Colors.blue),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                  shape: const CircleBorder(),
                                ),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ChatScreen(orderId: order.id, otherPartyName: order.customerName),
                                  ));
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildActionButton(order),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildActionButton(OrderModel order) {
    final stages = {
      'assigned': ('PICK UP', Colors.blue),
      'picked_up': ('I\'VE ARRIVED', Colors.deepPurple),
      'arrived': ('COMPLETE ✓', _kGreen),
    };
    final stage = stages[order.status];
    if (stage == null) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: () {
        final nextStatus = {
          'assigned': 'picked_up',
          'picked_up': 'arrived',
          'arrived': 'completed',
        }[order.status]!;
        _orderService.updateStatus(order, nextStatus);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: stage.$2,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(stage.$1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}