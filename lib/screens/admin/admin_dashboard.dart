import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'menu_manager_tab.dart';
import 'vendor_ratings_tab.dart';
import 'vendor_ledger_tab.dart';
import 'vendor_fleet_tab.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/image_helper.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  static const Color _kPrimary = Color(0xFF1E3A8A);
  static const Color _kGold = Color(0xFFEAB308);
  static const Color _kDark = Color(0xFF1F2937);

  String get _currentTabTitle {
    switch (_currentIndex) {
      case 0: return "Live Orders";
      case 1: return "My Shop";
      case 2: return "Menu Manager";
      case 3: return "Ratings";
      case 4: return "Ledger";
      case 5: return "Fleet";
      default: return "Admin Dashboard";
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final userData = userSnap.data!.data() as Map<String, dynamic>;
        final businessId = userData['businessId'] as String? ?? '';
        final adminName = userData['name'] as String? ?? 'Admin';

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('businesses').doc(businessId).get(),
          builder: (context, bizSnap) {
            final bizData = bizSnap.hasData && bizSnap.data!.exists
                ? bizSnap.data!.data() as Map<String, dynamic>
                : <String, dynamic>{};
            final bizName = bizData['name'] as String? ?? 'Your Shop';

            final List<Widget> tabs = [
              _buildOrdersTab(businessId),
              _buildShopPreviewTab(businessId, bizData),
              MenuManagerTab(businessId: businessId),
              VendorRatingsTab(businessId: businessId),
              VendorLedgerTab(businessId: businessId),
              VendorFleetTab(businessId: businessId),
            ];

            return Scaffold(
              backgroundColor: const Color(0xFFF9FAFB),
              body: Column(
                children: [
                  // Gradient Header
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bizName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentTabTitle,
                                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                // Live order count badge
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('orders')
                                      .where('businessId', isEqualTo: businessId)
                                      .where('status', isNotEqualTo: 'completed')
                                      .snapshots(),
                                  builder: (context, snap) {
                                    final count = snap.data?.docs.length ?? 0;
                                    if (count == 0) return const SizedBox.shrink();
                                    return Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "$count Live",
                                        style: const TextStyle(
                                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    );
                                  },
                                ),
                                // Profile / Logout
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: Text("Hi, $adminName"),
                                        content: const Text("What would you like to do?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text("Cancel"),
                                          ),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.logout),
                                            label: const Text("Log Out"),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              await FirebaseAuth.instance.signOut();
                                              // AuthGate StreamBuilder handles redirect automatically
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Body
                  Expanded(child: tabs[_currentIndex]),
                ],
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4)),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _navItem(0, Icons.receipt_long_rounded, Icons.receipt_long_outlined, "Orders"),
                        _navItem(1, Icons.storefront_rounded, Icons.storefront_outlined, "Shop"),
                        _navItem(2, Icons.restaurant_menu_rounded, Icons.restaurant_menu_outlined, "Menu"),
                        _navItem(3, Icons.star_rounded, Icons.star_outline_rounded, "Ratings"),
                        _navItem(4, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, "Ledger"),
                        _navItem(5, Icons.motorcycle_rounded, Icons.motorcycle_rounded, "Fleet"),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? _kPrimary : Colors.grey.shade400,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _kPrimary : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB 0: LIVE ORDERS ───────────────────────────────────────────────
  Widget _buildOrdersTab(String businessId) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService().getOrders(businessId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final orders = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAnalyticsHeader(orders),
            const SizedBox(height: 16),
            const Text("Live Orders",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kDark)),
            const SizedBox(height: 12),
            ...orders.where((o) => o.status != 'completed').map((order) => _buildOrderCard(order)).toList(),
            if (orders.where((o) => o.status != 'completed').isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text("All caught up! No active orders.", style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsHeader(List<OrderModel> orders) {
    final today = DateTime.now();
    final deliveredToday = orders.where((o) =>
        o.status == 'completed' && o.createdAt.day == today.day).toList();
    final allTimeCompleted = orders.where((o) => o.status == 'completed').toList();
    double todayRevenue = deliveredToday.fold(0, (sum, item) => sum + item.totalPrice + item.deliveryFee);
    double allTimeRevenue = allTimeCompleted.fold(0, (sum, item) => sum + item.totalPrice + item.deliveryFee);
    double aov = allTimeCompleted.isEmpty ? 0 : allTimeRevenue / allTimeCompleted.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Revenue", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  Text("MMK ${todayRevenue.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("All-Time", style: TextStyle(color: Colors.white60, fontSize: 11)),
                  Text("MMK ${allTimeRevenue.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _analyticsChip("Delivered Today", "${deliveredToday.length}"),
              _analyticsChip("Active Orders", "${orders.where((o) => o.status != 'completed').length}"),
              _analyticsChip("Avg Order", "MMK ${aov.toStringAsFixed(0)}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _analyticsChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final statusColor = OrderModel.getStatusColor(order.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.07),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kDark)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order.status.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.itemsSummary.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      order.itemsSummary,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(child: Text(order.address, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Clipboard.setData(ClipboardData(text: order.phone)),
                      child: Text(order.phone, style: const TextStyle(fontSize: 12, color: _kPrimary, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "MMK ${(order.totalPrice + order.deliveryFee).toStringAsFixed(0)} • ${order.paymentMethod}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                    ),
                    if (order.riderId.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("No Rider Yet",
                            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB 1: SHOP PREVIEW ─────────────────────────────────────────────
  Widget _buildShopPreviewTab(String businessId, Map<String, dynamic> bizData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image Card
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _kPrimary.withOpacity(0.08),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))
              ],
            ),
            child: Stack(
              children: [
                if (bizData['imageUrl'] != null && bizData['imageUrl'].toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      base64Decode(bizData['imageUrl']),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => const Icon(Icons.storefront, size: 72, color: _kPrimary),
                    ),
                  )
                else
                  Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.storefront_outlined, size: 60, color: _kPrimary),
                      const SizedBox(height: 8),
                      Text("No shop photo yet", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                    ]),
                  ),
                // Edit Button Overlay
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () async {
                      final b64 = await ImageHelper.pickAndCompressImage();
                      if (b64 != null) {
                        await FirebaseFirestore.instance
                            .collection('businesses')
                            .doc(businessId)
                            .update({'imageUrl': b64});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Shop photo updated!"),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.4), blurRadius: 8)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text("Edit Photo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Shop Name & Info
          Text(
            bizData['name'] ?? 'Your Shop',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _kDark),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text("● Active",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              if (bizData['deliveryFee'] != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text("Delivery: MMK ${bizData['deliveryFee']}",
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Menu Stats
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .where('businessId', isEqualTo: businessId)
                .snapshots(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              final available =
                  snap.data?.docs.where((d) => (d.data() as Map)['isAvailable'] == true).length ?? 0;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("MENU OVERVIEW",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 0.8)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _shopStat("$count", "Total Items", _kPrimary),
                        _shopStat("$available", "Available", Colors.green),
                        _shopStat("${count - available}", "Out of Stock", Colors.red),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick preview of all products
                    ...?snap.data?.docs.take(5).map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final isAvail = d['isAvailable'] as bool? ?? true;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isAvail ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(d['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              ],
                            ),
                            Text("MMK ${(d['basePrice'] ?? 0).toStringAsFixed(0)}",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                    if (count > 5)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text("+ ${count - 5} more items — see Menu tab",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _shopStat(String value, String label, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
    ]);
  }
}