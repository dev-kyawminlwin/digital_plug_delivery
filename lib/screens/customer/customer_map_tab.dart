import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'shop_menu_screen.dart';

class CustomerMapTab extends StatefulWidget {
  const CustomerMapTab({super.key});

  @override
  State<CustomerMapTab> createState() => _CustomerMapTabState();
}

class _CustomerMapTabState extends State<CustomerMapTab> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<Map<String, dynamic>> _businesses = [];

  @override
  void initState() {
    super.initState();
    _fetchLocationAndShops();
  }

  Future<void> _fetchLocationAndShops() async {
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() { _currentLocation = LatLng(pos.latitude, pos.longitude); });
      } else {
        // Default to central Tachileik if denied
        setState(() { _currentLocation = const LatLng(20.4430, 99.8827); });
      }
    } catch (e) {
      setState(() { _currentLocation = const LatLng(20.4430, 99.8827); });
    }

    // Fetch shops with locations
    final snap = await FirebaseFirestore.instance.collection('businesses').get();
    setState(() {
      _businesses = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    });
  }

  void _showShopPreview(Map<String, dynamic> shop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shop['imageUrl'] != null && shop['imageUrl'].toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    base64Decode(shop['imageUrl']),
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => Container(height: 150, color: Colors.grey.shade200, child: const Icon(Icons.store)),
                  ),
                ),
              const SizedBox(height: 16),
              Text(shop['name'] ?? 'Shop', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (shop['deliveryFee'] != null)
                Text("Base Delivery: THB ${shop['deliveryFee']}", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5E1E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (c) => ShopMenuScreen(
                      businessId: shop['id'], 
                      businessName: shop['name'], 
                    )));
                  },
                  child: const Text("View Menu & Order", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF5E1E)));
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation!,
            initialZoom: 14.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.digitalplug.delivery',
            ),
            MarkerLayer(
              markers: [
                // User Location
                Marker(
                  point: _currentLocation!,
                  width: 50,
                  height: 50,
                  child: const Icon(Icons.navigation, color: Colors.blue, size: 40),
                ),
                // Shops
                ..._businesses.where((b) => b['location'] != null).map((shop) {
                  GeoPoint geo = shop['location'];
                  return Marker(
                    point: LatLng(geo.latitude, geo.longitude),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _showShopPreview(shop),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5E1E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.storefront, color: Colors.white, size: 28),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
        // Overlay Title
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: const Row(
              children: [
                Icon(Icons.map_rounded, color: Color(0xFFFF5E1E)),
                SizedBox(width: 12),
                Text("Shops near you", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
