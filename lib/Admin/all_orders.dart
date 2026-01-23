// lib/screens/admin/all_orders.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'order_detail_screen.dart';

class AllOrdersScreen extends StatelessWidget {
  AllOrdersScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'out_for_delivery':
        return const Color(0xFF2E7D32);
      case 'preparing':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'All Orders',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No orders yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              final orderId = doc.id;

              final timestamp = (data['created_at'] as Timestamp?)?.toDate();
              final customer = data['customer'] as Map<String, dynamic>?;
              final items = data['items'] as List<dynamic>? ?? [];
              final firstItem = items.isNotEmpty
                  ? items[0] as Map<String, dynamic>
                  : null;
              final status = (data['status'] ?? 'pending').toString();
              final userId = data['user_id'] as String?;

              return Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.white,
                  leading: userId != null
                      ? FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .get(),
                          builder: (context, userSnapshot) {
                            String? photoUrl;
                            if (userSnapshot.hasData &&
                                userSnapshot.data!.exists) {
                              final userData =
                                  userSnapshot.data!.data()
                                      as Map<String, dynamic>?;
                              photoUrl = userData?['photoUrl'] as String?;
                            }

                            return CircleAvatar(
                              radius: 28,
                              backgroundImage:
                                  photoUrl != null && photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              backgroundColor: Colors.grey[300],
                              child: photoUrl == null || photoUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.white,
                                    )
                                  : null,
                            );
                          },
                        )
                      : const CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey,
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                  title: Text(
                    customer?['name'] ?? 'Unknown Customer',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UGX ${NumberFormat('#,###').format(data['total_amount'] ?? 0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (timestamp != null)
                        Text(
                          DateFormat('dd MMM yyyy • HH:mm').format(timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatStatus(status),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    if (firstItem != null)
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                firstItem['image'].toString().startsWith('http')
                                ? Image.network(
                                    firstItem['image'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    ),
                                  )
                                : Image.asset(
                                    firstItem['image'],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${firstItem['name']} × ${firstItem['quantity']}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(orderDoc: doc),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 20),
                        label: const Text('View Full Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
