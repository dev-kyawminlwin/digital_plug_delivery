import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class ShopLocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const ShopLocationPickerScreen({super.key, this.initialLocation});

  @override
  State<ShopLocationPickerScreen> createState() => _ShopLocationPickerScreenState();
}

class _ShopLocationPickerScreenState extends State<ShopLocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _currentCenter = const LatLng(20.4430, 99.8827); // Default Tachileik
  bool _isLoading = true;

  static const Color _kPrimary = Color(0xFFFF5E1E);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (widget.initialLocation != null) {
      _currentCenter = widget.initialLocation!;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentCenter = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (e) {
      // Ignore, rely on default
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Shop Location", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 16.0,
              onPositionChanged: (position, bool hasGesture) {
                if (hasGesture && position.center != null) {
                  setState(() {
                    _currentCenter = position.center;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.digitalplug.delivery',
              ),
            ],
          ),
          
          // Center Reticle
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 30), // Offset slightly to account for pin tip
              child: Icon(Icons.location_on, size: 50, color: _kPrimary),
            ),
          ),
          
          // Instruction Overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: _kPrimary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text("Drag the map to position the pin exactly on your storefront.", 
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),

          // Confirm Button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: _kPrimary.withOpacity(0.5),
                ),
                onPressed: () {
                  Navigator.pop(context, _currentCenter);
                },
                child: const Text("Confirm Location", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
