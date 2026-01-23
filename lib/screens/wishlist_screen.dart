// lib/screens/wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:success_motors/screens/cart_screen.dart';
import 'package:success_motors/screens/category_screen.dart';
import 'package:success_motors/screens/models/product_model.dart';
import 'package:success_motors/screens/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<Product> wishlistItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedList = prefs.getStringList('wishlist_items_list');

    if (savedList == null || savedList.isEmpty) {
      setState(() {
        wishlistItems = [];
        _isLoading = false;
      });
      return;
    }

    // First parse all items as they are saved
    List<Product> parsedItems = savedList
        .map((jsonStr) => Product.fromJson(jsonDecode(jsonStr)))
        .toList();

    // Now try to enrich products that probably came from Firestore
    List<Product> enrichedItems = [];
    for (var product in parsedItems) {
      // If it has no gallery images but looks like a Firestore product (id is not numeric/simple)
      if ((product.images == null || product.images!.isEmpty) &&
          product.id.length > 8) {
        // rough heuristic - real ids are usually longer
        try {
          final doc = await FirebaseFirestore.instance
              .collection('products')
              .doc(product.id)
              .get();

          if (doc.exists) {
            final data = doc.data()!;
            data['id'] = doc.id;

            // Create fresh product with full data (especially images)
            final freshProduct = Product.fromJson(data);

            // Keep wishlist-specific flags
            freshProduct.isInWishlist = true;

            enrichedItems.add(freshProduct);
            continue;
          }
        } catch (e) {
          debugPrint('Failed to enrich product ${product.id}: $e');
        }
      }

      // If we couldn't enrich or it's local product → keep as is
      enrichedItems.add(product);
    }

    if (mounted) {
      setState(() {
        wishlistItems = enrichedItems;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> list = wishlistItems
        .map((p) => jsonEncode(p.toJson()))
        .toList();
    await prefs.setStringList('wishlist_items_list', list);
    await prefs.setInt('wishlist_count', wishlistItems.length);
    homeScreenKey.currentState?.setState(() {});
  }

  Future<void> _remove(Product p) async {
    setState(() => wishlistItems.removeWhere((item) => item.id == p.id));
    await _saveWishlist();
  }

  void _navigateTo(int index) {
    final screens = [
      const HomeScreen(),
      const WishlistScreen(),
      const CategoryScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screens[index]),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Wishlist',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : wishlistItems.isEmpty
          ? const Center(
              child: Text(
                'Wishlist is empty',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: wishlistItems.length,
              itemBuilder: (_, i) {
                final p = wishlistItems[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: p.image.startsWith('http')
                          ? Image.network(
                              p.image,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            )
                          : Image.asset(
                              p.image,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            ),
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('UGX ${p.formattedPrice}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _remove(p),
                    ),
                    onTap: () {
                      // Optional: navigate to detail screen
                      // Navigator.push(...);
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: _navigateTo,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2E7D32),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Wishlist',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
