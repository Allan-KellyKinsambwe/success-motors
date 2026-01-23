// lib/screens/garage_cars/garage_hub_screen.dart
import 'package:flutter/material.dart';
import 'garage_booking_screen.dart';
import 'garage_schedule_screen.dart';
import 'package:success_motors/constants/constants.dart';

class GarageHubScreen extends StatelessWidget {
  const GarageHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Online Garage'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Garage Services',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Book professional car service or check your existing appointments',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // Big action cards
            _serviceCard(
              context,
              icon: Icons.add_circle_outline,
              title: 'Book New Service',
              subtitle: 'Schedule oil change, brakes, diagnostics & more',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GarageBookingScreen()),
              ),
            ),

            const SizedBox(height: 16),

            _serviceCard(
              context,
              icon: Icons.calendar_today_outlined,
              title: 'My Bookings',
              subtitle: 'View upcoming & past garage appointments',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GarageScheduleScreen()),
              ),
            ),

            // You can add more cards later (e.g. Service History, Quotes, etc.)
            const Spacer(),

            // Optional: Quick tip or promo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Get 10% off your first garage booking with code: FIRSTGARAGE',
                style: TextStyle(color: Colors.orange),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceCard(
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
