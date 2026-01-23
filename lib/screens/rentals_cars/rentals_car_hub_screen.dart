// lib/screens/rental_cars/rentals_car_hub_screen.dart
import 'package:flutter/material.dart';
import 'rental_booking_screen.dart';
import 'rental_schedule_screen.dart';
import 'rental_car_list_screen.dart'; // ← NEW IMPORT ADDED
import 'package:success_motors/constants/constants.dart';

class RentalsCarHubScreen extends StatelessWidget {
  const RentalsCarHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Car Rentals'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Rent a Car Today',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose from our wide range of vehicles — self-drive or with driver',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            _rentalCard(
              context,
              icon: Icons.directions_car_filled_outlined,
              title: 'Rent a New Car',
              subtitle: 'Browse & book luxury, SUVs, economy cars & more',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RentalCarListScreen(), // ← CHANGED HERE
                ),
              ),
            ),

            const SizedBox(height: 16),

            _rentalCard(
              context,
              icon: Icons.calendar_month_outlined,
              title: 'My Rentals',
              subtitle: 'View upcoming, ongoing & past rentals',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RentalScheduleScreen()),
              ),
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Get 15% off your first rental with code: FIRSTRENTAL',
                style: TextStyle(color: Colors.orange[900]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rentalCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                child: Icon(icon, size: 36, color: const Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xFF2E7D32)),
            ],
          ),
        ),
      ),
    );
  }
}
