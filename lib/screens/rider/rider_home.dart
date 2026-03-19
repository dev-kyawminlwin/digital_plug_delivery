import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/location_service.dart';
import 'rider_fleet_map_screen.dart';
import '../shared/chat_screen.dart';
import '../shared/guest_language_switcher.dart';
import '../../l10n/app_localizations.dart';
import 'add_shop_screen.dart';
import 'shop_management_screen.dart';

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
  static const Color _kPrimary = Color(0xFFFF5E1E);    // FoodXa Orange
  static const Color _kPrimaryDark = Color(0xFFD94A1A);
  static const Color _kCard = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    _tabController = TabController(length: 6, vsync: this);
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
        if (!riderSnapshot.hasData) return const Scaffold(backgroundColor: _kBg, body: Center(child: CircularProgressIndicator(color: _kPrimary)));

        final data = riderSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final businessId = data['businessId'];
        final walletBalance = (data['walletBalance'] as num?)?.toDouble() ?? 0.0;
        final collectedCash = (data['collectedCash'] as num?)?.toDouble() ?? 0.0;
        final riderName = data['name'] as String? ?? 'Rider';
        final isAvailable = data['isAvailable'] as bool? ?? false;

        // Removed early exit for businessId. Riders are now fully independent platform operators.

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
                                Row(
                                  children: [
                                    const Icon(Icons.motorcycle_rounded, color: _kPrimary, size: 18),
                                    const SizedBox(width: 6),
                                    Text(AppLocalizations.of(context)!.riderPanel,
                                        style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
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
                                          ? _kPrimary.withOpacity(0.2)
                                          : Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isAvailable ? _kPrimary : Colors.white24,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8, height: 8,
                                          decoration: BoxDecoration(
                                            color: isAvailable ? _kPrimary : Colors.white38,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isAvailable ? AppLocalizations.of(context)!.online : AppLocalizations.of(context)!.offline,
                                          style: TextStyle(
                                            color: isAvailable ? _kPrimary : Colors.white60,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Language switcher
                                const DashboardLanguageSwitcher(),
                                const SizedBox(width: 10),
                                // Logout
                                GestureDetector(
                                  onTap: _logout,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
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
                            _walletChip("💰 ${AppLocalizations.of(context)!.wallet}", "THB ${walletBalance.toStringAsFixed(0)}", _kPrimary),
                            const SizedBox(width: 12),
                            _walletChip("💵 ${AppLocalizations.of(context)!.cashToDrop}", "THB ${collectedCash.toStringAsFixed(0)}", Colors.redAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Tab Bar
                      TabBar(
                        controller: _tabController,
                        indicatorColor: _kPrimary,
                        indicatorWeight: 3,
                        labelColor: _kPrimary,
                        unselectedLabelColor: Colors.white38,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        tabs: [
                          // My Shops tab
                          Tab(
                            icon: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('businesses')
                                  .where('ownedByRiderId', isEqualTo: uid)
                                  .snapshots(),
                              builder: (ctx, s) {
                                final count = s.data?.docs.length ?? 0;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.storefront_rounded, size: 20),
                                    if (count > 0)
                                      Positioned(
                                        top: -4, right: -6,
                                        child: Container(
                                          width: 14, height: 14,
                                          decoration: const BoxDecoration(
                                              color: Color(0xFF10B981), shape: BoxShape.circle),
                                          child: Center(
                                            child: Text('$count',
                                                style: const TextStyle(
                                                    color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            text: 'My Shops',
                          ),
                          Tab(icon: const Icon(Icons.delivery_dining_rounded, size: 20), text: AppLocalizations.of(context)!.myOrders),
                          Tab(icon: const Icon(Icons.radar_rounded, size: 20), text: AppLocalizations.of(context)!.radar),
                          Tab(icon: const Icon(Icons.map_rounded, size: 20), text: AppLocalizations.of(context)!.fleetMap),
                          const Tab(icon: Icon(Icons.account_balance_wallet_rounded, size: 20), text: 'Earnings'),
                          Tab(
                            icon: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('orders')
                                  .doc('admin_rider_$uid')
                                  .collection('messages')
                                  .snapshots(),
                              builder: (ctx, snap) {
                                final count = snap.data?.docs.length ?? 0;
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.chat_bubble_rounded, size: 20),
                                    if (count > 0)
                                      Positioned(
                                        top: -4,
                                        right: -6,
                                        child: Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            text: 'Messages',
                          ),
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
                    _buildMyShopsTab(),
                    _buildMyDeliveriesTab(data, walletBalance, collectedCash),
                    _buildOrderRadarTab(riderName),
                    const RiderFleetMapScreen(),
                    _buildEarningsTab(),
                    _buildMessagesTab(),
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

  Widget _buildOrderRadarTab(String riderName) {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getAvailableOrders(),
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
                border: Border.all(color: _kPrimary.withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(color: _kPrimary.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))
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
                            color: _kPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                         ),
                          child: const Text("NEW ORDER",
                              style: TextStyle(color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                        const Spacer(),
                        Text("THB ${order.totalPrice.toStringAsFixed(0)}",
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
                          backgroundColor: _kPrimary,
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

  Widget _buildMyDeliveriesTab(Map<String, dynamic> data, double walletBalance, double collectedCash) {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderService.getRiderOrders(uid),
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
                    backgroundColor: _kPrimaryDark,
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
                          backgroundColor: _kPrimary,
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
                            child: Text(order.status.displayName,
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
                              style: const TextStyle(color: Color(0xFFFF5E1E), fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(
                            "💰 THB ${order.totalPrice.toStringAsFixed(0)} • ${order.paymentMethod}",
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
                              if (order.customerLat != 0.0 && order.customerLng != 0.0)
                                IconButton(
                                  iconSize: 20,
                                  icon: const Icon(Icons.navigation_rounded, color: Colors.green),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.green.withValues(alpha: 0.1),
                                    shape: const CircleBorder(),
                                  ),
                                  onPressed: () async {
                                    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${order.customerLat},${order.customerLng}');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    }
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
      OrderStatus.assigned: ('PICK UP', Colors.blue),
      OrderStatus.pickedUp: ('I\'VE ARRIVED', Colors.deepPurple),
      OrderStatus.arrived: ('COMPLETE ✓', _kPrimary),
    };
    final stage = stages[order.status];
    if (stage == null) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: () {
        final nextStatus = {
          OrderStatus.assigned: OrderStatus.pickedUp,
          OrderStatus.pickedUp: OrderStatus.arrived,
          OrderStatus.arrived: OrderStatus.completed,
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

  Widget _buildEarningsTab() {
    if (uid.isEmpty) {
      return const Center(child: Text('Please log in to view earnings', style: TextStyle(color: Colors.white54)));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('riderId', isEqualTo: uid)
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        // Weekly totals (last 7 days)
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        double weeklyTotal = 0;
        int weeklyCount = 0;
        double allTimeTotal = 0;

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final fee = (data['deliveryFee'] as num?)?.toDouble() ?? 0.0;
          allTimeTotal += fee;
          final ts = data['createdAt'];
          if (ts != null && ts is Timestamp) {
            final date = ts.toDate();
            if (date.isAfter(weekAgo)) {
              weeklyTotal += fee;
              weeklyCount++;
            }
          }
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Summary Cards ─────────────────────────────────────────────
            Row(
              children: [
                _earningCard('This Week', 'THB ${weeklyTotal.toStringAsFixed(0)}', '$weeklyCount orders', const Color(0xFFFF5E1E)),
                const SizedBox(width: 12),
                _earningCard('All Time', 'THB ${allTimeTotal.toStringAsFixed(0)}', '${docs.length} orders', const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Completed Deliveries',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // ── Per-order list (newest first) ─────────────────────────────
            if (docs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 56, color: Colors.white12),
                      const SizedBox(height: 12),
                      const Text('No completed deliveries yet', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                ),
              )
            else
              ...docs.reversed.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final fee = (data['deliveryFee'] as num?)?.toDouble() ?? 0.0;
                final name = data['customerName'] ?? 'Customer';
                final address = data['address'] ?? '';
                final ts = data['createdAt'];
                String dateStr = '';
                if (ts != null && ts is Timestamp) {
                  final d = ts.toDate();
                  dateStr = '${d.day}/${d.month}/${d.year}';
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _kPrimary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delivery_dining_rounded, color: _kPrimary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(address, style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            if (dateStr.isNotEmpty)
                              Text(dateStr, style: const TextStyle(color: Colors.white24, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text(
                        '+THB ${fee.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _earningCard(String title, String amount, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ── MY SHOPS TAB ──────────────────────────────────────────────────────────
  Widget _buildMyShopsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .where('ownedByRiderId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        return Stack(
          children: [
            if (!snap.hasData)
              const Center(child: CircularProgressIndicator(color: Color(0xFFFF5E1E)))
            else if (docs.isEmpty)
              _emptyShopsState()
            else
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                children: [
                  // Summary bar
                  Row(children: [
                    _shopStat('${docs.where((d) => (d.data() as Map)['status'] == 'approved').length}', 'Active', Colors.greenAccent),
                    const SizedBox(width: 12),
                    _shopStat('${docs.where((d) => (d.data() as Map)['status'] == 'pending').length}', 'Pending', const Color(0xFFFBBF24)),
                    const SizedBox(width: 12),
                    _shopStat('${docs.length}', 'Total', Colors.white),
                  ]),
                  const SizedBox(height: 20),
                  const Text('YOUR SHOPS',
                      style: TextStyle(color: Colors.white38, fontSize: 11,
                          fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  ...docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final status = d['status'] as String? ?? 'pending';
                    final name = d['name'] as String? ?? 'Shop';
                    final logo = d['logo'] as String? ?? '';
                    final address = d['address'] as String? ?? '';
                    final isOpen = d['isOpen'] as bool? ?? false;
                    final approved = status == 'approved';
                    final rejected = status == 'rejected';

                    return GestureDetector(
                      onTap: approved
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ShopManagementScreen(
                                    businessId: doc.id,
                                    shopName: name,
                                    shopLogo: logo,
                                  ),
                                ),
                              )
                          : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _kCard,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: approved
                                ? (isOpen ? const Color(0xFF10B981) : Colors.white12)
                                : rejected
                                    ? const Color(0xFFEF4444).withOpacity(0.5)
                                    : const Color(0xFFFBBF24).withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            // Logo
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white10,
                                border: Border.all(color: Colors.white12),
                              ),
                              child: ClipOval(
                                child: logo.isNotEmpty
                                    ? Image.memory(base64Decode(logo), fit: BoxFit.cover)
                                    : const Icon(Icons.storefront_rounded,
                                        color: Colors.white38, size: 28),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(name,
                                          style: TextStyle(
                                              color: approved ? Colors.white : Colors.white54,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16)),
                                    ),
                                    // Status badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: approved
                                            ? const Color(0xFF10B981).withOpacity(0.2)
                                            : rejected
                                                ? const Color(0xFFEF4444).withOpacity(0.2)
                                                : const Color(0xFFFBBF24).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        approved ? (isOpen ? '● Open' : '○ Closed') : status.toUpperCase(),
                                        style: TextStyle(
                                          color: approved
                                              ? (isOpen ? const Color(0xFF10B981) : Colors.white38)
                                              : rejected
                                                  ? const Color(0xFFEF4444)
                                                  : const Color(0xFFFBBF24),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(address,
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                      overflow: TextOverflow.ellipsis),
                                  if (rejected && (d['rejectionReason'] as String? ?? '').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text('Reason: ${d['rejectionReason']}',
                                          style: const TextStyle(
                                              color: Color(0xFFEF4444), fontSize: 11)),
                                    ),
                                  if (approved) ...[
                                    const SizedBox(height: 8),
                                    // Live order count
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('orders')
                                          .where('businessId', isEqualTo: doc.id)
                                          .where('status', isEqualTo: 'looking_for_rider')
                                          .snapshots(),
                                      builder: (ctx, oSnap) {
                                        final count = oSnap.data?.docs.length ?? 0;
                                        return Row(children: [
                                          Icon(Icons.receipt_long_rounded,
                                              size: 13,
                                              color: count > 0 ? _kPrimary : Colors.white30),
                                          const SizedBox(width: 4),
                                          Text(
                                            count > 0 ? '$count new order${count > 1 ? 's' : ''}!' : 'No pending orders',
                                            style: TextStyle(
                                                color: count > 0 ? _kPrimary : Colors.white30,
                                                fontSize: 12,
                                                fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal),
                                          ),
                                        ]);
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (approved)
                              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            // FAB — Add Shop
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddShopScreen()),
                ),
                backgroundColor: _kPrimary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add a Shop',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _shopStat(String value, String label, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.25))),
          child: Column(children: [
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 22)),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ),
      );

  Widget _emptyShopsState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.storefront_outlined,
                  color: Color(0xFFFF5E1E), size: 48),
            ),
            const SizedBox(height: 20),
            const Text('No Shops Yet',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 8),
            const Text(
              'Partner with local coffee shops and restaurants.\nAdd their menus and start taking digital orders!',
              style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddShopScreen()),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Your First Shop',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ]),
        ),
      );

  // ── MESSAGES TAB ──────────────────────────────────────────────────────────
  Widget _buildMessagesTab() {
    final channelId = 'admin_rider_$uid';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .doc(channelId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        final hasMessages = (snap.data?.docs.isNotEmpty) ?? false;
        final lastMsg = hasMessages
            ? (snap.data!.docs.first.data() as Map)['text'] as String? ?? ''
            : 'No messages yet — tap to start chatting';

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            const Text(
              'INBOX',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            // Shop Owner conversation card
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    orderId: channelId,
                    otherPartyName: 'Shop Owner',
                  ),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasMessages
                        ? _kPrimary.withOpacity(0.4)
                        : Colors.white12,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF5E1E), Color(0xFFFF8045)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(Icons.storefront_rounded,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shop Owner',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lastMsg,
                            style: TextStyle(
                              color: hasMessages
                                  ? Colors.white60
                                  : Colors.white30,
                              fontSize: 13,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                    // Unread dot
                    if (hasMessages)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5E1E),
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tip card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.white30, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Messages from your shop owner appear here. You\'ll see a red dot on this tab when new messages arrive.',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}