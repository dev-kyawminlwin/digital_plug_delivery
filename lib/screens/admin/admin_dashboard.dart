import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Phase 8: Copy to Clipboard
import 'menu_manager_tab.dart'; // Phase 9: Menu Manager
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

  // Helper to calculate totals from the stream
  Widget _buildAnalyticsHeader(List<OrderModel> orders) {
    final today = DateTime.now();
    
    // 1. Daily Metrics
    final deliveredToday = orders.where((o) =>
    o.status == 'completed' &&
        o.createdAt.day == today.day
    ).toList();
    double todayRevenue = deliveredToday.fold(0, (sum, item) => sum + item.totalPrice + item.deliveryFee);

    // 2. All-Time Metrics
    final allTimeCompleted = orders.where((o) => o.status == 'completed').toList();
    double allTimeRevenue = allTimeCompleted.fold(0, (sum, item) => sum + item.totalPrice + item.deliveryFee);
    double averageOrderValue = allTimeCompleted.isEmpty ? 0 : (allTimeRevenue / allTimeCompleted.length);

    // 3. Top Customer Logic
    String topCustomer = "N/A";
    if (allTimeCompleted.isNotEmpty) {
      final Map<String, int> customerCounts = {};
      for (var order in allTimeCompleted) {
        customerCounts[order.customerName] = (customerCounts[order.customerName] ?? 0) + 1;
      }
      final sortedCustomers = customerCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      topCustomer = "${sortedCustomers.first.key} (${sortedCustomers.first.value}x)";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text("Today's Revenue", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          Text("MMK ${todayRevenue.toStringAsFixed(0)}",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("Daily Vol", "${deliveredToday.length}"),
              _statItem("Total Active", "${orders.where((o) => o.status != 'completed').length}"),
              _statItem("AOV (Avg)", "MMK ${averageOrderValue.toStringAsFixed(0)}"),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEAB308).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.orange, size: 16),
                const SizedBox(width: 5),
                Text("Top Customer: $topCustomer", style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text("All-Time Gross: MMK ${allTimeRevenue.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // Phase 6: Top Performers Leaderboard
  Widget _buildTopPerformers(List<OrderModel> orders) {
    final completedOrders = orders.where((o) => o.status == 'completed').toList();
    if (completedOrders.isEmpty) return const SizedBox.shrink();

    // Count orders per rider
    final Map<String, int> riderCounts = {};
    for (var order in completedOrders) {
      if (order.assignedRider.isNotEmpty) {
        riderCounts[order.assignedRider] = (riderCounts[order.assignedRider] ?? 0) + 1;
      }
    }

    // Sort by most completed
    final sortedRiders = riderCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text("Top Performers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedRiders.take(3).length, // Showing top 3
          itemBuilder: (context, index) {
            final entry = sortedRiders[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFEAB308).withOpacity(0.2),
                child: Text("#${index + 1}", style: const TextStyle(color: Color(0xFFEAB308), fontWeight: FontWeight.bold)),
              ),
              title: Text("Rider ID: ${entry.key.substring(0, 5)}..."),
              trailing: Text("${entry.value} Deliveries", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            );
          },
        ),
        const Divider(height: 16),
      ],
    );
  }
  // Professional Color System
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.orange;
      case 'picked_up':
        return Colors.blue; 
      case 'arrived':
        return Colors.deepPurple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get _currentTabTitle {
    switch (_currentIndex) {
      case 0: return "Live Orders";
      case 1: return "Menu Manager";
      case 2: return "Ratings";
      case 3: return "Ledger";
      case 4: return "Fleet";
      default: return "Admin Dashboard";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTabTitle),
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get(),
            builder: (context, snapshot) {
              if(!snapshot.hasData) return const SizedBox.shrink();
               final data = snapshot.data?.data() as Map<String, dynamic>?;
               final bizId = data?['businessId'];
               if(bizId == null) return const SizedBox.shrink();
               
               return IconButton(
                 icon: const Icon(Icons.add_photo_alternate),
                 tooltip: "Upload Shop Banner",
                 onPressed: () async {
                   final b64 = await ImageHelper.pickAndCompressImage();
                   if (b64 != null) {
                     await FirebaseFirestore.instance.collection('businesses').doc(bizId).update({
                       'imageUrl': b64,
                     });
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop Banner Updated!')));
                     }
                   }
                 },
               );
            }
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get(),
        builder: (context, adminSnapshot) {
          if (!adminSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = adminSnapshot.data?.data() as Map<String, dynamic>?;
          final businessId = data != null && data.containsKey('businessId') 
              ? data['businessId'] 
              : null;
              
          if (businessId == null) return const Center(child: Text("Error: No business ID linked to this admin."));

          if (_currentIndex == 0) return _buildOrdersTab(context, businessId);
          if (_currentIndex == 1) return _buildMenuTab(businessId);
          if (_currentIndex == 2) return VendorRatingsTab(businessId: businessId);
          if (_currentIndex == 3) return VendorLedgerTab(businessId: businessId);
          if (_currentIndex == 4) return VendorFleetTab(businessId: businessId);
          return _buildOrdersTab(context, businessId);
        }
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Live Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: "Menu"),
          BottomNavigationBarItem(icon: Icon(Icons.star_rate), label: "Ratings"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Ledger"),
          BottomNavigationBarItem(icon: Icon(Icons.motorcycle), label: "Fleet"),
        ],
      ),
    );
  }

  Widget _buildMenuTab(String businessId) {
    return MenuManagerTab(businessId: businessId);
  }

  Widget _buildOrdersTab(BuildContext context, String businessId) {
    return StreamBuilder<List<OrderModel>>(
      stream: OrderService().getOrders(businessId),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final orders = snapshot.data!;

              // This is the trick: Use a standard ListView to stack the Header + the Cards
              return ListView(
                children: [
                  // 1. Show the Money/Analytics at the top
                  _buildAnalyticsHeader(orders),

                  // Phase 6: Show Top Performers Leaderboard
                  _buildTopPerformers(orders),

                  // 2. Show the "Active Orders" label
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 10, bottom: 5),
                    child: Text("Active Orders", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),

                  // 3. Build the individual order cards
                  if (orders.isEmpty)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("No active orders found."),
                    ))
                  else
                    ...orders.map((order) {
                      final statusColor = _getStatusColor(order.status);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withOpacity(0.2),
                            child: Icon(Icons.delivery_dining, color: statusColor),
                          ),
                          title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            "Status: ${order.status.toUpperCase()}",
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "MMK ${order.totalPrice.toStringAsFixed(0)}",
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    order.paymentMethod,
                                    style: TextStyle(
                                      color: order.paymentMethod == 'Cash' ? Colors.red : Colors.blue, 
                                      fontSize: 10, fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              // Phase 8: Copy Tracking Link
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.blueGrey),
                                tooltip: "Copy Tracking Link",
                                onPressed: () {
                                  // In production, use your real domain here
                                  final trackingUrl = "https://digitalplug.com/#/track/${order.id}";
                                  Clipboard.setData(ClipboardData(text: trackingUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Copied link: $trackingUrl'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                ],
              );
            },
          );
  }
}