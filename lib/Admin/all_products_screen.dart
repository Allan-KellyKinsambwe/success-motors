// lib/screens/admin/all_products_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _categories = [
    'All Categories',
  ]; // Default with 'All Categories'

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadCategories(); // Load all categories from 'categories' collection
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .get();

      final List<String> loadedCats = ['All Categories'];
      for (var doc in snapshot.docs) {
        final name = doc.data()['name'] as String?;
        if (name != null && name.isNotEmpty) {
          loadedCats.add(name);
        }
      }

      if (mounted) {
        setState(() {
          _categories = loadedCats;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      // Keep only 'All Categories' on error
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'All Products',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final int productCount = docs.length;

          // Filter products based on search and selected category
          final filteredProducts = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] as String?)?.toLowerCase() ?? '';
            final category = data['category'] as String?;

            final matchesSearch = name.contains(_searchQuery);
            final matchesCategory =
                _selectedCategory == null ||
                _selectedCategory == 'All Categories' ||
                category == _selectedCategory;

            return matchesSearch && matchesCategory;
          }).toList();

          if (productCount == 0) {
            return const Center(
              child: Text(
                'No products found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              // TOTAL PRODUCTS COUNT CARD
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.inventory_2,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text(
                          '$productCount',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Total Products',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // SEARCH BAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF2E7D32),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // CATEGORY FILTER — Now loads ALL categories from 'categories' collection
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: const Text('Filter by Category'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // FILTERED PRODUCT LIST
              Expanded(
                child: filteredProducts.isEmpty
                    ? const Center(
                        child: Text(
                          'No products match your search/filter',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final doc = filteredProducts[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final String? name = data['name'] as String?;
                          final num? price = data['price'] as num?;
                          final String? unit = data['unit'] as String?;
                          final String? currentImageUrl =
                              data['image'] as String?;
                          final String? description =
                              data['description'] as String?;
                          final String? category = data['category'] as String?;

                          final dynamic stockDynamic = data['stock'];
                          final bool inStock =
                              (stockDynamic is num && stockDynamic > 0) ||
                              (stockDynamic is int && stockDynamic > 0);

                          return Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    currentImageUrl != null &&
                                        currentImageUrl.startsWith('http')
                                    ? Image.network(
                                        currentImageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _placeholderImage(),
                                      )
                                    : Image.asset(
                                        currentImageUrl ??
                                            'assets/products/placeholder.jpg',
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              title: Text(
                                name ?? 'No name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('UGX ${price ?? 0} • ${unit ?? ''}'),
                                  Text('Category: ${category ?? 'None'}'),
                                  const SizedBox(height: 4),
                                  Text(
                                    inStock ? 'In Stock' : 'Out of Stock',
                                    style: TextStyle(
                                      color: inStock
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () => _showEditProductDialog(
                                      context,
                                      doc,
                                      data,
                                      currentImageUrl,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _confirmDelete(context, doc, name),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 70,
      height: 70,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  void _confirmDelete(
    BuildContext context,
    QueryDocumentSnapshot doc,
    String? name,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      doc.reference.delete();
    }
  }

  void _showEditProductDialog(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    String? currentImageUrl,
  ) {
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final priceCtrl = TextEditingController(
      text: data['price']?.toString() ?? '',
    );
    final unitCtrl = TextEditingController(text: data['unit'] ?? '');
    final descCtrl = TextEditingController(text: data['description'] ?? '');

    String selectedCategory =
        data['category'] ??
        (_categories.isNotEmpty
            ? _categories.firstWhere(
                (c) => c != 'All Categories',
                orElse: () => 'Others',
              )
            : 'Others');

    final dynamic stockDynamic = data['stock'];
    bool inStock =
        (stockDynamic is num && stockDynamic > 0) ||
        (stockDynamic is int && stockDynamic > 0);

    File? newImageFile;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Edit Product'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (picked != null) {
                        setDialogState(() {
                          newImageFile = File(picked.path);
                        });
                      }
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[100],
                      ),
                      child: newImageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                newImageFile!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : currentImageUrl != null &&
                                currentImageUrl.startsWith('http')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                currentImageUrl,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to change image',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Price (UGX)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: unitCtrl,
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: _categories
                        .where((c) => c != 'All Categories')
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedCategory = val!),
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('In Stock?'),
                      const Spacer(),
                      Switch(
                        value: inStock,
                        activeColor: const Color(0xFF2E7D32),
                        onChanged: (val) => setDialogState(() => inStock = val),
                      ),
                    ],
                  ),
                ],
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
                ),
                onPressed: () async {
                  final updatedData = {
                    'name': nameCtrl.text.trim(),
                    'price': int.tryParse(priceCtrl.text.trim()) ?? 0,
                    'unit': unitCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'category': selectedCategory,
                    'stock': inStock ? 999 : 0,
                  };

                  try {
                    String? newImageUrl = currentImageUrl;

                    if (newImageFile != null) {
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('products')
                          .child(
                            '${DateTime.now().millisecondsSinceEpoch}.jpg',
                          );

                      await ref.putFile(
                        newImageFile!,
                        SettableMetadata(contentType: 'image/jpeg'),
                      );
                      newImageUrl = await ref.getDownloadURL();
                      updatedData['image'] = newImageUrl;
                    }

                    await doc.reference.update(updatedData);

                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Product updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating product: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
