// lib/screens/profile/full_order_history_details.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:success_motors/screens/track_order_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FullOrderDetailsScreen extends StatefulWidget {
  final DocumentSnapshot orderDoc;

  const FullOrderDetailsScreen({super.key, required this.orderDoc});

  @override
  State<FullOrderDetailsScreen> createState() => _FullOrderDetailsScreenState();
}

class _FullOrderDetailsScreenState extends State<FullOrderDetailsScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();

  // FIXED: Safe Re-order — handles null values
  Future<void> _reorder() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> cartList = [];

      final data = widget.orderDoc.data() as Map<String, dynamic>;
      final items = (data['items'] as List?) ?? [];

      for (var item in items) {
        // Safely extract values with fallbacks
        final productMap = {
          'id':
              item['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          'name': item['name']?.toString() ?? 'Unknown Item',
          'price': item['price'] is int
              ? item['price']
              : (item['price'] is double ? item['price'].toInt() : 0),
          'image': item['image']?.toString() ?? '',
          'quantity': item['quantity'] is int
              ? item['quantity']
              : (item['quantity'] is String
                    ? int.tryParse(item['quantity']) ?? 1
                    : 1),
        };
        cartList.add(jsonEncode(productMap));
      }

      await prefs.setStringList('cart_items_list', cartList);
      await prefs.setInt('cart_count', cartList.length);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All items added to cart!'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Optional: Go to cart or home
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error re-ordering: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rate Your Delivery', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How was your experience?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: 'Add a comment (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2E7D32),
                    width: 2,
                  ),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_rating == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a rating')),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('orders')
                  .doc(widget.orderDoc.id)
                  .update({
                    'rating': _rating,
                    'feedback': _feedbackController.text.trim().isEmpty
                        ? null
                        : _feedbackController.text.trim(),
                    'ratedAt': FieldValue.serverTimestamp(),
                  });

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.orderDoc.data() as Map<String, dynamic>;
    final customer = data['customer'] as Map<String, dynamic>? ?? {};
    final items = (data['items'] as List?) ?? [];
    final timestamp = (data['created_at'] as Timestamp?)?.toDate();
    final status = (data['status'] ?? 'pending').toString().toLowerCase();

    final orderNumber =
        data['order_number'] ??
        '#FB${widget.orderDoc.id.substring(0, 6).toUpperCase()}';
    final paymentMethod = data['payment_method'] ?? 'Not specified';
    final notes = data['notes'] ?? 'No notes';
    final subtotal = data['subtotal'] ?? 0;
    final deliveryFee = data['delivery_fee'] ?? 5000;
    final totalAmount = data['total_amount'] ?? 0;

    Color statusColor = Colors.orange;
    if (status == 'delivered') statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;

    // Only allow rating if status is 'delivered'
    final bool canRate = status == 'delivered';

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
          'Order Details',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER CARD — FIXED OVERFLOW
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            orderNumber,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      timestamp != null
                          ? DateFormat(
                              'EEEE, dd MMMM yyyy • hh:mm a',
                            ).format(timestamp)
                          : 'Date not available',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _sectionTitle('Customer Information'),
            _infoCard([
              _infoRow(
                Icons.person,
                'Name',
                customer['name'] ?? 'Not provided',
              ),
              _infoRow(
                Icons.phone,
                'Phone',
                customer['phone'] ?? 'Not provided',
              ),
              _infoRow(
                Icons.location_on,
                'Delivery Address',
                customer['address'] ?? 'Not provided',
              ),
              if (notes != 'No notes') _infoRow(Icons.note, 'Notes', notes),
            ]),

            const SizedBox(height: 24),
            _sectionTitle('Payment Method'),
            _infoCard([
              Row(
                children: [
                  Icon(
                    paymentMethod.contains('Cash')
                        ? Icons.money
                        : paymentMethod.contains('Mobile')
                        ? Icons.phone_android
                        : Icons.credit_card,
                    color: const Color(0xFF2E7D32),
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    paymentMethod,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: 24),
            _sectionTitle('Order Items (${items.length})'),
            ...items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            (item['image']?.toString() ?? '').startsWith('http')
                            ? Image.network(
                                item['image'],
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.fastfood,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                    ? child
                                    : Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ),
                              )
                            : Image.asset(
                                item['image'] ??
                                    'assets/products/placeholder.jpg',
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 70,
                                  height: 70,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                  ),
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'UGX ${item['price'] ?? 0}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '×${item['quantity'] ?? 1}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _sectionTitle('Price Breakdown'),
            _infoCard([
              _priceRow('Subtotal', subtotal),
              _priceRow('Delivery Fee', deliveryFee),
              const Divider(height: 30),
              _priceRow('Total Amount', totalAmount, isTotal: true),
            ]),

            // ACTION BUTTONS
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final String orderId = widget.orderDoc.id;
                  if (orderId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cannot track order: Invalid order ID'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrackOrderScreen(orderId: orderId),
                    ),
                  );
                },
                icon: const Icon(Icons.track_changes, size: 24),
                label: const Text(
                  'Track Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _reorder,
                icon: const Icon(Icons.shopping_basket_outlined),
                label: const Text(
                  'Re-order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  side: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),

            if (canRate)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showRatingDialog,
                    icon: const Icon(Icons.star_outline, color: Colors.amber),
                    label: const Text(
                      'Rate Delivery',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.amber, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E7D32),
      ),
    ),
  );

  Widget _infoCard(List<Widget> children) => Card(
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: children),
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF2E7D32), size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _priceRow(String label, int amount, {bool isTotal = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 20 : 18,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          'UGX ${NumberFormat('#,###').format(amount)}',
          style: TextStyle(
            fontSize: isTotal ? 26 : 20,
            fontWeight: FontWeight.bold,
            color: isTotal ? const Color(0xFF2E7D32) : Colors.black87,
          ),
        ),
      ],
    ),
  );
}
