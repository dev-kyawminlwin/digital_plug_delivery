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
                      // Wait Time & Address Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                            child: const Icon(Icons.access_time, color: Color(0xFF1F2937)),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("10-15 min", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))),
                              Text("Estimated Delivery", style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          )
                        ],
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
                  child: const Icon(Icons.delivery_dining, color: Colors.orange, size: 40),
                )
              ]
            )
          ],
        );
      },
    );
  }
}
