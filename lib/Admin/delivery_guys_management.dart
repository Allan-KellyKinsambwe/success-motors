// lib/screens/admin/delivery_guys_management.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryGuysManagementScreen extends StatelessWidget {
  const DeliveryGuysManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Guys'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add),
        onPressed: () => _showAddRiderDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('delivery_guys')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final guys = snapshot.data!.docs;

          return ListView.builder(
            itemCount: guys.length,
            itemBuilder: (context, i) {
              final data = guys[i].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.delivery_dining, size: 40),
                title: Text(data['name'] ?? 'No name'),
                subtitle: Text(data['phone'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => guys[i].reference.delete(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddRiderDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Delivery Guy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('delivery_guys').add({
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'addedAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
