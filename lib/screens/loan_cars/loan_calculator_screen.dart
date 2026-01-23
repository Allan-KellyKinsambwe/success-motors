// lib/screens/loan_cars/loan_calculator_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart'; // for number formatting with commas

class LoanCalculatorScreen extends StatefulWidget {
  const LoanCalculatorScreen({super.key});

  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen> {
  final _loanAmountCtrl = TextEditingController(text: '50,000,000');
  final _interestRateCtrl = TextEditingController(text: '18');
  final _termMonthsCtrl = TextEditingController(text: '36');

  double _emi = 0;
  double _totalInterest = 0;
  double _totalPayment = 0;

  final NumberFormat _currencyFormat = NumberFormat('#,###', 'en_US');

  void _calculate() {
    // Remove commas before parsing
    final cleanLoan = _loanAmountCtrl.text.replaceAll(',', '');
    final p = double.tryParse(cleanLoan) ?? 0;
    final annualRate = double.tryParse(_interestRateCtrl.text) ?? 0;
    final n = int.tryParse(_termMonthsCtrl.text) ?? 0;

    if (p <= 0 || n <= 0 || annualRate <= 0) {
      setState(() {
        _emi = 0;
        _totalInterest = 0;
        _totalPayment = 0;
      });
      return;
    }

    final r = annualRate / 100 / 12; // monthly rate
    _emi = (p * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
    _totalPayment = _emi * n;
    _totalInterest = _totalPayment - p;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Calculator'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calculate Your EMI',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter loan details to see monthly payment',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Loan Amount
            TextField(
              controller: _loanAmountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Loan Amount (UGX)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                prefixText: 'UGX ',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 20),

            // Interest Rate
            TextField(
              controller: _interestRateCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Annual Interest Rate (%)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                suffixText: '%',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 20),

            // Loan Term
            TextField(
              controller: _termMonthsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Loan Term (Months)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (_) => _calculate(),
            ),
            const SizedBox(height: 40),

            // Result Card
            if (_emi > 0)
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Monthly Payment',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'UGX ${_currencyFormat.format(_emi.round())}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Divider(color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Interest:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'UGX ${_currencyFormat.format(_totalInterest.round())}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Repayment:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'UGX ${_currencyFormat.format(_totalPayment.round())}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Enter values above to calculate EMI',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
