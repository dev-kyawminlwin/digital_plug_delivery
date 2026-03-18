import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/order_model.dart';
import '../shared/chat_screen.dart'; // Phase 16: Live Chat

class TrackOrderScreen extends StatefulWidget {
  final String orderId;
  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  final MapController _mapController = MapController();

  String _getDynamicETA(OrderStatus status) {
    switch (status) {
      case OrderStatus.lookingForRider: return "~20-30 min";
      case OrderStatus.assigned: return "~15-20 min";
      case OrderStatus.pickedUp: return "~5-10 min";
      case OrderStatus.arrived: return "Arriving Now!";
      case OrderStatus.completed: return "Delivered";
      default: return "--";
    }
  }

  String _getDynamicStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.lookingForRider: return "Finding a Rider for you";
      case OrderStatus.assigned: return "Rider is heading to Shop";
      case OrderStatus.pickedUp: return "Order is on the way!";
      case OrderStatus.arrived: return "Rider has arrived!";
      case OrderStatus.completed: return "Enjoy your meal!";
      default: return "Processing...";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').doc(widget.orderId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading order."));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final doc = snapshot.data!;
          if (!doc.exists) {
            return const Center(child: Text("Invalid Tracking Link. Order not found."));
          }

          final order = OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          
          return Stack(
            children: [
              // 1. Edge-to-Edge Map Background
              _buildMapBackground(order),

              // 2. Top Navigation Overlays
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Floating Back Button
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 22,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1F2937)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      // Floating Target Button
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 22,
                        child: IconButton(
                          icon: const Icon(Icons.my_location, size: 20, color: Color(0xFF1F2937)),
                          onPressed: () {
                            // Re-center map logic ignored for simplicity
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Bottom Information Sheet
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dynamic Status & ETA Highlighted Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: order.status == OrderStatus.completed 
                              ? [Colors.green.shade500, Colors.green.shade700]
                              : [const Color(0xFFFF5E1E), const Color(0xFFD94A1A)], // Vibrant Orange
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (order.status == OrderStatus.completed ? Colors.green : const Color(0xFFFF5E1E)).withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                order.status == OrderStatus.completed ? Icons.check_circle_rounded : Icons.local_shipping_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.status.displayName,
                                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "ETA: ${_getDynamicETA(order.status)}",
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: const Icon(Icons.location_on_outlined, color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(order.address, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))),
                                const Text("Delivery Address", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          )
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Dark Courier Card
                      if (order.assignedRider.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0xFFEAB308),
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(order.riderName.isEmpty ? "Rider Assigned" : order.riderName, 
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    const Text("Courier", style: TextStyle(color: Colors.white54, fontSize: 13)),
                                  ],
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
                                      icon: const Icon(Icons.chat, color: Colors.white),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ChatScreen(
                                              orderId: order.id,
                                              otherPartyName: order.riderName.isEmpty ? "Rider" : order.riderName,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981), // Emerald Green
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.call, color: Colors.white),
                                      onPressed: () {
                                        // Call rider logic
                                      },
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      else 
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: const Center(
                            child: Text("Preparing your order... Waiting for Rider assignment.", 
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold)),
                          ),
                        )
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapBackground(OrderModel order) {
    if (order.assignedRider.isEmpty) {
      return FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(20.4430, 99.8804), // Tachileik coordinates
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.digitalplug.delivery',
          ),
        ],
      );
    }

    // Stream Rider Location
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(order.assignedRider).snapshots(),
      builder: (context, riderSnap) {
        if (!riderSnap.hasData || !riderSnap.data!.exists) {
            return FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(20.4430, 99.8804),
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.digitalplug.delivery',
                ),
              ],
            );
        }
        
        final riderData = riderSnap.data!.data() as Map<String, dynamic>;
        final lat = riderData['latitude'];
        final lng = riderData['longitude'];

        if (lat == null || lng == null) {
           return FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(20.4430, 99.8804),
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.digitalplug.delivery',
                ),
              ],
            );
        }

        final currentPos = LatLng(lat, lng);
        
        // Optionally center map on stream update
        try {
          _mapController.move(currentPos, 16.0);
        } catch(e) {}

        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: currentPos,
            initialZoom: 16.0,
          ),
          children: [
             TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.digitalplug.delivery',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: currentPos,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.delivery_dining, color: Color(0xFFFF5E1E), size: 40),
                )
              ]
            )
          ],
        );
      },
    );
  }
}
