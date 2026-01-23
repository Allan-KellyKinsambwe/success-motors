// lib/screens/garage_cars/garage_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/constants/constants.dart';
import '../home_screen.dart';
import 'garage_schedule_screen.dart';
import 'garage_model.dart';

class GarageConfirmationScreen extends StatelessWidget {
  final GarageBooking booking;

  const GarageConfirmationScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 120, color: Colors.green),
              const SizedBox(height: 32),
              const Text(
                'Service Booked!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Your garage appointment has been confirmed',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Booking ID: ${booking.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${booking.carMake} ${booking.carModel}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      Text(booking.serviceType),
                      const SizedBox(height: 12),
                      Text(
                        DateFormat(
                          'dd MMMM yyyy',
                        ).format(booking.preferredDate),
                      ),
                      Text(booking.preferredTime),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(booking.status.toUpperCase()),
                        backgroundColor: Colors.orange[100],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.orangeButtonStyle,
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GarageScheduleScreen(),
                    ),
                  ),
                  child: const Text('View My Service Bookings'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
