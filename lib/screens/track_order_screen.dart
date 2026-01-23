// lib/screens/track_order_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// Removed: import 'live_tracking_screen.dart';  // No longer needed

class TrackOrderScreen extends StatefulWidget {
  final String orderId;
  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Track Order',
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading order'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'pending';
          final deliveryGuy = data['delivery_guy'] as Map<String, dynamic>?;

          final List<dynamic>? items = data['items'] as List<dynamic>?;
          final Map<String, dynamic>? firstItem = items?.isNotEmpty == true
              ? items!.first as Map<String, dynamic>?
              : null;

          final String? itemImage = firstItem?['image'] as String?;

          final isOutForDelivery = status == 'out_for_delivery';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Summary Card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child:
                              itemImage != null && itemImage.startsWith('http')
                              ? Image.network(
                                  itemImage,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholderImage(),
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return _placeholderImage();
                                      },
                                )
                              : itemImage != null
                              ? Image.asset(
                                  itemImage,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholderImage(),
                                )
                              : _placeholderImage(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${data['order_number'] ?? widget.orderId}',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'UGX ${NumberFormat('#,###').format(data['total_amount'] ?? 0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    status,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: TextStyle(
                                    color: _getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'Order Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSystematicTimeline(data, status),

                // Delivery Guy Info Button (kept)
                if (isOutForDelivery && deliveryGuy != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showDeliveryGuyDialog(deliveryGuy),
                        icon: const Icon(Icons.person, size: 24),
                        label: const Text(
                          'View Delivery Guy Info',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                        ),
                      ),
                    ),
                  ),

                // REMOVED: Live Tracking Button entirely
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[300],
      child: const Icon(Icons.fastfood, size: 40, color: Colors.grey),
    );
  }

  void _showDeliveryGuyDialog(Map<String, dynamic> deliveryGuy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delivery Guy Info',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF2E7D32),
              child: Icon(Icons.delivery_dining, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              deliveryGuy['name'] ?? 'Delivery Partner',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              deliveryGuy['phone'] ?? 'No phone available',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystematicTimeline(
    Map<String, dynamic> data,
    String currentStatus,
  ) {
    final List<Map<String, String>> steps = [
      {'title': 'Order Placed', 'field': 'created_at'},
      {'title': 'Confirmed', 'field': 'confirmed_at'},
      {'title': 'Preparing', 'field': 'preparing_at'},
      {'title': 'Out for Delivery', 'field': 'out_for_delivery_at'},
      {'title': 'Delivered', 'field': 'delivered_at'},
    ];

    final statusOrder = [
      'pending',
      'confirmed',
      'preparing',
      'out_for_delivery',
      'delivered',
    ];
    final currentIndex = statusOrder.indexOf(currentStatus);

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final Timestamp? timestamp = data[step['field']] as Timestamp?;
        final bool isCompleted = index <= currentIndex && currentIndex >= 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isCompleted
                        ? const Color(0xFF2E7D32)
                        : Colors.grey[300],
                    child: isCompleted
                        ? const Icon(Icons.check, size: 20, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                  ),
                  if (index < steps.length - 1)
                    Container(
                      height: 50,
                      width: 2,
                      color: isCompleted
                          ? const Color(0xFF2E7D32)
                          : Colors.grey[300],
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['title']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCompleted
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCompleted ? Colors.black87 : Colors.grey,
                      ),
                    ),
                    Text(
                      timestamp != null
                          ? DateFormat(
                              'dd MMM, HH:mm',
                            ).format(timestamp.toDate())
                          : 'Pending',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    return switch (status) {
      'delivered' => Colors.green,
      'out_for_delivery' => const Color(0xFF2E7D32),
      'preparing' || 'confirmed' => Colors.orange,
      _ => Colors.grey,
    };
  }

  String _getStatusText(String status) {
    return switch (status) {
      'pending' => 'Pending',
      'confirmed' => 'Confirmed',
      'preparing' => 'Preparing',
      'out_for_delivery' => 'Out for Delivery',
      'delivered' => 'Delivered',
      _ => status[0].toUpperCase() + status.substring(1).replaceAll('_', ' '),
    };
  }
}
