// lib/screens/loan_cars/loan_confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:success_motors/constants/constants.dart';
import 'package:success_motors/screens/home_screen.dart';
import 'loan_model.dart';
import 'loan_schedule_screen.dart';

class LoanConfirmationScreen extends StatelessWidget {
  final LoanApplication application;

  const LoanConfirmationScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    // Debug print when screen builds
    print('Confirmation screen received ID: ${application.id ?? "MISSING"}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 100, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Application Submitted!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Your car loan application for ${application.carMake} ${application.carModel} has been submitted successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              SelectableText(
                'Application ID: ${application.id ?? "Not available"}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppStyles.orangeButtonStyle,
                  onPressed: () {
                    // Debug print before navigation
                    print(
                      'Confirmation → navigating to schedule with ID: ${application.id ?? "MISSING"}',
                    );

                    if (application.id == null || application.id!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Cannot view schedule — application not saved.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LoanScheduleScreen(application: application),
                      ),
                    );
                  },
                  child: const Text('View Loan Schedule'),
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
