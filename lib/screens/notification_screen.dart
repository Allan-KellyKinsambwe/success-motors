// lib/screens/notification_screen.dart (Order Status Updates)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// NOTE: You must include the _NotificationItem and _NotificationItemState
// classes in this file (or a shared file) for this code to work.
// They are included below this main class.

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // NOTE: This helper function is now unused since we are using _NotificationItem
  // but it's kept here just in case.
  IconData _getIcon(String type) {
    switch (type) {
      case 'order_status':
        return Icons.local_shipping;
      case 'promotion':
        return Icons.local_offer;
      case 'gift':
        return Icons.card_giftcard;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Updates', // Changed title to reflect content
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications') // Focused on Order Status
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No order updates yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const Text('All orders are up-to-date!'),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;

              // 🌟 Using the interactive _NotificationItem for Order Status
              return _NotificationItem(
                key: ValueKey('order-$docId'),
                docId: docId,
                title: data['title'] ?? 'Order Notification',
                body: data['body'] ?? '',
                timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
                isRead: data['read'] == true,
                orderId: data['orderId'],
                collectionName:
                    'notifications', // Specifies the collection for update
              );
            },
          );
        },
      ),
    );
  }
}

// --- 🌟 INTERACTIVE NOTIFICATION ITEM (REUSED FROM INBOX) ---

// THIS IS THE ONLY THING THAT STOPS DISAPPEARING (Because it controls the local state)
class _NotificationItem extends StatefulWidget {
  final String docId;
  final String title;
  final String body;
  final DateTime? timestamp;
  final bool isRead;
  final dynamic orderId;
  final String collectionName; // To ensure the correct collection is updated

  const _NotificationItem({
    required Key key,
    required this.docId,
    required this.title,
    required this.body,
    this.timestamp,
    required this.isRead,
    this.orderId,
    required this.collectionName,
  }) : super(key: key);

  @override
  State<_NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<_NotificationItem> {
  // Local state to manage visual changes immediately on tap
  late bool _isRead = widget.isRead;

  // Helper to determine the icon
  IconData _getIcon() {
    // Since this screen is dedicated to Order Updates, the logic is simple
    return Icons.local_shipping;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      // Elevation and color change based on local read status
      elevation: _isRead ? 2 : 8,
      color: _isRead ? Colors.white : const Color(0xFFE8F5E8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _isRead ? Colors.grey[300] : const Color(0xFF2E7D32),
          child: Icon(_getIcon(), color: Colors.white),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: _isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.body, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (widget.orderId != null)
              Text(
                'Order #${widget.orderId}',
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Unread dot indicator
            if (!_isRead)
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              widget.timestamp != null ? _formatTime(widget.timestamp!) : 'Now',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        // 🌟 Firestore update happens ONLY on tap
        onTap: () async {
          if (!_isRead) {
            await FirebaseFirestore.instance
                .collection(widget.collectionName)
                .doc(widget.docId)
                .update({'read': true});
            setState(() => _isRead = true);
          }
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(date);
  }
}
