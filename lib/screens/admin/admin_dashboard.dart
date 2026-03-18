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
  
  late Future<Map<String, dynamic>> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _loadDashboardData();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    final userData = userSnap.data() as Map<String, dynamic>? ?? {};
    final businessId = userData['businessId'] as String? ?? '';
    final adminName = userData['name'] as String? ?? 'Admin';

    final bizSnap = await FirebaseFirestore.instance.collection('businesses').doc(businessId).get();
    final bizData = bizSnap.exists ? bizSnap.data() as Map<String, dynamic> : <String, dynamic>{};

    return {
      'businessId': businessId,
      'adminName': adminName,
      'bizData': bizData,
    };
  }

  static const Color _kPrimary = Color(0xFFFF5E1E);
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
    return FutureBuilder<Map<String, dynamic>>(
      future: _dashboardDataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        }

        final data = snapshot.data!;
        final businessId = data['businessId'] as String;
        final adminName = data['adminName'] as String;
        final bizData = data['bizData'] as Map<String, dynamic>;
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
                        colors: [Color(0xFFFF5E1E), Color(0xFFD94A1A)],
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
                                      .snapshots(),
                                  builder: (context, snap) {
                                    if (!snap.hasData) return const SizedBox.shrink();
                                    
                                    // Filter locally to avoid requiring composite indexes
                                    final liveDocs = snap.data!.docs.where((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      return data['status'] != 'completed';
                                    }).toList();
                                    
                                    final count = liveDocs.length;
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
                                      color: Colors.white.withValues(alpha: 0.2),
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
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4)),
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
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? _kPrimary.withValues(alpha: 0.1) : Colors.transparent,
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
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? _kPrimary : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    ));
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
        boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
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
                  Text("THB ${todayRevenue.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("All-Time", style: TextStyle(color: Colors.white60, fontSize: 11)),
                  Text("THB ${allTimeRevenue.toStringAsFixed(0)}",
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
              _analyticsChip("Avg Order", "THB ${aov.toStringAsFixed(0)}"),
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
        color: Colors.white.withValues(alpha: 0.15),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.07),
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
                    color: statusColor.withValues(alpha: 0.12),
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
                      "THB ${(order.totalPrice + order.deliveryFee).toStringAsFixed(0)} • ${order.paymentMethod}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                    ),
                    if (order.riderId.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
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
              color: _kPrimary.withValues(alpha: 0.08),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6))
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
                        boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha: 0.4), blurRadius: 8)],
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
                  color: Colors.green.withValues(alpha: 0.1),
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
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text("Delivery: THB ${bizData['deliveryFee']}",
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
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
                            Text("THB ${(d['basePrice'] ?? 0).toStringAsFixed(0)}",
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
          
          const SizedBox(height: 20),

          // TEMPORARY BULK SEED BUTTON FOR PHINGPHA
          GestureDetector(
            onLongPress: () async {
              // Confirm dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Seed Menu?'),
                  content: const Text('This will inject 60+ PhingPha drinks into your menu. Proceed?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Seed')),
                  ],
                ),
              );

              if (confirm == true) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeding drinks...')));
                try {
                  final db = FirebaseFirestore.instance;
                  final drinks = [
                    {'name': 'Blue Hawaii Soda / บลูฮาวายโซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Blue Lemon Soda / บลูเลม่อนโซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Blueberry Soda / บลูเบอร์รี่โซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Kiwi Soda / กีวี่โซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Strawberry Soda / สตรอเบอร์รี่โซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Raspberry Soda / ราสเบอร์รี่โซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Passion Fruit Soda / เสาวรสโซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Lychee Soda / ลิ้นจี่โซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Green Apple Soda / แอปเปิ้ลเขียวโซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Lemon Soda / มะนาวโซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Grape Soda / องุ่นโซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Orange Soda / ส้มโซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Pineapple Soda / สับปะรดโซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Honey Lemon Soda / น้ำผึ้งมะนาวโซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Punch Soda / พันซ์โซดา', 'basePrice': 60, 'category': 'Italian Soda'},
                    {'name': 'Red Syrup Soda / น้ำแดงโซดา', 'basePrice': 60, 'category': 'Italian Soda'},

                    // --- Smoothies (สมูทตี้) 65 THB ---
                    {'name': 'Kiwi Smoothie / สมูทตี้กีวี่', 'basePrice': 65, 'category': 'Smoothies'},
                    {'name': 'Blueberry Smoothie / สมูทตี้บลูเบอร์รี่', 'basePrice': 65, 'category': 'Smoothies'},
                    {'name': 'Strawberry Smoothie / สมูทตี้สตรอเบอร์รี่', 'basePrice': 65, 'category': 'Smoothies'},
                    {'name': 'Raspberry Smoothie / สมูทตี้ราสเบอร์รี่', 'basePrice': 65, 'category': 'Smoothies'},
                    {'name': 'Passion Fruit Smoothie / สมูทตี้เสาวรส', 'basePrice': 65, 'category': 'Smoothies'},
                    {'name': 'Lychee Smoothie / สมูทตี้ลิ้นจี่', 'basePrice': 65, 'category': 'Smoothies'},
                    {'name': 'Green Apple Smoothie / สมูทตี้แอปเปิ้ลเขียว', 'basePrice': 65, 'category': 'Smoothies'},
                    {'name': 'Lemon Smoothie / สมูทตี้มะนาว', 'basePrice': 65, 'category': 'Smoothies'},
                    {'name': 'Yogurt Smoothie / สมูทตี้โยเกิร์ต', 'basePrice': 65, 'category': 'Smoothies'},

                    // --- Coffee with variants ---
                    {'name': 'Espresso / เอสเปรสโซ่', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75},
                    {'name': 'Americano / อเมริกาโน่', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75},
                    {'name': 'Cappuccino / คาปูชิโน่', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75},
                    {'name': 'Mocha / มอคค่า', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75},
                    {'name': 'Latte / ลาเต้', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75},
                    {'name': 'Honey Coffee / กาแฟน้ำผึ้ง', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75},
                    {'name': 'Black Coffee Honey / กาแฟดำน้ำผึ้ง', 'basePrice': 55, 'category': 'Coffee', 'hasVariants': true, 'icedPrice': 65, 'frappePrice': 75},
                    {'name': 'Black Coffee Orange / กาแฟดำน้ำส้ม', 'basePrice': 75, 'category': 'Coffee'},

                    // --- Tea ---
                    {'name': 'Thai Tea / ชาเย็น', 'basePrice': 55, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 60, 'frappePrice': 70},
                    {'name': 'Green Tea / ชาเขียว', 'basePrice': 55, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 60, 'frappePrice': 70},
                    {'name': 'Lemon Tea / ชามะนาว', 'basePrice': 50, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Honey Lemon Tea / ชาน้ำผึ้งมะนาว', 'basePrice': 50, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Apple Tea / ชาแอปเปิ้ล', 'basePrice': 50, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Peach Tea / ชาพีช', 'basePrice': 50, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Butterfly Pea Honey Lemon / อัญชันน้ำผึ้งมะนาว', 'basePrice': 50, 'category': 'Tea', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},

                    // --- Milk ---
                    {'name': 'Honey Lemon Milk / น้ำผึ้งมะนาว (นม)', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Fresh Milk / นมสด', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Honey Milk / นมน้ำผึ้ง', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Pink Milk (Sala) / นมชมพู', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Green Milk / นมเขียว', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Cocoa / โกโก้', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Matcha Latte / มัทฉะลาเต้', 'basePrice': 65, 'category': 'Milk'},
                    {'name': 'Caramel Fresh Milk / นมสดคาราเมล', 'basePrice': 50, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Banana Milk Frappe / กล้วยหอมนมสดปั่น', 'basePrice': 65, 'category': 'Milk'},
                    {'name': 'Oreo Milk / นมโอริโอ้', 'basePrice': 65, 'category': 'Milk'},
                    {'name': 'Butterfly Pea Milk / อัญชันนมสด', 'basePrice': 55, 'category': 'Milk', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Avocado / อะโวคาโด้', 'basePrice': 65, 'category': 'Milk'},
                    {'name': 'Coconut Milk / มะพร้าวนมสด', 'basePrice': 65, 'category': 'Milk'},
                    {'name': 'Coconut Avocado Milk / มะพร้าวอะโวคาโด้นมสด', 'basePrice': 65, 'category': 'Milk'},

                    // --- Bubble Tea (Iced/Frappe usually) ---
                    {'name': 'Taiwan Milk Tea Bubble / ชานมไต้หวันไข่มุก', 'basePrice': 65, 'category': 'Bubble Tea'},
                    {'name': 'Matcha Green Tea Bubble / มัทฉะกรีนทีมุก', 'basePrice': 65, 'category': 'Bubble Tea'},
                    {'name': 'Chocolate Bubble / ช็อกโกแลตมุก', 'basePrice': 65, 'category': 'Bubble Tea'},
                    {'name': 'Melon Bubble / เมล่อนมุก', 'basePrice': 65, 'category': 'Bubble Tea'},
                    {'name': 'Strawberry Bubble / สตรอเบอร์รี่มุก', 'basePrice': 65, 'category': 'Bubble Tea'},
                    {'name': 'Taro Bubble / เผือกมุก', 'basePrice': 65, 'category': 'Bubble Tea'},
                    {'name': 'Rose Tea Bubble / ชากุหลาบมุก', 'basePrice': 65, 'category': 'Bubble Tea'},

                    // --- Fresh Fruit ---
                    {'name': 'Mango Smoothie / มะม่วงปั่น', 'basePrice': 85, 'category': 'Fresh Fruit'},
                    {'name': 'Strawberry Cheesecake / สตรอเบอร์รี่ปั่นชีสเค้ก', 'basePrice': 85, 'category': 'Fresh Fruit'},
                    {'name': 'Green Tea Red Bean / ชาเขียวปั่นถั่วแดง', 'basePrice': 85, 'category': 'Fresh Fruit'},
                    {'name': 'Watermelon / น้ำแตงโม', 'basePrice': 65, 'category': 'Fresh Fruit'},
                    {'name': 'Strawberry Juice / น้ำสตรอเบอร์รี่', 'basePrice': 65, 'category': 'Fresh Fruit'},
                    {'name': 'Mango / น้ำมะม่วง', 'basePrice': 65, 'category': 'Fresh Fruit'},
                    {'name': 'Orange Juice / น้ำส้ม', 'basePrice': 65, 'category': 'Fresh Fruit'},
                    {'name': 'Lemon Juice / น้ำมะนาว', 'basePrice': 50, 'category': 'Fresh Fruit', 'hasVariants': true, 'icedPrice': 55, 'frappePrice': 65},
                    {'name': 'Blueberry Juice / น้ำบลูเบอร์รี่', 'basePrice': 65, 'category': 'Fresh Fruit'},
                    {'name': 'Kiwi Juice / น้ำกีวี่', 'basePrice': 65, 'category': 'Fresh Fruit'},
                    {'name': 'Passion Fruit Juice / น้ำเสาวรส', 'basePrice': 65, 'category': 'Fresh Fruit'},
                    {'name': 'Apple Juice / น้ำแอปเปิ้ล', 'basePrice': 65, 'category': 'Fresh Fruit'},
                    {'name': 'Lychee Juice / น้ำลิ้นจี่', 'basePrice': 65, 'category': 'Fresh Fruit'},
                    {'name': 'Carrot Juice / น้ำแครอท', 'basePrice': 65, 'category': 'Fresh Fruit'},
                    {'name': 'Fresh Coconut / มะพร้าวสด', 'basePrice': 65, 'category': 'Fresh Fruit'},
                  ];

                  int totalDrinks = drinks.length;
                  int successCount = 0;

                  for (var drink in drinks) {
                    List<Map<String, dynamic>> addOns = [];
                    if (drink['category'] == 'Coffee') {
                      addOns.add({'name': 'Coffee Shot (เพิ่มช็อต)', 'price': 20.0});
                    } else if (drink['category'] == 'Bubble Tea') {
                      addOns.add({'name': 'Extra Pearl (เพิ่มมุก)', 'price': 15.0});
                    }

                    List<Map<String, dynamic>> optionGroups = [];
                    if (drink['hasVariants'] == true) {
                      double iPrice = (drink['icedPrice'] as int).toDouble();
                      double fPrice = (drink['frappePrice'] as int).toDouble();
                      optionGroups.add({
                        'title': 'Serving Style / รูปแบบการเสิร์ฟ',
                        'options': [
                          'Hot (ร้อน)',
                          'Iced (เย็น) [+${(iPrice - (drink['basePrice'] as int)).toStringAsFixed(0)} THB]',
                          'Frappe (ปั่น) [+${(fPrice - (drink['basePrice'] as int)).toStringAsFixed(0)} THB]'
                        ]
                      });
                    } else if (drink['category'] == 'Fresh Fruit' || drink['category'] == 'Smoothies' || drink['category'] == 'Italian Soda') {
                      optionGroups.add({
                        'title': 'Serving Style / รูปแบบการเสิร์ฟ',
                        'options': ['Frappe (ปั่น) / Iced (เย็น)']
                      });
                    }

                    await db.collection('products').add({
                      'businessId': businessId,
                      'name': drink['name'],
                      'description': 'Refreshing ${drink['category']} from PhingPha Cafe',
                      'basePrice': (drink['basePrice'] as int).toDouble(),
                      'category': drink['category'],
                      'imageUrl': '',
                      'isAvailable': true,
                      'optionGroups': optionGroups,
                      'addOns': addOns,
                      'customOptions': [],
                      'quantity': 999,
                      'soldCount': 0,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    successCount++;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully seeded $successCount drinks!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid, width: 2),
              ),
              child: const Center(
                child: Text(
                  "[Long Press to Auto-Seed PhingPha Menu]",
                  style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),

          // 📈 Trending Insights Widget
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('businessId', isEqualTo: businessId)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const SizedBox.shrink();

              // Calculate frequencies
              final Map<String, int> frequencies = {};
              final exp = RegExp(r"^\d+x (.*?)(?: \(.*?\))?$", multiLine: true);
              
              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final summary = data['itemsSummary'] as String? ?? '';
                final matches = exp.allMatches(summary);
                for (var m in matches) {
                  final productName = m.group(1)?.trim();
                  if (productName != null && productName.isNotEmpty) {
                    frequencies[productName] = (frequencies[productName] ?? 0) + 1;
                  }
                }
              }

              if (frequencies.isEmpty) return const SizedBox.shrink();

              final sorted = frequencies.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              final top3 = sorted.take(3).toList();

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade50, Colors.deepOrange.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.deepOrange.shade200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, color: Colors.deepOrange),
                        const SizedBox(width: 8),
                        const Text("TRENDING INSIGHTS",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.deepOrange, letterSpacing: 0.8)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Your customers love these items! Consider adding a Discount Price to them in your Menu Manager to boost sales even further.",
                      style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    ...top3.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final food = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle),
                              child: Center(child: Text("#$rank", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(food.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kDark))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: Text("${food.value} Orders", style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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