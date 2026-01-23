// lib/screens/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:success_motors/screens/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'home_screen.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _showAllPhotos = false;

  final NumberFormat _priceFormat = NumberFormat('#,##0', 'en_US');

  final List<String> _photoLabels = [
    'Front 3/4 Angle (Hero Shot)',
    'Rear 3/4 Angle',
    'Side Profile (Driver Side)',
    'Side Profile (Passenger Side)',
    'Front Straight',
    'Rear Straight',
    'Dashboard & Steering',
    'Rear Seats',
    'Trunk/Boot (Open)',
    'Engine Bay (Hood Open)',
    'Odometer Reading',
    'Wheels/Tires Close-up',
  ];

  List<String> get _images {
    if (widget.product.images != null && widget.product.images!.isNotEmpty) {
      return widget.product.images!;
    }
    return [widget.product.image];
  }

  String _getLabel(int index) {
    if (index < _photoLabels.length) {
      return _photoLabels[index];
    }
    return 'Additional View ${index + 1 - _photoLabels.length}';
  }

  Future<void> _addToCart() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cartList = prefs.getStringList('cart_items_list') ?? [];

    cartList.removeWhere(
      (item) => item.contains('"id":"${widget.product.id}"'),
    );
    cartList.add(jsonEncode(widget.product.toJson()));

    await prefs.setStringList('cart_items_list', cartList);
    await prefs.setInt(
      'cart_count',
      (prefs.getInt('cart_count') ?? 0) + quantity,
    );

    homeScreenKey.currentState?.setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} added to inquiry!'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveOrderToFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'product_id': widget.product.id,
        'product_name': widget.product.name,
        'price': widget.product.price,
        'quantity': quantity,
        'total': widget.product.price * quantity,
        'image': widget.product.image,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'payment_method': 'selected_in_checkout',
        'user_id': 'guest_user',
      });
    } catch (e) {
      debugPrint('Error saving order: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper to display spec if available
  Widget _specRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final imageCount = _images.length;
    final hasMultipleImages = imageCount > 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              p.isInWishlist ? Icons.favorite : Icons.favorite_border,
              color: p.isInWishlist ? Colors.red : const Color(0xFF2E7D32),
              size: 28,
            ),
            onPressed: () async {
              setState(() => p.isInWishlist = !p.isInWishlist);

              final prefs = await SharedPreferences.getInstance();
              List<String> list =
                  prefs.getStringList('wishlist_items_list') ?? [];

              if (p.isInWishlist) {
                list.removeWhere((i) => i.contains('"id":"${p.id}"'));
                list.add(jsonEncode(p.toJson()));
              } else {
                list.removeWhere((i) => i.contains('"id":"${p.id}"'));
              }

              await prefs.setStringList('wishlist_items_list', list);
              await prefs.setInt('wishlist_count', list.length);
              homeScreenKey.currentState?.setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFF2E7D32),
              size: 28,
            ),
            onPressed: _addToCart,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Carousel
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SizedBox(
                          height: 340,
                          width: double.infinity,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) =>
                                setState(() => _currentImageIndex = index),
                            itemCount: imageCount,
                            itemBuilder: (context, index) {
                              final img = _images[index];
                              return img.startsWith('http')
                                  ? Image.network(
                                      img,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Color(0xFF2E7D32),
                                                    ),
                                              ),
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                Icons.error,
                                                size: 60,
                                                color: Colors.red,
                                              ),
                                            );
                                          },
                                    )
                                  : Image.asset(img, fit: BoxFit.cover);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getLabel(_currentImageIndex),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (hasMultipleImages)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              imageCount,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                width: _currentImageIndex == i ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == i
                                      ? const Color(0xFF2E7D32)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // View All Photos Button
                  if (hasMultipleImages)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _showAllPhotos = !_showAllPhotos),
                          icon: Icon(
                            _showAllPhotos
                                ? Icons.keyboard_arrow_up
                                : Icons.photo_library,
                          ),
                          label: Text(
                            _showAllPhotos
                                ? 'Hide Photos'
                                : 'View All Photos ($imageCount)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2E7D32),
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Full Photo Grid (collapsed by default)
                  if (_showAllPhotos && hasMultipleImages)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: imageCount,
                        itemBuilder: (context, index) {
                          final img = _images[index];
                          final label = _getLabel(index);
                          final isSelected = index == _currentImageIndex;

                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2E7D32)
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: img.startsWith('http')
                                        ? Image.network(img, fit: BoxFit.cover)
                                        : Image.asset(img, fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.7),
                                          Colors.transparent,
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(14),
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'UGX ${_priceFormat.format(p.price)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (i) => Icon(
                          i < p.rating.floor() ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${p.rating}', style: const TextStyle(fontSize: 18)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          p.category,
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // NEW: Vehicle Specifications Section
                  const Text(
                    'Vehicle Specifications',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const Divider(height: 24, thickness: 1),
                  _specRow('Year', p.year),
                  _specRow('Mileage', p.mileage),
                  _specRow('Transmission', p.transmission),
                  _specRow('Fuel Type', p.fuelType),
                  _specRow('Color', p.color),
                  const SizedBox(height: 32),

                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.description?.isNotEmpty == true
                        ? p.description!
                        : 'Well-maintained vehicle in excellent condition. Full service history available. Ready for test drive and immediate delivery.',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),

          // Bottom Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _addToCart();
                    await _saveOrderToFirestore();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    );
                  },
                  icon: const Icon(Icons.message_outlined, color: Colors.white),
                  label: const Text(
                    'Inquire Now',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
