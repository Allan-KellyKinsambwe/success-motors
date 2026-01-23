import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/screens/loan_cars/loan_model.dart';

class AdminLoanDetailScreen extends StatefulWidget {
  final LoanApplication application;

  const AdminLoanDetailScreen({super.key, required this.application});

  @override
  State<AdminLoanDetailScreen> createState() => _AdminLoanDetailScreenState();
}

class _AdminLoanDetailScreenState extends State<AdminLoanDetailScreen> {
  final _notesController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _updateStatus(String newStatus, {String? notes}) async {
    setState(() => _isProcessing = true);

    final docId = widget.application.id;
    if (docId == null || docId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot update — application ID is missing or invalid'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isProcessing = false);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('loan_applications')
          .doc(docId)
          .update({
            'status': newStatus,
            'adminNotes': notes ?? FieldValue.delete(),
            'updatedAt': Timestamp.now(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application $newStatus successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.application;

    return Scaffold(
      appBar: AppBar(title: Text('${app.carMake} ${app.carModel} Application')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Applicant', [
                  'Name: ${app.firstName} ${app.surname}',
                  'Email: ${app.email}',
                  'Phone: ${app.phoneNumber}',
                  'National ID: ${app.nationalId}',
                  'Address: ${app.address}',
                  'Employment: ${app.employmentStatus}',
                  'Monthly Income: UGX ${NumberFormat('#,###').format(app.monthlyIncome)}',
                ]),
                const Divider(),
                _buildSection('Vehicle & Loan', [
                  'Car: ${app.carMake} ${app.carModel} (${app.carYear})',
                  'Market Value: UGX ${NumberFormat('#,###').format(app.carMarketValue)}',
                  'Purpose: ${app.loanPurpose}',
                  'Requested: UGX ${NumberFormat('#,###').format(app.loanAmountRequested)}',
                  'Term: ${app.loanTermMonths} months',
                  'Interest: ${(app.interestRateAnnual * 100).toStringAsFixed(1)}%',
                ]),
                const Divider(),
                if (app.nationalIdFrontUrl != null ||
                    app.nationalIdBackUrl != null ||
                    app.proofOfIncomeUrl != null)
                  _buildSection('Documents', [
                    if (app.nationalIdFrontUrl != null)
                      'National ID Front: View',
                    if (app.nationalIdBackUrl != null) 'National ID Back: View',
                    if (app.proofOfIncomeUrl != null) 'Proof of Income: View',
                  ], isLinks: true),
                const SizedBox(height: 24),
                const Text(
                  'Admin Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Notes / Rejection Reason',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => _updateStatus(
                              'rejected',
                              notes: _notesController.text.trim().isNotEmpty
                                  ? _notesController.text.trim()
                                  : null,
                            ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => _updateStatus('approved'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.money),
                    label: const Text('Mark as Disbursed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: _isProcessing
                        ? null
                        : () => _updateStatus('disbursed'),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<String> items, {
    bool isLinks = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: isLinks
                ? InkWell(
                    onTap: () {
                      // TODO: Open image viewer / download URL
                    },
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(item),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
