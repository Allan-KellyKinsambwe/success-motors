// lib/screens/profile/inbox_screen.dart (Promotion Inbox)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null)
      return const Scaffold(body: Center(child: Text('Login required')));

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
          'Promotions & Offers', // Changed title
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      // 🌟 LISTENING TO 'promotions' COLLECTION
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('promotions') // Focus on promotions
            .orderBy('timestamp', descending: true)
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
                'No promotions available', // Changed text
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final List<DocumentSnapshot> docs = snapshot.data!.docs;

          return ListView.builder(
            key: const ValueKey('promotion_list'),
            cacheExtent: 2000,
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;

              // Promotions need to check if the CURRENT USER has read the message.
              // Since the 'promotions' collection is global, you should store read status
              // inside an array or map within the document, or use a separate sub-collection.

              // For simplicity, we will assume 'read' is a simple boolean for now,
              // but be aware this is often inadequate for global messages.

              // For a global document, you might track read status by user ID:
              // isRead: data['readBy']?.contains(userId) == true,
              // But based on your current structure, we stick to the simple boolean for now:

              return _NotificationItem(
                key: ValueKey('promotion-$docId'),
                docId: docId,
                title: data['title'] ?? 'Promotion',
                body: data['body'] ?? '',
                timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
                isRead: data['read'] == true,
                orderId: null, // Always null for promotions
                collectionName: 'promotions', // Specify collection
              );
            },
          );
        },
      ),
    );
  }
}

// 🌟 THE RE-SHARED _NotificationItem (with generic icon and collection update logic)
class _NotificationItem extends StatefulWidget {
  final String docId;
  final String title;
  final String body;
  final DateTime? timestamp;
  final bool isRead;
  final dynamic orderId;
  final String collectionName; // Now mandatory

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
  late bool _isRead = widget.isRead;

  IconData _getIcon() {
    if (widget.collectionName == 'promotions') return Icons.local_offer;
    if (widget.orderId != null) return Icons.local_shipping;
    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
        onTap: () async {
          if (!_isRead) {
            // Updating the correct collection using the passed collectionName
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
