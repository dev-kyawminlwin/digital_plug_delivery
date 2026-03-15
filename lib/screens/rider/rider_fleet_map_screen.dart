import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RiderFleetMapScreen extends StatefulWidget {
  const RiderFleetMapScreen({super.key});

  @override
  State<RiderFleetMapScreen> createState() => _RiderFleetMapScreenState();
}

class _RiderFleetMapScreenState extends State<RiderFleetMapScreen> {

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'rider')
          .where('isAvailable', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Marker> markers = [];
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final lat = data['latitude'];
          final lng = data['longitude'];

          if (lat != null && lng != null) {
            String avatar = data['avatar'] ?? '3d_male_avatar';
            
            Widget markerWidget = const Icon(Icons.location_on, color: Colors.blue, size: 40);
            if (avatar == '3d_male_avatar') {
              markerWidget = Image.asset('assets/images/3d_male_avatar.png', width: 40, height: 40);
            } else if (avatar == '3d_female_avatar') {
              markerWidget = Image.asset('assets/images/3d_female_avatar.png', width: 40, height: 40);
            }

            markers.add(
              Marker(
                point: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
                width: 60,
                height: 60,
                child: Column(
                  children: [
                    Text(data['name'] ?? 'Rider ${doc.id.substring(0,4)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, backgroundColor: Colors.white)),
                    Expanded(child: markerWidget),
                  ],
                ),
              )
            );
          }
        }

        return Stack(
          children: [
            FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(20.4447, 99.8821), // Tachileik Default Start
                initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.digitalplug.delivery',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            
            // HUD Overlay showing live count
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_alt, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text(
                          "${markers.length} Fleet Members Active",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Icon(Icons.satellite_alt, color: Colors.grey)
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
