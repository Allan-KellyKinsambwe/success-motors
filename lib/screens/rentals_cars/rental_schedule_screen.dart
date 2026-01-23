// lib/screens/rental_cars/rental_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'rental_model.dart';
import 'rental_booking_details_screen.dart'; // ← NEW IMPORT

class RentalScheduleScreen extends StatelessWidget {
  const RentalScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('My Rentals')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rental_bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs
              .map(
                (doc) =>
                    RentalBooking.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList();

          if (bookings.isEmpty) {
            return const Center(child: Text('No rental bookings yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (_, i) {
              final b = bookings[i];
              final isActive = DateTime.now().isBefore(b.dropoffDate);

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RentalBookingDetailsScreen(booking: b),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                b.carImage.startsWith('http') ||
                                    b.carImage.startsWith('https')
                                ? Image.network(
                                    b.carImage,
                                    width: 80,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _placeholderImage(),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return const SizedBox(
                                            width: 80,
                                            height: 60,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          );
                                        },
                                  )
                                : Image.asset(
                                    b.carImage.isNotEmpty
                                        ? b.carImage
                                        : 'assets/images/default_car.png',
                                    width: 80,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _placeholderImage(),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.55,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${b.carMake} ${b.carModel}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  'UGX ${b.totalAmount} • ${b.totalDays} days',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Chip(
                            label: Text(b.status.toUpperCase()),
                            backgroundColor: isActive
                                ? Colors.green[100]
                                : Colors.grey[300],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 80,
      height: 60,
      color: Colors.grey[300],
      child: const Icon(
        Icons.broken_image_outlined,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
}
