// lib/services/location_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _positionStream;

  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<bool> startTracking(String bookingId) async {
    final hasPermission = await checkAndRequestPermission();
    if (!hasPermission) {
      return false;
    }

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // update every ~10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            try {
              await FirebaseFirestore.instance
                  .collection('rental_bookings')
                  .doc(bookingId)
                  .set({
                    'liveLocation': {
                      'latitude': position.latitude,
                      'longitude': position.longitude,
                      'accuracy': position.accuracy,
                      'altitude': position.altitude,
                      'speed': position.speed,
                      'timestamp': FieldValue.serverTimestamp(),
                    },
                    'lastLocationUpdate': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
            } catch (e) {
              print('Failed to update location: $e');
            }
          },
          onError: (error) {
            print('Location stream error: $error');
          },
        );

    return true;
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}
