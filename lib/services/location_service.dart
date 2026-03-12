import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final String uid;
  StreamSubscription<Position>? _positionStream;

  LocationService({required this.uid});

  Future<void> startTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    } 

    // When permissions are OK, start the stream
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position? position) {
        if (position != null) {
          _updateLocationInFirestore(position);
        }
      }
    );
  }

  void _updateLocationInFirestore(Position position) {
    if (uid.isEmpty) return;

    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    }).catchError((error) {
       print("Failed to update location: $error");
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}
