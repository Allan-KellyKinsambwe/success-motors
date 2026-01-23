// lib/screens/live_tracking_screen.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String orderId;
  const LiveTrackingScreen({super.key, required this.orderId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  LatLng? _deliveryGuyLocation;
  LatLng? _customerLocation;
  LatLng? _restaurantLocation;

  bool _hasUpdatedOnce = false; // To prevent initial unnecessary update

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _updateMarkersAndCamera() {
    final newMarkers = <Marker>{};

    if (_restaurantLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: _restaurantLocation!,
          infoWindow: const InfoWindow(title: 'Restaurant'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }

    if (_deliveryGuyLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('delivery_guy'),
          position: _deliveryGuyLocation!,
          infoWindow: const InfoWindow(title: 'Delivery Guy'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    if (_customerLocation != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: _customerLocation!,
          infoWindow: const InfoWindow(title: 'Delivery Address'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });

    // Camera animation
    if (_mapController != null &&
        (_deliveryGuyLocation != null || _customerLocation != null)) {
      List<double> lats = [];
      List<double> lngs = [];

      if (_deliveryGuyLocation != null) {
        lats.add(_deliveryGuyLocation!.latitude);
        lngs.add(_deliveryGuyLocation!.longitude);
      }
      if (_customerLocation != null) {
        lats.add(_customerLocation!.latitude);
        lngs.add(_customerLocation!.longitude);
      }
      if (_restaurantLocation != null) {
        lats.add(_restaurantLocation!.latitude);
        lngs.add(_restaurantLocation!.longitude);
      }

      if (lats.isNotEmpty) {
        final minLat = lats.reduce((a, b) => a < b ? a : b);
        final maxLat = lats.reduce((a, b) => a > b ? a : b);
        final minLng = lngs.reduce((a, b) => a < b ? a : b);
        final maxLng = lngs.reduce((a, b) => a > b ? a : b);

        final bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      } else if (_deliveryGuyLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _deliveryGuyLocation!, zoom: 15),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: const Text(
          'Live Tracking',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_hasUpdatedOnce) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          // Error or no data
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Order data not available',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Extract locations safely
          final GeoPoint? deliveryGuyGeo =
              data['delivery_guy_location'] as GeoPoint?;
          final GeoPoint? customerGeo =
              data['delivery_address_location'] as GeoPoint?;
          final GeoPoint? restaurantGeo =
              data['restaurant_location'] as GeoPoint?;

          final newDeliveryGuy = deliveryGuyGeo != null
              ? LatLng(deliveryGuyGeo.latitude, deliveryGuyGeo.longitude)
              : null;

          final newCustomer = customerGeo != null
              ? LatLng(customerGeo.latitude, customerGeo.longitude)
              : null;

          final newRestaurant = restaurantGeo != null
              ? LatLng(restaurantGeo.latitude, restaurantGeo.longitude)
              : null;

          // Only update if locations actually changed
          final locationsChanged =
              newDeliveryGuy != _deliveryGuyLocation ||
              newCustomer != _customerLocation ||
              newRestaurant != _restaurantLocation;

          _deliveryGuyLocation = newDeliveryGuy;
          _customerLocation = newCustomer;
          _restaurantLocation = newRestaurant;

          // Update map only after build and only if needed
          if (locationsChanged || !_hasUpdatedOnce) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateMarkersAndCamera();
            });
            _hasUpdatedOnce = true;
          }

          return GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(0.3476, 32.5825), // Kampala fallback
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          );
        },
      ),
    );
  }
}
