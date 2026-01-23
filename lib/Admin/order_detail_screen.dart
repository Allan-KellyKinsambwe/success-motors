// lib/screens/admin/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:success_motors/Admin/status_messages.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  final DocumentSnapshot orderDoc;

  const OrderDetailScreen({super.key, required this.orderDoc});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late String currentStatus;

  final List<String> statuses = [
    'pending',
    'confirmed',
    'preparing',
    'out_for_delivery',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    final data = widget.orderDoc.data() as Map<String, dynamic>;
    currentStatus = (data['status'] ?? 'pending').toString();
  }

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
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
  }

  Future<void> _updateStatus(String newStatus) async {
    final data = widget.orderDoc.data() as Map<String, dynamic>;
    final orderId = widget.orderDoc.id;
    final firstItemName = (data['items'] as List<dynamic>?)?.isNotEmpty == true
        ? (data['items'][0] as Map)['name']
        : 'your order';

    try {
      if (newStatus == 'out_for_delivery') {
        final selectedRider = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => const _DeliveryGuyPickerDialog(),
        );

        if (selectedRider == null) return;

        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
              'status': newStatus,
              'out_for_delivery_at': FieldValue.serverTimestamp(),
              'delivery_guy': {
                'id': selectedRider['id'],
                'name': selectedRider['name'],
                'phone': selectedRider['phone'],
              },
            });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Assigned to ${selectedRider['name']}')),
          );
        }
      } else {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .update({
              'status': newStatus,
              '${newStatus}_at': FieldValue.serverTimestamp(),
            });
      }

      final userId = data['user_id'] as String?;
      if (userId != null) {
        await OrderStatusService.sendOrderStatusMessage(
          orderId: orderId,
          userId: userId,
          newStatus: newStatus,
          productName: firstItemName,
          riderName: newStatus == 'out_for_delivery'
              ? (data['delivery_guy']?['name'])
              : null,
        );
      }

      setState(() => currentStatus = newStatus);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${_formatStatus(newStatus)}'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.orderDoc.data() as Map<String, dynamic>;
    final customer = data['customer'] as Map<String, dynamic>?;
    final items = (data['items'] as List<dynamic>?) ?? [];
    final timestamp = (data['created_at'] as Timestamp?)?.toDate();
    final userId = data['user_id'] as String?;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: Text(
          '#${data['order_number'] ?? 'N/A'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info + Address
            FutureBuilder<DocumentSnapshot>(
              future: userId != null
                  ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get()
                  : null,
              builder: (context, snapshot) {
                final userData = snapshot.hasData && snapshot.data!.exists
                    ? snapshot.data!.data() as Map<String, dynamic>?
                    : null;
                final photoUrl = userData?['photoUrl'] as String?;
                final email = userData?['email'] as String?;

                return Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage:
                                  photoUrl != null && photoUrl.isNotEmpty
                                  ? NetworkImage(photoUrl)
                                  : null,
                              backgroundColor: Colors.grey[300],
                              child: photoUrl == null || photoUrl.isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer?['name'] ?? 'Unknown Customer',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (email != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text('Phone: ${customer?['phone'] ?? 'N/A'}'),
                                  if (customer?['alternative_phone'] != null)
                                    Text(
                                      'Alt: ${customer?['alternative_phone']}',
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFF2E7D32),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Delivery Address',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customer?['address'] ?? 'Not provided',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Status Dropdown
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Order Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<String>(
                      value: currentStatus,
                      underline: Container(),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF2E7D32),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      items: statuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(_formatStatus(status)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null && val != currentStatus) {
                          _updateStatus(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Items
            const Text(
              'Ordered Items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...items.map((itemMap) {
              final item = itemMap as Map<String, dynamic>;
              final String imagePath = item['image'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imagePath.startsWith('http')
                            ? Image.network(
                                imagePath,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image),
                                ),
                              )
                            : Image.asset(
                                imagePath,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'Unknown Item',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text('Quantity: ${item['quantity'] ?? 1}'),
                            Text(
                              'UGX ${NumberFormat('#,###').format(item['price'] ?? 0)} each',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'UGX ${NumberFormat('#,###').format((item['price'] ?? 0) * (item['quantity'] ?? 1))}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Order Summary
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _summaryRow('Subtotal', data['subtotal'] ?? 0),
                    _summaryRow('Delivery Fee', data['delivery_fee'] ?? 5000),
                    const Divider(height: 32),
                    _summaryRow(
                      'Total Paid',
                      data['total_amount'] ?? 0,
                      isBold: true,
                    ),
                    const SizedBox(height: 16),
                    Text('Payment Method: ${data['payment_method'] ?? 'N/A'}'),
                    if (timestamp != null)
                      Text(
                        'Order Placed: ${DateFormat('dd MMMM yyyy • HH:mm').format(timestamp)}',
                      ),
                    if (data['notes'] != null &&
                        (data['notes'] as String).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text('Customer Notes: ${data['notes']}'),
                      ),
                    if (data['delivery_guy'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delivery_dining,
                              color: Color(0xFF2E7D32),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Assigned to: ${data['delivery_guy']['name']}',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, int amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 17,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            'UGX ${NumberFormat('#,###').format(amount)}',
            style: TextStyle(
              fontSize: isBold ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: isBold ? const Color(0xFF2E7D32) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// Delivery Guy Picker Dialog (unchanged)
class _DeliveryGuyPickerDialog extends StatelessWidget {
  const _DeliveryGuyPickerDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Assign Delivery Guy',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('delivery_guys')
              .orderBy('name')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No delivery guys available'));
            }

            final guys = snapshot.data!.docs;

            return ListView.builder(
              itemCount: guys.length,
              itemBuilder: (context, i) {
                final guyData = guys[i].data() as Map<String, dynamic>;
                final guyId = guys[i].id;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF2E7D32),
                      child: Icon(Icons.delivery_dining, color: Colors.white),
                    ),
                    title: Text(
                      guyData['name'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(guyData['phone'] ?? 'No phone'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pop(context, {
                      'id': guyId,
                      'name': guyData['name'],
                      'phone': guyData['phone'],
                    }),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
