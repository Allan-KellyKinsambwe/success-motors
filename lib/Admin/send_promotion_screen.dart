import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendPromotionScreen extends StatefulWidget {
  const SendPromotionScreen({super.key});

  @override
  State<SendPromotionScreen> createState() => _SendPromotionScreenState();
}

class _SendPromotionScreenState extends State<SendPromotionScreen> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    if (_titleCtrl.text.isEmpty || _messageCtrl.text.isEmpty) {
      // Show error if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and message.')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      // 🌟 MAJOR CHANGE: Writing to the separate 'promotions' collection
      await FirebaseFirestore.instance.collection('promotions').add({
        'title': _titleCtrl.text.trim(),
        'body': _messageCtrl.text
            .trim(), // FIX: Use 'body' to match the InboxScreen display logic
        'read':
            false, // FIX: Explicitly set 'read' status to ensure it appears as unread
        'timestamp':
            FieldValue.serverTimestamp(), // Use consistent field name for sorting
        'type': 'promotion',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promotion sent to all users!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      _titleCtrl.clear();
      _messageCtrl.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send promotion: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Promotion'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageCtrl,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 5,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _sending
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Send to All Users',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
