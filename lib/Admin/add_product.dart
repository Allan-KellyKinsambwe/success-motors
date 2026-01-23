// lib/screens/admin/add_product.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedTransmission;
  String? _selectedFuelType;
  String? _selectedColor;

  bool _inStock = true;
  bool _uploading = false;

  List<String> _categories = [];

  final List<String> _transmissions = ['Automatic', 'Manual'];
  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'Hybrid', 'Electric'];
  final List<String> _colors = [
    'White',
    'Black',
    'Silver',
    'Grey',
    'Blue',
    'Red',
    'Green',
    'Brown',
    'Yellow',
    'Other',
  ];

  // Guided photo sections
  final List<Map<String, dynamic>> _photoSections = [
    {'label': 'Front 3/4 Angle (Hero Shot)', 'key': 'front34'},
    {'label': 'Rear 3/4 Angle', 'key': 'rear34'},
    {'label': 'Side Profile (Driver Side)', 'key': 'sideDriver'},
    {'label': 'Side Profile (Passenger Side)', 'key': 'sidePassenger'},
    {'label': 'Front Straight', 'key': 'front'},
    {'label': 'Rear Straight', 'key': 'rear'},
    {'label': 'Dashboard & Steering', 'key': 'dashboard'},
    {'label': 'Rear Seats', 'key': 'rearSeats'},
    {'label': 'Trunk/Boot (Open)', 'key': 'trunk'},
    {'label': 'Engine Bay (Hood Open)', 'key': 'engine'},
    {'label': 'Odometer Reading', 'key': 'odometer'},
    {'label': 'Wheels/Tires Close-up', 'key': 'wheels'},
  ];

  final Map<String, File?> _sectionImages = {};

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    for (var section in _photoSections) {
      _sectionImages[section['key']] = null;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .get();

      final List<String> cats = [];
      for (var doc in snapshot.docs) {
        final name = doc.data()['name'] as String?;
        if (name != null) cats.add(name);
      }

      if (mounted) {
        setState(() {
          _categories = cats;
          if (_categories.isNotEmpty && _selectedCategory == null) {
            _selectedCategory = _categories[0];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _pickImageForSection(String key, String label) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo with Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _sectionImages[key] = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    final selectedCount = _sectionImages.values
        .where((img) => img != null)
        .length;
    if (selectedCount < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least 6 photos of different parts'),
        ),
      );
      return;
    }

    setState(() => _uploading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in as admin')),
      );
      setState(() => _uploading = false);
      return;
    }

    try {
      final List<String> imageUrls = [];
      int index = 0;

      for (var entry in _sectionImages.entries) {
        final file = entry.value;
        if (file != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('products')
              .child('${DateTime.now().millisecondsSinceEpoch}_$index.jpg');

          await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
          index++;
        }
      }

      if (imageUrls.isEmpty) throw Exception('No images uploaded');

      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameCtrl.text.trim(),
        'price': int.parse(_priceCtrl.text.trim()),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'image': imageUrls[0],
        'images': imageUrls,
        'rating': 4.8,
        'year': _yearCtrl.text.trim().isEmpty ? null : _yearCtrl.text.trim(),
        'mileage': _mileageCtrl.text.trim().isEmpty
            ? null
            : _mileageCtrl.text.trim(),
        'transmission': _selectedTransmission,
        'fuelType': _selectedFuelType,
        'color': _selectedColor,
        'stock': _inStock ? 999 : 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Car added successfully to inventory!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Car'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Photograph Each Part (Recommended for Trust)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _photoSections.length,
              itemBuilder: (context, i) {
                final section = _photoSections[i];
                final key = section['key'] as String;
                final label = section['label'] as String;
                final imageFile = _sectionImages[key];

                return GestureDetector(
                  onTap: () => _pickImageForSection(key, label),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade400, width: 2),
                      color: Colors.grey[100],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          imageFile == null
                              ? Icons.camera_alt
                              : Icons.check_circle,
                          size: 40,
                          color: imageFile == null
                              ? Colors.grey
                              : const Color(0xFF2E7D32),
                        ),
                        const SizedBox(height: 8),
                        if (imageFile != null)
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                imageFile,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Basic Info
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Car Name & Model *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (UGX) *',
                border: OutlineInputBorder(),
                prefixText: 'UGX ',
              ),
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Brand/Category *',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Vehicle Specifications
            const Text(
              'Vehicle Specifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _yearCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Year (e.g. 2023)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _mileageCtrl,
              decoration: const InputDecoration(
                labelText: 'Mileage (e.g. 45,000 km)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedTransmission,
              decoration: const InputDecoration(
                labelText: 'Transmission',
                border: OutlineInputBorder(),
              ),
              items: _transmissions
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedTransmission = v),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedFuelType,
              decoration: const InputDecoration(
                labelText: 'Fuel Type',
                border: OutlineInputBorder(),
              ),
              items: _fuelTypes
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedFuelType = v),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedColor,
              decoration: const InputDecoration(
                labelText: 'Color',
                border: OutlineInputBorder(),
              ),
              items: _colors
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedColor = v),
            ),
            const SizedBox(height: 24),

            // Description
            TextFormField(
              controller: _descCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Description & Additional Specs',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                const Text(
                  'Available for Sale?',
                  style: TextStyle(fontSize: 16),
                ),
                const Spacer(),
                Switch(
                  value: _inStock,
                  activeColor: const Color(0xFF2E7D32),
                  onChanged: (v) => setState(() => _inStock = v),
                ),
              ],
            ),
            const SizedBox(height: 40),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _uploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: _uploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Add Car to Inventory',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
