// lib/screens/rental_cars/rental_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/constants/constants.dart';
import 'rental_model.dart';
import '../home_screen.dart';
import 'rental_schedule_screen.dart';

class RentalConfirmationScreen extends StatelessWidget {
  final RentalBooking booking;

  const RentalConfirmationScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 120, color: Colors.green),
              const SizedBox(height: 32),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Your rental for ${booking.carMake} ${booking.carModel} has been confirmed.',
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Booking ID: ${booking.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pickup: ${DateFormat('dd MMM yyyy').format(booking.pickupDate)}',
                      ),
                      Text(
                        'Dropoff: ${DateFormat('dd MMM yyyy').format(booking.dropoffDate)}',
                      ),
                      Text('Total: UGX ${booking.totalAmount}'),
                      Text('Status: ${booking.status.toUpperCase()}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.orangeButtonStyle,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RentalScheduleScreen(),
                      ),
                    );
                  },
                  child: const Text('View My Rentals'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
