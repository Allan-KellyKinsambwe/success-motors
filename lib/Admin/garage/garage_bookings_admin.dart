import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/screens/garage_cars/garage_model.dart';

class GarageBookingsAdminScreen extends StatelessWidget {
  const GarageBookingsAdminScreen({super.key});

  Future<void> _updateStatus(
    BuildContext context,
    String bookingId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('garage_bookings')
          .doc(bookingId)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to $newStatus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garage Bookings Management'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('garage_bookings')
            .orderBy('preferredDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bookings found'));
          }

          final bookings = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return GarageBooking.fromMap({...data, 'id': doc.id});
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final isPending = booking.status.toLowerCase() == 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(booking.status),
                    child: Text(
                      booking.status[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    '${booking.carMake} ${booking.carModel} • ${booking.registrationNumber}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${DateFormat('dd MMM yyyy').format(booking.preferredDate)}',
                      ),
                      Text('Time: ${booking.preferredTime}'),
                      Text('Service: ${booking.serviceType}'),
                      if (booking.additionalNotes.isNotEmpty)
                        Text(
                          'Notes: ${booking.additionalNotes}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: isPending
                      ? ElevatedButton(
                          onPressed: () =>
                              _updateStatus(context, booking.id!, 'confirmed'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(90, 36),
                          ),
                          child: const Text('Confirm'),
                        )
                      : Chip(
                          label: Text(booking.status.toUpperCase()),
                          backgroundColor: _getStatusColor(booking.status),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
