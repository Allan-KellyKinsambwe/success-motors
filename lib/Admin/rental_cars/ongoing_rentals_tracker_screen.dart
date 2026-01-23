import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:success_motors/Admin/rental_cars/live_tracking_map_screen.dart';
import 'package:success_motors/screens/rentals_cars/rental_model.dart';

class OngoingRentalsTrackerScreen extends StatefulWidget {
  const OngoingRentalsTrackerScreen({super.key});

  @override
  State<OngoingRentalsTrackerScreen> createState() =>
      _OngoingRentalsTrackerScreenState();
}

class _OngoingRentalsTrackerScreenState
    extends State<OngoingRentalsTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ongoing Rentals Tracking'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rental_bookings')
            .where('status', isEqualTo: 'ongoing')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final bookings = snapshot.data!.docs
              .map(
                (doc) =>
                    RentalBooking.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

          if (bookings.isEmpty) {
            return const Center(child: Text('No ongoing rentals right now'));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              return ListTile(
                title: Text('${b.carMake} ${b.carModel}'),
                subtitle: Text(
                  'User: ${b.userId.substring(0, 8)}... • Total: UGX ${b.totalAmount}',
                ),
                trailing: const Icon(Icons.map, color: Colors.green),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveTrackingMapScreen(booking: b),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
