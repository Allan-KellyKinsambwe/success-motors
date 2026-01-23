// lib/screens/loan_cars/loan_schedule_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:success_motors/constants/constants.dart';
import 'dart:math';
import 'loan_model.dart';

class LoanScheduleScreen extends StatefulWidget {
  final LoanApplication application;

  const LoanScheduleScreen({super.key, required this.application});

  @override
  State<LoanScheduleScreen> createState() => _LoanScheduleScreenState();
}

class _LoanScheduleScreenState extends State<LoanScheduleScreen> {
  late List<Map<String, dynamic>> _schedule;
  late double _emi;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    // Debug: Show exactly what ID we received
    print(
      'Schedule screen received ID: "${widget.application.id}" (length: ${widget.application.id?.length ?? 0})',
    );

    _calculateSchedule();
  }

  Future<void> _calculateSchedule() async {
    final receivedId = widget.application.id;

    // More precise guard + debug
    if (receivedId == null || receivedId.trim().isEmpty) {
      print('Guard triggered: ID is null or empty → showing error message');
      setState(() {
        _error =
            'Application ID is missing or invalid. Please resubmit the loan application.';
        _isLoading = false;
      });
      return;
    }

    print(
      'Valid ID detected: $receivedId → proceeding to calculate & save schedule',
    );

    try {
      final p = widget.application.loanAmountRequested.toDouble();
      final r = widget.application.interestRateAnnual / 12;
      final n = widget.application.loanTermMonths;

      _emi = (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);

      double balance = p;
      _schedule = [];
      for (int i = 1; i <= n; i++) {
        final interest = balance * r;
        final principal = _emi - interest;
        balance -= principal;
        _schedule.add({
          'month': i,
          'emi': _emi,
          'principal': principal,
          'interest': interest,
          'balance': balance.abs() < 0.01 ? 0 : balance,
        });
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('loan_applications')
          .doc(receivedId)
          .update({'repaymentSchedule': _schedule});

      print('Schedule saved successfully to document: $receivedId');

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error in _calculateSchedule: $e');
      setState(() {
        _error = 'Error calculating/saving schedule: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loan Schedule')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 18, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Loan Repayment Schedule')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('Monthly EMI', style: TextStyle(fontSize: 18)),
                Text(
                  'UGX ${_emi.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _schedule.length,
              itemBuilder: (_, i) {
                final entry = _schedule[i];
                return ListTile(
                  title: Text('Month ${entry['month']}'),
                  subtitle: Text(
                    'Principal: UGX ${entry['principal'].toStringAsFixed(0)}\n'
                    'Interest: UGX ${entry['interest'].toStringAsFixed(0)}\n'
                    'Balance: UGX ${entry['balance'].toStringAsFixed(0)}',
                  ),
                  trailing: Text('EMI: UGX ${entry['emi'].toStringAsFixed(0)}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
