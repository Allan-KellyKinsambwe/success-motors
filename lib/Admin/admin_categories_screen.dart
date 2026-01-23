// lib/screens/admin/admin_categories_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCategoriesScreen extends StatelessWidget {
  AdminCategoriesScreen({super.key});

  // Same mapping as in your CategoryScreen
  final Map<String, Map<String, dynamic>> iconMap = {
    'Fruits': {'icon': Icons.local_florist, 'color': Colors.orange},
    'Vegetables': {'icon': Icons.eco, 'color': Colors.green},
    'Dairy': {'icon': Icons.local_drink, 'color': Colors.blue},
    'Snacks': {'icon': Icons.fastfood, 'color': Colors.pink},
    'Beverages': {'icon': Icons.local_bar, 'color': Colors.purple},
    'Meat & Fish': {'icon': Icons.restaurant, 'color': Colors.red},
  };

  IconData _getIcon(String name) {
    return iconMap[name]?['icon'] ?? Icons.category;
  }

  Color _getColor(String name) {
    return iconMap[name]?['color'] ?? Colors.grey;
  }

  void _showAddEditDialog(
    BuildContext context, [
    DocumentSnapshot? categoryDoc,
  ]) {
    final isEdit = categoryDoc != null;
    final nameCtrl = TextEditingController(
      text: isEdit ? categoryDoc['name'] : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isEdit ? 'Edit Category' : 'Add New Category'),
        content: TextField(
          controller: nameCtrl,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              if (isEdit) {
                categoryDoc!.reference.update({'name': name}).then((_) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category updated!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                });
              } else {
                FirebaseFirestore.instance
                    .collection('categories')
                    .add({'name': name})
                    .then((_) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Category added!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    });
              }
            },
            child: Text(
              isEdit ? 'Save' : 'Add',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'Manage Categories',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2E7D32),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEditDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('categories')
            .orderBy('name')
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
                'No categories yet.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final categories = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final doc = categories[index];
              final name = doc['name'] as String;

              final icon = _getIcon(name);
              final color = _getColor(name);

              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, size: 32, color: color),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddEditDialog(context, doc),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Category?'),
                              content: Text(
                                'Delete "$name"? Products in this category will lose their category.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            doc.reference.delete();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
