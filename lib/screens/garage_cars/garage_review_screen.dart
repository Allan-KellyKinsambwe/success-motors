// lib/screens/garage_cars/garage_review_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/constants/constants.dart';
import 'garage_model.dart';
import 'garage_confirmation_screen.dart';

class GarageReviewScreen extends StatelessWidget {
  final GarageBooking booking;

  const GarageReviewScreen({super.key, required this.booking});

  Future<void> _submit(BuildContext context) async {
    try {
      final docRef = await FirebaseFirestore.instance
          .collection('garage_bookings')
          .add(booking.toMap());
      await docRef.update({'id': docRef.id});

      final updatedBooking = GarageBooking(
        id: docRef.id,
        userId: booking.userId,
        fullName: booking.fullName,
        phoneNumber: booking.phoneNumber,
        carMake: booking.carMake,
        carModel: booking.carModel,
        carYear: booking.carYear,
        registrationNumber: booking.registrationNumber,
        serviceType: booking.serviceType,
        otherService: booking.otherService,
        preferredDate: booking.preferredDate,
        preferredTime: booking.preferredTime,
        additionalNotes: booking.additionalNotes,
        status: 'pending',
        createdAt: booking.createdAt,
      );

      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GarageConfirmationScreen(booking: updatedBooking),
          ),
        );
      }
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Review Service Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please confirm your details',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            _section('Customer', [
              _row('Name', booking.fullName),
              _row('Phone', booking.phoneNumber),
            ]),
            const SizedBox(height: 24),

            _section('Vehicle', [
              _row(
                'Car',
                '${booking.carMake} ${booking.carModel} (${booking.carYear})',
              ),
              _row('Registration', booking.registrationNumber),
            ]),
            const SizedBox(height: 24),

            _section('Service', [
              _row('Type', booking.serviceType),
              if (booking.otherService != null)
                _row('Details', booking.otherService!),
              _row(
                'Preferred Date',
                DateFormat('EEEE, dd MMMM yyyy').format(booking.preferredDate),
              ),
              _row('Time', booking.preferredTime),
            ]),
            const SizedBox(height: 24),

            if (booking.additionalNotes.isNotEmpty)
              _section('Notes', [_row('Message', booking.additionalNotes)]),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppStyles.orangeButtonStyle,
                onPressed: () => _submit(context),
                child: const Text(
                  'Confirm Booking',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Edit Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
