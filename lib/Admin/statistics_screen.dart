// lib/screens/admin/statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'Statistics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Row 1
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Products',
                      'products',
                      Icons.inventory,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Active Users',
                      'users',
                      Icons.people,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Delivery Guys',
                      'delivery_guys',
                      Icons.delivery_dining,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFutureStatCard(
                      'Total Downloads',
                      'users',
                      Icons.download,
                      (count) => count,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Revenue by Order Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 12),
              _buildRevenueByStatus(),
              const SizedBox(height: 24),
              const Text(
                'Orders by Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 12),
              _buildOrdersByPaymentMethod(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String collection, IconData icon) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.data?.docs.length ?? 0;
        return _statCard(title, count.toString(), icon, Colors.blue);
      },
    );
  }

  Widget _buildFutureStatCard(
    String title,
    String collection,
    IconData icon,
    int Function(int) mapper,
  ) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection(collection).get(),
      builder: (context, snapshot) {
        int count = mapper(snapshot.data?.docs.length ?? 0);
        return _statCard(title, count.toString(), icon, Colors.orange);
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueByStatus() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        Map<String, double> revenueByStatus = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] ?? 'pending';
          final amount = (data['total_amount'] as num?)?.toDouble() ?? 0.0;
          revenueByStatus[status] = (revenueByStatus[status] ?? 0) + amount;
        }

        return Column(
          children: revenueByStatus.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(Icons.monetization_on, color: Colors.green),
                title: Text(_formatStatus(entry.key)),
                trailing: Text(
                  'UGX ${NumberFormat('#,###').format(entry.value)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildOrdersByPaymentMethod() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        Map<String, int> countByMethod = {};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final method = data['payment_method'] ?? 'Unknown';
          countByMethod[method] = (countByMethod[method] ?? 0) + 1;
        }

        return Column(
          children: countByMethod.entries.map((entry) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(Icons.payment, color: Colors.purple),
                title: Text(
                  entry.key == 'Unknown' ? 'Not Specified' : entry.key,
                ),
                trailing: Text(
                  '${entry.value} orders',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
