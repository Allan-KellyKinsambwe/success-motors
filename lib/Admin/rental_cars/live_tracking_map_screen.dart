// lib/Admin/live_tracking_map_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/screens/rentals_cars/rental_model.dart';

class LiveTrackingMapScreen extends StatefulWidget {
  final RentalBooking booking;
  final bool demoMode; // ← new optional parameter

  const LiveTrackingMapScreen({
    super.key,
    required this.booking,
    this.demoMode = true, // default to demo for now
  });

  @override
  State<LiveTrackingMapScreen> createState() => _LiveTrackingMapScreenState();
}

class _LiveTrackingMapScreenState extends State<LiveTrackingMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Marker? _currentMarker;
  StreamSubscription<DocumentSnapshot>? _locationSub;
  Timer? _demoTimer;

  // Center of Kampala
  static const LatLng _kampalaCenter = LatLng(0.3136, 32.5811);

  // Demo movement parameters
  LatLng _demoPosition = _kampalaCenter;
  double _demoBearing = 0.0;

  @override
  void initState() {
    super.initState();

    if (widget.demoMode) {
      _startDemoAnimation();
    } else {
      _listenToLiveLocation();
    }
  }

  void _startDemoAnimation() {
    _demoTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Simulate movement: small random walk + slight direction change
      final random = Random();
      final deltaLat = (random.nextDouble() - 0.5) * 0.002; // ~200 meters
      final deltaLng = (random.nextDouble() - 0.5) * 0.002;

      setState(() {
        _demoPosition = LatLng(
          _demoPosition.latitude + deltaLat,
          _demoPosition.longitude + deltaLng,
        );
        _demoBearing = (_demoBearing + (random.nextDouble() * 60 - 30)) % 360;
      });

      _updateMarker(
        position: _demoPosition,
        bearing: _demoBearing,
        title: 'Demo Renter Location',
        snippet:
            'Simulated movement • ${DateFormat('HH:mm:ss').format(DateTime.now())}',
      );

      _controller.future.then((ctrl) {
        ctrl.animateCamera(CameraUpdate.newLatLng(_demoPosition));
      });
    });

    // Initial marker
    _updateMarker(
      position: _demoPosition,
      bearing: _demoBearing,
      title: 'Demo Renter Location',
      snippet: 'Real tracking not active yet',
    );
  }

  void _updateMarker({
    required LatLng position,
    required double bearing,
    required String title,
    String? snippet,
  }) {
    setState(() {
      _currentMarker = Marker(
        markerId: const MarkerId('renter_current'),
        position: position,
        rotation: bearing,
        infoWindow: InfoWindow(title: title, snippet: snippet),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    });
  }

  void _listenToLiveLocation() {
    _locationSub = FirebaseFirestore.instance
        .collection('rental_bookings')
        .doc(widget.booking.id)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists || !mounted) return;

          final data = snapshot.data()!;
          final loc = data['liveLocation'] as Map<String, dynamic>?;

          if (loc != null &&
              loc['latitude'] != null &&
              loc['longitude'] != null) {
            final lat = loc['latitude'] as double;
            final lng = loc['longitude'] as double;
            final ts = (loc['timestamp'] as Timestamp?)?.toDate();

            setState(() {
              _currentMarker = Marker(
                markerId: const MarkerId('renter_current'),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: 'Renter Location',
                  snippet: ts != null
                      ? 'Updated: ${DateFormat('HH:mm:ss • dd MMM').format(ts)}'
                      : null,
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
              );
            });

            _controller.future.then((ctrl) {
              ctrl.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
            });
          }
        });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _demoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Tracking – ${widget.booking.carMake} ${widget.booking.carModel}',
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _kampalaCenter,
              zoom: 15.0,
            ),
            markers: _currentMarker != null ? {_currentMarker!} : {},
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              // Center on demo position immediately
              if (widget.demoMode) {
                controller.animateCamera(CameraUpdate.newLatLng(_demoPosition));
              }
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),

          // Demo mode overlay banner
          if (widget.demoMode)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'DEMO MODE – Simulated movement\nReal tracking will appear here later',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        child: const Icon(Icons.my_location),
        onPressed: () {
          final target = widget.demoMode
              ? _demoPosition
              : _currentMarker?.position;
          if (target != null) {
            _controller.future.then((ctrl) {
              ctrl.animateCamera(CameraUpdate.newLatLng(target));
            });
          }
        },
      ),
    );
  }
}
