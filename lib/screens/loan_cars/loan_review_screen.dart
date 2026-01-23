// lib/screens/loan_cars/loan_review_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/constants/constants.dart';
import 'loan_model.dart';
import 'loan_confirmation_screen.dart';

class LoanReviewScreen extends StatelessWidget {
  final LoanApplication application;

  const LoanReviewScreen({super.key, required this.application});

  Future<void> _submitLoan(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Make sure createdAt is set (should already be from previous screen)
      final appToSave = application;

      // Save to Firestore (without id - let Firestore generate it)
      final docRef = await FirebaseFirestore.instance
          .collection('loan_applications')
          .add(appToSave.toMap());

      // Create updated version with the real document ID
      final updatedApplication = appToSave.copyWith(id: docRef.id);

      // Debug: Confirm real ID is being passed
      print('Loan submitted successfully. Document ID: ${docRef.id}');
      print(
        'Navigating to confirmation with updated ID: ${updatedApplication.id}',
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              LoanConfirmationScreen(application: updatedApplication),
        ),
      );
    } catch (e) {
      print('Submit loan error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting loan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Review Application')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please review your details',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _ReviewSection(
                    title: 'Personal Info',
                    items: [
                      'Full Name: ${application.firstName} ${application.surname}',
                      'Email: ${application.email}',
                      'Phone: ${application.phoneNumber}',
                      'Monthly Income: UGX ${NumberFormat('#,###').format(application.monthlyIncome)}',
                      'Employment: ${application.employmentStatus}',
                      'National ID: ${application.nationalId}',
                      'Address: ${application.address}',
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ReviewSection(
                    title: 'Car Details',
                    items: [
                      'Make: ${application.carMake}',
                      'Model: ${application.carModel}',
                      'Year: ${application.carYear}',
                    ],
                  ),
                  const SizedBox(height: 24),
                  _ReviewSection(
                    title: 'Loan Details',
                    items: [
                      'Amount Requested: UGX ${NumberFormat('#,###').format(application.loanAmountRequested)}',
                      'Term: ${application.loanTermMonths} months',
                      'Interest Rate: ${(application.interestRateAnnual * 100).toStringAsFixed(1)}%',
                      if (application.monthlyEMI > 0)
                        'Estimated Monthly EMI: UGX ${NumberFormat('#,###').format(application.monthlyEMI)}',
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppStyles.orangeButtonStyle,
                onPressed: () => _submitLoan(context),
                child: const Text('Submit Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ReviewSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(item),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
