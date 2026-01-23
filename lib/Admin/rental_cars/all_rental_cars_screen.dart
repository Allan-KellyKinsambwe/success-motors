// lib/screens/admin/all_rental_cars_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AllRentalCarsScreen extends StatefulWidget {
  const AllRentalCarsScreen({super.key});

  @override
  State<AllRentalCarsScreen> createState() => _AllRentalCarsScreenState();
}

class _AllRentalCarsScreenState extends State<AllRentalCarsScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> _categories = ['All Categories'];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    _loadCategories();
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
          'All Rental Cars',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rental_cars')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          final int carCount = docs.length;

          // Filter cars based on search and selected category
          final filteredCars = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final make = (data['make'] as String?)?.toLowerCase() ?? '';
            final model = (data['model'] as String?)?.toLowerCase() ?? '';
            final category = data['category'] as String?;

            final matchesSearch =
                make.contains(_searchQuery) || model.contains(_searchQuery);
            final matchesCategory =
                _selectedCategory == null ||
                _selectedCategory == 'All Categories' ||
                category == _selectedCategory;

            return matchesSearch && matchesCategory;
          }).toList();

          if (carCount == 0) {
            return const Center(
              child: Text(
                'No rental cars found',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return Column(
            children: [
              // TOTAL RENTAL CARS COUNT CARD
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
                      Icons.directions_car_filled,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        Text(
                          '$carCount',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Total Rental Cars',
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
                    hintText: 'Search rental cars...',
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

              // CATEGORY FILTER
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
                    setState(() => _selectedCategory = value);
                  },
                ),
              ),

              const SizedBox(height: 16),

              // FILTERED RENTAL CAR LIST
              Expanded(
                child: filteredCars.isEmpty
                    ? const Center(
                        child: Text(
                          'No rental cars match your search/filter',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredCars.length,
                        itemBuilder: (context, index) {
                          final doc = filteredCars[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final String? make = data['make'] as String?;
                          final String? model = data['model'] as String?;
                          final String? carName =
                              (make != null && model != null)
                              ? '$make $model'
                              : 'Unnamed Car';

                          final num? pricePerDay =
                              data['rentalPricePerDay'] as num?;
                          final String? category = data['category'] as String?;
                          final String? imageUrl = data['image'] as String?;

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
                                    imageUrl != null &&
                                        imageUrl.startsWith('http')
                                    ? Image.network(
                                        imageUrl,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            _placeholderImage(),
                                      )
                                    : Image.asset(
                                        'assets/images/default_car.png',
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              title: Text(
                                carName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UGX ${pricePerDay?.toStringAsFixed(0) ?? "0"} / day',
                                  ),
                                  Text('Category: ${category ?? "Unknown"}'),
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
                                    onPressed: () => _showEditRentalCarDialog(
                                      context,
                                      doc,
                                      data,
                                      imageUrl,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _confirmDelete(context, doc, carName),
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
        title: const Text('Delete Rental Car?'),
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
      await doc.reference.delete();
    }
  }

  void _showEditRentalCarDialog(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
    String? currentImageUrl,
  ) {
    final makeCtrl = TextEditingController(text: data['make'] ?? '');
    final modelCtrl = TextEditingController(text: data['model'] ?? '');
    final priceCtrl = TextEditingController(
      text: data['rentalPricePerDay']?.toString() ?? '',
    );
    final descCtrl = TextEditingController(text: data['description'] ?? '');

    String selectedCategory =
        data['category'] ??
        (_categories.isNotEmpty
            ? _categories.firstWhere(
                (c) => c != 'All Categories',
                orElse: () => 'Other',
              )
            : 'Other');

    File? newImageFile;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Edit Rental Car'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Image preview / change
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
                    controller: makeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Make / Brand',
                    ),
                  ),
                  TextField(
                    controller: modelCtrl,
                    decoration: const InputDecoration(labelText: 'Model'),
                  ),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Rental Price per Day (UGX)',
                    ),
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
                    'make': makeCtrl.text.trim(),
                    'model': modelCtrl.text.trim(),
                    'rentalPricePerDay':
                        int.tryParse(priceCtrl.text.trim()) ?? 0,
                    'description': descCtrl.text.trim(),
                    'category': selectedCategory,
                  };

                  try {
                    String? newImageUrl = currentImageUrl;

                    if (newImageFile != null) {
                      final ref = FirebaseStorage.instance
                          .ref()
                          .child('rental_cars')
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
                          content: Text('Rental car updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error updating rental car: $e'),
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
