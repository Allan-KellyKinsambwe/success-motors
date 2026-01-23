// lib/screens/admin/add_rental_car.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class AddRentalCarScreen extends StatefulWidget {
  const AddRentalCarScreen({super.key});

  @override
  State<AddRentalCarScreen> createState() => _AddRentalCarScreenState();
}

class _AddRentalCarScreenState extends State<AddRentalCarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _rentalPriceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _mileageCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedTransmission;
  String? _selectedFuelType;
  String? _selectedColor;

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

  // Reduced photo sections — only 4 most important
  final List<Map<String, dynamic>> _photoSections = [
    {'label': 'Hero Shot (Front 3/4)', 'key': 'hero'},
    {'label': 'Side Profile', 'key': 'side'},
    {'label': 'Interior / Dashboard', 'key': 'interior'},
    {'label': 'Rear / Trunk', 'key': 'rear'},
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
      // Fallback
      setState(() {
        _categories = [
          'Sedan',
          'SUV',
          'Pickup',
          'Hatchback',
          'Luxury',
          'Other',
        ];
      });
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
              title: const Text('Take Photo'),
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
    if (picked != null && mounted) {
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
    if (selectedCount < 1) {
      // at least 1 photo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one main photo')),
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

      for (var entry in _sectionImages.entries) {
        final file = entry.value;
        if (file != null) {
          final ref = FirebaseStorage.instance
              .ref()
              .child('rental_cars')
              .child(
                '${DateTime.now().millisecondsSinceEpoch}_${entry.key}.jpg',
              );

          await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      if (imageUrls.isEmpty) throw Exception('No images uploaded');

      await FirebaseFirestore.instance.collection('rental_cars').add({
        'make': _makeCtrl.text.trim(),
        'model': _modelCtrl.text.trim(),
        'rentalPricePerDay': int.parse(_rentalPriceCtrl.text.trim()),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'image': imageUrls[0], // main image
        'images': imageUrls, // all uploaded images
        'year': _yearCtrl.text.trim().isEmpty ? null : _yearCtrl.text.trim(),
        'mileage': _mileageCtrl.text.trim().isEmpty
            ? null
            : _mileageCtrl.text.trim(),
        'transmission': _selectedTransmission,
        'fuelType': _selectedFuelType,
        'color': _selectedColor,
        'createdAt': FieldValue.serverTimestamp(),
        'addedBy': user.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental car added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error adding rental car: $e');
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
        title: const Text('Add Rental Car'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Main Photo (Required)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),

            // Main image picker (only one required)
            GestureDetector(
              onTap: () => _pickImageForSection(
                _photoSections[0]['key'],
                _photoSections[0]['label'],
              ),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                  color: Colors.grey[100],
                ),
                child: _sectionImages[_photoSections[0]['key']] == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_a_photo,
                            size: 60,
                            color: Color(0xFF2E7D32),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tap to add main photo',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _sectionImages[_photoSections[0]['key']]!,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Basic Info
            TextFormField(
              controller: _makeCtrl,
              decoration: const InputDecoration(
                labelText: 'Make / Brand *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _modelCtrl,
              decoration: const InputDecoration(
                labelText: 'Model *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _rentalPriceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Rental Price per Day (UGX) *',
                border: OutlineInputBorder(),
                prefixText: 'UGX ',
              ),
              validator: (v) {
                if (v!.trim().isEmpty) return 'Required';
                if (int.tryParse(v) == null) return 'Enter valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 24),

            // Vehicle Specs (borrowed from add_product)
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
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description & Features',
                border: OutlineInputBorder(),
              ),
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
                        'Add Rental Car',
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
