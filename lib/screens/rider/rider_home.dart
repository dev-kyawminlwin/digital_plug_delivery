import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/location_service.dart'; // Phase 9: Live Map Tracker
import 'rider_fleet_map_screen.dart';
import '../shared/chat_screen.dart'; // Phase 16: Live Chat

class RiderHome extends StatefulWidget {
  const RiderHome({super.key});

  @override
  State<RiderHome> createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  final OrderService _orderService = OrderService();
  LocationService? _locationService;
  late String uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isNotEmpty) {
      _locationService = LocationService(uid: uid);
      _locationService!.startTracking().catchError((e) {
        print("Location tracking error: $e");
      });
    }
  }

  @override
  void dispose() {
    _locationService?.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, riderSnapshot) {
        if (!riderSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final data = riderSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final businessId = data['businessId'];
        final walletBalance = (data['walletBalance'] as num?)?.toDouble() ?? 0.0;
        final collectedCash = (data['collectedCash'] as num?)?.toDouble() ?? 0.0;

        if (businessId == null) return const Center(child: Text("Error: No business assigned to this rider."));

        return DefaultTabController(
          length: 3,
          child: Scaffold(
              appBar: AppBar(
                title: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('orders').where('status', isNotEqualTo: 'completed').snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Rider Panel"),
                        const SizedBox(width: 8),
                        if (count > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                            child: Text("$count Live", style: const TextStyle(fontSize: 12, color: Colors.white)),
                          )
                      ],
                    );
                  }
                ),
                bottom: const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.list_alt), text: "My Deliveries"),
                    Tab(icon: Icon(Icons.radar), text: "Order Radar"),
                    Tab(icon: Icon(Icons.map), text: "Fleet Map"),
                  ],
                ),
                actions: [
                  Row(
                    children: [
                      const Text("Status:", style: TextStyle(fontSize: 12)),
                      Switch(
                        value: data['isAvailable'] ?? false,
                        activeColor: Colors.greenAccent,
                        activeTrackColor: Colors.green,
                        onChanged: (val) async {
                          await FirebaseFirestore.instance.collection('users').doc(uid).update({'isAvailable': val});
                        },
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      _locationService?.stopTracking(); // Stop GPS on logout
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                  ),
                ],
              ),
              body: TabBarView(
                physics: const NeverScrollableScrollPhysics(), // Prevent swipe interference with Google Maps
                children: [
                  // Tab 1: My active deliveries and Wallet
                  _buildMyDeliveriesTab(uid, businessId, data, _orderService, walletBalance, collectedCash),
                  
                  // Tab 2: Available broadcasted orders
                  _buildOrderRadarTab(uid, data['name'] ?? 'Rider', businessId, _orderService),

                  // Tab 3: Live 3D Fleet Map
                  const RiderFleetMapScreen(),
                ],
              ),
            ),
          );
        }
      );
  }

  Widget _buildOrderRadarTab(String uid, String riderName, String businessId, OrderService service) {
    return StreamBuilder<List<OrderModel>>(
      stream: service.getAvailableOrders(businessId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final availableOrders = snapshot.data!;

        if (availableOrders.isEmpty) {
          return const Center(child: Text("No new requests right now. Relax! 🛋️"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: availableOrders.length,
          itemBuilder: (context, index) {
            final order = availableOrders[index];
            return Card(
              elevation: 4,
              color: const Color(0xFFEAB308).withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("New Order: ${order.customerName}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEAB308))),
                    Text("📍 ${order.address}", style: const TextStyle(color: Colors.black87)),
                    Text("💰 MMK ${order.totalPrice.toStringAsFixed(0)} (${order.paymentMethod})", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                        bool success = await service.acceptOrder(order.id, uid, riderName);
                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order Accepted! Go to My Deliveries to start.')));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Oh snap! Another rider claimed this first.')));
                          }
                        }
                      },
                      child: const Text("FASTEST FINGER: ACCEPT ORDER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyDeliveriesTab(String uid, String businessId, Map<String, dynamic> data, OrderService service, double walletBalance, double collectedCash) {
    return StreamBuilder<List<OrderModel>>(
      stream: service.getRiderOrders(uid, businessId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final orders = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // Step 4: Wallet Balance Header
            Card(
              elevation: 4,
              color: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Side: What the Rider Earned
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Wallet Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          "MMK ${walletBalance.toStringAsFixed(0)}",
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    
                    // Right Side: Physical Cash the Rider holds
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text("Cash to Drop", style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            "MMK ${collectedCash.toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),

            // Phase 8: Payout / Settlement Request
            if (collectedCash > 0 || walletBalance > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.payments, color: Colors.white),
                  label: const Text("Settle Balances with Shop", style: TextStyle(color: Colors.white, fontSize: 16)),
                  onPressed: () async {
                    // Simple Direct Settlement for MVP
                    await FirebaseFirestore.instance.collection('users').doc(uid).update({
                      'walletBalance': 0,
                      'collectedCash': 0,
                    });
                  },
                ),
              ),

            const Text("Active Deliveries", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            if (orders.isEmpty)
              const Center(child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("No active deliveries. Check the Radar!"),
              )),

            ...orders.map((order) {
              final statusColor = OrderModel.getStatusColor(order.status);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(order.customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "MMK ${order.totalPrice.toStringAsFixed(0)}",
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                              // Phase 8: Show payment method
                              Text(
                                order.paymentMethod.toUpperCase(),
                                style: TextStyle(
                                  color: order.paymentMethod == 'Cash' ? Colors.red : Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            ]
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("📍 ${order.address}"),
                      Text("📞 ${order.phone}"),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3B82F6), // Blue for Chat
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.chat, color: Colors.white, size: 20),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          orderId: order.id,
                                          otherPartyName: order.customerName,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              _buildActionButton(order, service),
                            ],
                          ),
                        ],
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

  Widget _buildActionButton(OrderModel order, OrderService service) {
    if (order.status == 'assigned') {
      return ElevatedButton(
        onPressed: () => service.updateStatus(order, 'picked_up'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        child: const Text("PICK UP", style: TextStyle(color: Colors.white)),
      );
    } else if (order.status == 'picked_up') {
      return ElevatedButton(
        onPressed: () => service.updateStatus(order, 'arrived'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
        child: const Text("ARRIVED", style: TextStyle(color: Colors.white)),
      );
    } else if (order.status == 'arrived') {
      return ElevatedButton(
        onPressed: () => service.updateStatus(order, 'completed'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        child: const Text("COMPLETE DELIVERY", style: TextStyle(color: Colors.white)),
      );
    }
    return const SizedBox.shrink();
  }
} // End RiderHome