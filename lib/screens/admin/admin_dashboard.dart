import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'shop_location_picker_screen.dart';
import '../../services/user_service.dart';
import '../../services/business_service.dart';
import '../../services/order_service.dart';
import '../../services/seed_service.dart';
import '../shared/app_components.dart';
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
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _bizData;
  
  late Future<Map<String, dynamic>> _dashboardDataFuture;

  static const Color _kPrimary = Color(0xFFFF5E1E);
  static const Color _kGold = Color(0xFFEAB308);
  static const Color _kDark = Color(0xFF1F2937);

  static const List<Map<String, dynamic>> _markerIcons = [
    {'name': 'store', 'icon': Icons.storefront},
    {'name': 'coffee', 'icon': Icons.coffee},
    {'name': 'fastfood', 'icon': Icons.fastfood},
    {'name': 'local_pizza', 'icon': Icons.local_pizza},
    {'name': 'bakery_dining', 'icon': Icons.bakery_dining},
    {'name': 'restaurant', 'icon': Icons.restaurant},
    {'name': 'local_pharmacy', 'icon': Icons.local_pharmacy},
    {'name': 'shopping_bag', 'icon': Icons.shopping_bag},
    {'name': 'cake', 'icon': Icons.cake},
    {'name': 'icecream', 'icon': Icons.icecream},
  ];

  static const List<Map<String, dynamic>> _markerColors = [
    {'name': 'Orange', 'hex': '#FF5E1E', 'color': Color(0xFFFF5E1E)},
    {'name': 'Red', 'hex': '#EF4444', 'color': Colors.red},
    {'name': 'Blue', 'hex': '#3B82F6', 'color': Colors.blue},
    {'name': 'Green', 'hex': '#10B981', 'color': Colors.green},
    {'name': 'Purple', 'hex': '#8B5CF6', 'color': Colors.purple},
    {'name': 'Pink', 'hex': '#EC4899', 'color': Colors.pink},
    {'name': 'Yellow', 'hex': '#F59E0B', 'color': Colors.amber},
    {'name': 'Dark', 'hex': '#1F2937', 'color': Color(0xFF1F2937)},
  ];

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _loadDashboardData();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    final userData = await UserService().getUserData(user.uid);
    final businessId = userData?['businessId'] as String? ?? '';
    final adminName = userData?['name'] as String? ?? 'Admin';

    final bizData = await BusinessService().getBusinessData(businessId);

    return {
      'businessId': businessId,
      'adminName': adminName,
      'bizData': bizData ?? {},
    };
  }

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

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  void _showMarkerCustomizer(String businessId, Map<String, dynamic> bizData) {
    String currentIcon = bizData['markerIcon'] ?? 'store';
    String currentColor = bizData['markerColor'] ?? '#FF5E1E';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeColor = _hexToColor(currentColor);
            final activeIconData = _markerIcons.firstWhere((i) => i['name'] == currentIcon, orElse: () => _markerIcons[0])['icon'] as IconData;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24, right: 24, top: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text("Customize Map Marker", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kDark)),
                  const SizedBox(height: 16),
                  
                  // Preview
                  Center(
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: activeColor, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Icon(activeIconData, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text("Select Icon", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    children: _markerIcons.map((i) {
                      bool isSel = i['name'] == currentIcon;
                      return GestureDetector(
                        onTap: () => setModalState(() => currentIcon = i['name']),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSel ? activeColor.withOpacity(0.1) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? activeColor : Colors.transparent, width: 2),
                          ),
                          child: Icon(i['icon'], color: isSel ? activeColor : Colors.grey.shade600),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),
                  const Text("Select Color", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12, runSpacing: 12,
                    children: _markerColors.map((c) {
                      bool isSel = c['hex'] == currentColor;
                      return GestureDetector(
                        onTap: () => setModalState(() => currentColor = c['hex']),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: c['color'], shape: BoxShape.circle,
                            border: Border.all(color: isSel ? Colors.black : Colors.transparent, width: 3),
                          ),
                          child: isSel ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _kDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      onPressed: () async {
                        await BusinessService().updateMarkerStyle(businessId, currentIcon, currentColor);
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text("Save Marker", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  )
                ],
              ),
            ));
          }
        );
      }
    );
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
                  _buildSubscriptionBanner(bizData),
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
                                      .where('status', isNotEqualTo: 'completed')
                                      .snapshots(),
                                  builder: (context, snap) {
                                    if (!snap.hasData) return const SizedBox.shrink();
                                    
                                    final liveDocs = snap.data!.docs;
                                    
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
            _buildTrendingInsights(businessId),
            const SizedBox(height: 16),
            const Text("Live Orders",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _kDark)),
            const SizedBox(height: 12),
            ...orders.where((o) => o.status != OrderStatus.completed).map((order) => _buildOrderCard(order)).toList(),
            if (orders.where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled).isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text("No orders yet.", style: TextStyle(color: _kDark, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text("Start adding items to your menu to drive sales!", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: "Go to Menu Manager",
                        icon: Icons.restaurant_menu_rounded,
                        onPressed: () {
                          setState(() {
                            _currentIndex = 2; // Jump to Menu tab
                          });
                        },
                      )
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
        o.status == OrderStatus.completed && 
        o.createdAt.year == today.year && 
        o.createdAt.month == today.month && 
        o.createdAt.day == today.day).toList();
        
    final allTimeCompleted = orders.where((o) => o.status == OrderStatus.completed).toList();
    
    double grossRevenue = deliveredToday.fold(0, (sum, item) => sum + item.totalPrice + item.deliveryFee);
    double riderPayout = deliveredToday.fold(0, (sum, item) => sum + item.deliveryFee);
    double netEarnings = deliveredToday.fold(0, (sum, item) => sum + item.totalPrice);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Gross Revenue", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text("THB ${grossRevenue.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Rider Payout", style: TextStyle(color: Colors.white60, fontSize: 10)),
                  Text("- THB ${riderPayout.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  const Text("Net Earnings", style: TextStyle(color: Colors.white60, fontSize: 10)),
                  Text("THB ${netEarnings.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: _analyticsChip("Completed", "${deliveredToday.length}")),
              const SizedBox(width: 8),
              Expanded(child: _analyticsChip("Active", "${orders.where((o) => o.status != OrderStatus.completed && o.status != OrderStatus.cancelled).length}")),
              const SizedBox(width: 8),
              Expanded(child: _analyticsChip("Orders", "${orders.length}")),
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

  Widget _buildSubscriptionBanner(Map<String, dynamic> bizData) {
    if (bizData.isEmpty) return const SizedBox.shrink();
    
    final status = bizData['subscriptionStatus'] as String? ?? 'inactive';
    final sl = bizData['subscriptionEnd'];
    DateTime? subEnd;
    if (sl is Timestamp) subEnd = sl.toDate();
    else if (sl is String) subEnd = DateTime.tryParse(sl);

    if (status != 'active' || subEnd == null) {
      return Container(
        color: Colors.red.shade600,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Text("⚠️ Subscription Inactive - Please Renew to accept orders.", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
      );
    }
    
    final daysLeft = subEnd.difference(DateTime.now()).inDays;
    if (daysLeft <= 7) {
      return Container(
        color: Colors.orange.shade700,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text("⚠️ Plan: Active • Expires in $daysLeft Days", 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
      );
    }
    
    return Container(
      color: Colors.green.shade600,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Text("✅ Plan: Active • Expires in $daysLeft Days", 
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
    );
  }

  Widget _buildTrendingInsights(String businessId) {
    // NOTE: This intentionally bypasses OrderService.getOrders because it requires history, 
    // not just 'live' orders. It could be moved to a BusinessAnalyticsService later.
    return StreamBuilder<QuerySnapshot>(
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
          margin: const EdgeInsets.only(top: 16),
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
                  const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange),
                  const SizedBox(width: 8),
                  const Text("🔥 Top Selling Today",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.deepOrange, letterSpacing: -0.5)),
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
                        decoration: const BoxDecoration(color: Colors.deepOrange, shape: BoxShape.circle),
                        child: Center(child: Text("#$rank", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text("${food.key}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _kDark))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: Text("${food.value} Orders", style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
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
                    order.status.displayName,
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
          const SizedBox(height: 16),

          // Location Setup
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.location_on, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Shop Location Setup", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(bizData['location'] != null ? "GPS coordinates actively synced." : "Required for Customer Map & Delivery estimation.", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    LatLng? initLoc;
                    if (bizData['location'] != null) {
                      initLoc = LatLng(bizData['location'].latitude, bizData['location'].longitude);
                    }
                    final LatLng? picked = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ShopLocationPickerScreen(initialLocation: initLoc)),
                    );

                    if (picked != null) {
                      await BusinessService().updateBusinessLocation(businessId, picked.latitude, picked.longitude);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop Location Updated Successfully!'), backgroundColor: Colors.green));
                      }
                    }
                  },
                  child: const Text("Set on Map", style: TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Custom Marker Setup
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bizData['markerColor'] != null ? _hexToColor(bizData['markerColor']).withValues(alpha: 0.1) : Colors.purple.withValues(alpha: 0.1), 
                    shape: BoxShape.circle
                  ),
                  child: Icon(
                    _markerIcons.firstWhere((i) => i['name'] == (bizData['markerIcon'] ?? 'store'), orElse: () => _markerIcons[0])['icon'] as IconData, 
                    color: bizData['markerColor'] != null ? _hexToColor(bizData['markerColor']) : Colors.purple
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Map Pin Appearance", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("Customize how customers see you on the map.", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showMarkerCustomizer(businessId, bizData),
                  child: const Text("Customize", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                )
              ],
            ),
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
          if (kDebugMode)
            GestureDetector(
              onLongPress: () => SeedService.seedPhingPhaMenu(context, businessId),
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