// lib/Admin/loan/admin_loan_applications_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/screens/loan_cars/loan_model.dart';
import 'admin_loan_detail_screen.dart';

class AdminLoanApplicationsScreen extends StatelessWidget {
  const AdminLoanApplicationsScreen({super.key});

  bool _isAdmin() {
    // TODO: Replace with real check (e.g. from user document or provider)
    // For now returning true for testing - make this secure in production
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    // Optional: enforce admin check
    // if (!_isAdmin()) {
    //   return Scaffold(body: Center(child: Text('Admin access only')));
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Loan Applications'),
        backgroundColor: Colors.purple,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('loan_applications')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No loan applications yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              // FIXED: Pass real document ID to fromMap (not empty string)
              final app = LoanApplication.fromMap(data, id: doc.id);

              Color statusColor = Colors.orange;
              switch (app.status.toLowerCase()) {
                case 'approved':
                  statusColor = Colors.green;
                  break;
                case 'rejected':
                  statusColor = Colors.red;
                  break;
                case 'disbursed':
                  statusColor = Colors.blue;
                  break;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    radius: 30,
                    child: Icon(
                      Icons.attach_money,
                      color: statusColor,
                      size: 32,
                    ),
                  ),
                  title: Text(
                    '${app.carMake} ${app.carModel} (${app.carYear})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UGX ${NumberFormat('#,###').format(app.loanAmountRequested)}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${app.status.toUpperCase()}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Applied: ${DateFormat('dd MMM yyyy • HH:mm').format(app.createdAt.toDate())}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (app.adminNotes != null && app.adminNotes!.isNotEmpty)
                        Text(
                          'Notes: ${app.adminNotes}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Debug print to confirm ID is passed correctly
                    print('Admin list → opening detail for ID: ${app.id}');

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminLoanDetailScreen(application: app),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
