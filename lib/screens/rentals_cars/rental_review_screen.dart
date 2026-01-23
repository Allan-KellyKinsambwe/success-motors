// lib/screens/rental_cars/rental_review_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/constants/constants.dart';
import 'rental_model.dart';
import 'rental_confirmation_screen.dart';

class RentalReviewScreen extends StatelessWidget {
  final RentalBooking booking;

  const RentalReviewScreen({super.key, required this.booking});

  Future<void> _submitBooking(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final docRef = await FirebaseFirestore.instance
          .collection('rental_bookings')
          .add(booking.toMap());
      await docRef.update({'id': docRef.id}); // Set ID in Firestore

      final updatedBooking = RentalBooking(
        id: docRef.id,
        userId: booking.userId,
        carMake: booking.carMake,
        carModel: booking.carModel,
        carImage: booking.carImage,
        dailyRate: booking.dailyRate,
        pickupDate: booking.pickupDate,
        dropoffDate: booking.dropoffDate,
        pickupLocation: booking.pickupLocation,
        dropoffLocation: booking.dropoffLocation,
        withDriver: booking.withDriver,
        totalAmount: booking.totalAmount,
        status: 'pending',
        createdAt: booking.createdAt,
      );

      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RentalConfirmationScreen(booking: updatedBooking),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting booking: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = booking.totalDays;
    final driverFee = booking.withDriver ? 150000 * days : 0;
    final subtotal = booking.dailyRate * days;
    final total = subtotal + driverFee;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Review Booking'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Your Rental',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Booking ID will be generated upon confirmation',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // Car Summary – FIXED IMAGE LOADING
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 100,
                        height: 80,
                        child:
                            booking.carImage.startsWith('http') ||
                                booking.carImage.startsWith('https')
                            ? Image.network(
                                booking.carImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderImage(),
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                              )
                            : Image.asset(
                                booking.carImage.isNotEmpty
                                    ? booking.carImage
                                    : 'assets/images/default_car.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _placeholderImage(),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${booking.carMake} ${booking.carModel}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'UGX ${booking.dailyRate} per day',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$days day${days > 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dates & Locations – FIXED OVERFLOW
            _buildSection(
              title: 'Rental Period',
              children: [
                _buildRow(
                  'Pickup Date',
                  DateFormat('EEEE, dd MMM yyyy').format(booking.pickupDate),
                ),
                _buildRow(
                  'Dropoff Date',
                  DateFormat('EEEE, dd MMM yyyy').format(booking.dropoffDate),
                ),
                _buildRow('Pickup Location', booking.pickupLocation),
                _buildRow('Dropoff Location', booking.dropoffLocation),
                _buildRow(
                  'With Driver',
                  booking.withDriver
                      ? 'Yes (+UGX 150,000/day)'
                      : 'No (Self-drive)',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cost Breakdown – FIXED OVERFLOW
            _buildSection(
              title: 'Cost Breakdown',
              children: [
                _buildRow('Daily Rate × $days days', 'UGX $subtotal'),
                _buildRow('Driver Fee', 'UGX $driverFee'),
                const Divider(),
                _buildRow(
                  'Total Amount',
                  'UGX $total',
                  isBold: true,
                  color: AppColors.orange,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: AppStyles.orangeButtonStyle,
                onPressed: () => _submitBooking(context),
                child: const Text(
                  'Confirm & Book Now',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Edit Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color ?? Colors.black87,
                fontSize: isBold ? 18 : 16,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 100,
      height: 80,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
    );
  }
}
