// lib/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:success_motors/screens/models/product_model.dart';
import 'package:success_motors/screens/rentals_cars/rentals_car_hub_screen.dart';
import 'cart_screen.dart';
import 'wishlist_screen.dart';
import 'category_screen.dart';
import 'product_detail_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'garage_cars/garage_hub_screen.dart';
import 'loan_cars/loan_car_hub_screen.dart';

final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _cartCount = 0;
  int _wishlistCount = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  late List<Product> _filteredProducts;

  // Personalized greeting
  String _userFirstName = 'User';

  final NumberFormat _priceFormat = NumberFormat('#,##0', 'en_US');

  final List<Product> hardcodedProducts = [
    Product(
      id: '1',
      name: 'Toyota Corolla 2023',
      price: 95000000,
      category: 'Sedan',
      image: 'assets/products/toyota_corolla.jpeg',
      rating: 4.8,
      description:
          'Reliable and fuel-efficient sedan with modern features, perfect for daily commuting.',
    ),
    Product(
      id: '2',
      name: 'Honda CR-V 2024',
      price: 140000000,
      category: 'SUV',
      image: 'assets/products/honda_crv.jpeg',
      rating: 4.9,
      description:
          'Spacious family SUV with advanced safety features and excellent reliability.',
    ),
    Product(
      id: '3',
      name: 'Nissan Patrol 2022',
      price: 450000000,
      category: 'SUV',
      image: 'assets/products/nissan_patrol.jpg',
      rating: 4.7,
      description:
          'Powerful off-road capable luxury SUV with strong V8 engine.',
    ),
    Product(
      id: '4',
      name: 'Mazda CX-5 2023',
      price: 130000000,
      category: 'SUV',
      image: 'assets/products/mazda_cx5.jpg',
      rating: 4.8,
      description:
          'Stylish compact SUV with premium interior and engaging driving dynamics.',
    ),
    Product(
      id: '5',
      name: 'Toyota Hilux 2024',
      price: 160000000,
      category: 'Pickup',
      image: 'assets/products/toyota_hilux.jpg',
      rating: 4.9,
      description:
          'Legendary durable pickup truck ideal for tough jobs and off-road adventures.',
    ),
    Product(
      id: '6',
      name: 'Subaru Forester 2023',
      price: 135000000,
      category: 'SUV',
      image: 'assets/products/subaru_forester.jpeg',
      rating: 4.7,
      description:
          'All-wheel-drive SUV with excellent safety ratings and great visibility.',
    ),
    Product(
      id: '7',
      name: 'Hyundai Tucson 2024',
      price: 120000000,
      category: 'SUV',
      image: 'assets/products/hyundai_tucson.jpeg',
      rating: 4.8,
      description:
          'Modern crossover with bold design, advanced tech, and comfortable ride.',
    ),
    Product(
      id: '8',
      name: 'Mitsubishi Pajero 2022',
      price: 200000000,
      category: 'SUV',
      image: 'assets/products/mitsubishi_pajero.jpeg',
      rating: 4.6,
      description:
          'Robust 4x4 SUV built for extreme off-road conditions and long-distance travel.',
    ),
  ];

  List<Product> allProducts = [];
  List<String> categories = ['All'];

  final List<Map<String, dynamic>> _quickServices = [
    {
      'title': 'Garage',
      'icon': Icons.build_outlined,
      'screen': const GarageHubScreen(),
    },
    {
      'title': 'Rentals',
      'icon': Icons.directions_car_outlined,
      'screen': const RentalsCarHubScreen(),
    },
    {
      'title': 'Car Loan Plan',
      'icon': Icons.money_outlined,
      'screen': const LoanCarHubScreen(),
    },
  ];

  @override
  void initState() {
    super.initState();
    allProducts = List.from(hardcodedProducts);
    _filteredProducts = List.from(allProducts);

    _loadUserFirstName();
    _loadData();
    _loadFirestoreProducts();
    _loadCategories();

    _searchController.addListener(() {
      _searchQuery = _searchController.text;
      _filterProducts();
    });
  }

  Future<void> _loadUserFirstName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();
        final firstName = data?['firstName'] as String?;
        if (firstName != null && firstName.trim().isNotEmpty) {
          setState(() {
            _userFirstName = firstName.trim();
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user first name: $e');
      // keep fallback 'User'
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _cartCount = prefs.getInt('cart_count') ?? 0;
    _wishlistCount = prefs.getInt('wishlist_count') ?? 0;

    final cartList = prefs.getStringList('cart_items_list') ?? [];
    final wishList = prefs.getStringList('wishlist_items_list') ?? [];

    for (var p in allProducts) {
      p.isInCart = cartList.any((json) => json.contains('"id":"${p.id}"'));
      p.isInWishlist = wishList.any((json) => json.contains('"id":"${p.id}"'));
    }

    if (mounted) setState(() {});
  }

  Future<void> _loadFirestoreProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      final List<Product> firestoreProducts = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        firestoreProducts.add(Product.fromJson(data));
      }

      setState(() {
        allProducts.addAll(firestoreProducts);
        _filteredProducts = List.from(allProducts);
        _filterProducts();
      });
    } catch (e) {
      debugPrint('Error loading products from Firestore: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .get();

      final List<String> loadedCats = ['All'];

      for (var doc in snapshot.docs) {
        final name = doc.data()['name'] as String?;
        if (name != null && name.isNotEmpty) {
          loadedCats.add(name);
        }
      }

      setState(() {
        categories = loadedCats;
        if (!categories.contains(_selectedCategory)) {
          _selectedCategory = 'All';
        }
        _filterProducts();
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        categories = [
          'All',
          'Sedan',
          'SUV',
          'Pickup',
          'Hatchback',
          'Luxury',
          'Electric',
          'Commercial',
        ];
      });
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = allProducts.where((p) {
        final matchesSearch =
            _searchQuery.isEmpty ||
            p.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory =
            _selectedCategory == 'All' || p.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _addToCart(Product p) async {
    if (p.stock <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('This vehicle is sold')));
      return;
    }

    setState(() {
      p.isInCart = true;
      _cartCount++;
    });

    final prefs = await SharedPreferences.getInstance();
    List<String> cartList = prefs.getStringList('cart_items_list') ?? [];
    cartList.removeWhere((item) => item.contains('"id":"${p.id}"'));
    cartList.add(jsonEncode(p.toJson()));
    await prefs.setStringList('cart_items_list', cartList);
    await prefs.setInt('cart_count', _cartCount);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.name} added to inquiry cart!'),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );
    }
  }

  void _toggleWishlist(Product p) async {
    setState(() {
      p.isInWishlist = !p.isInWishlist;
      _wishlistCount += p.isInWishlist ? 1 : -1;
    });

    final prefs = await SharedPreferences.getInstance();
    List<String> wishList = prefs.getStringList('wishlist_items_list') ?? [];

    if (p.isInWishlist) {
      wishList.removeWhere((item) => item.contains('"id":"${p.id}"'));
      wishList.add(jsonEncode(p.toJson()));
    } else {
      wishList.removeWhere((item) => item.contains('"id":"${p.id}"'));
    }

    await prefs.setStringList('wishlist_items_list', wishList);
    await prefs.setInt('wishlist_count', _wishlistCount);
  }

  void _onBottomNavTap(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    final List<Widget> screens = [
      const HomeScreen(),
      const WishlistScreen(),
      const CategoryScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screens[index]),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        key: homeScreenKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            'Hi, $_userFirstName!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
            ),
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  ),
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: Colors.red,
                    child: Text(
                      '3',
                      style: TextStyle(fontSize: 8, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: () => _onBottomNavTap(1),
                  icon: const Icon(
                    Icons.favorite_border,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                if (_wishlistCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$_wishlistCount',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: () => _onBottomNavTap(3),
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                if (_cartCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$_cartCount',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: _buildHomeContent(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomNavTap,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Wishlist',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              activeIcon: Icon(Icons.category),
              label: 'Categories',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF2E7D32)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search cars...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: Color(0xFF2E7D32)),
                onPressed: () {},
              ),
            ],
          ),
        ),

        SizedBox(
          height: 50,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _quickServices.length,
            itemBuilder: (context, index) {
              final service = _quickServices[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => service['screen']),
                    );
                  },
                  child: Chip(
                    avatar: Icon(
                      service['icon'] as IconData,
                      size: 18,
                      color: const Color(0xFF2E7D32),
                    ),
                    label: Text(service['title'] as String),
                    backgroundColor: Colors.transparent,
                    labelStyle: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                    side: const BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, i) {
              final p = _filteredProducts[i];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(product: p),
                    ),
                  );
                },
                child: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: p.image.startsWith('http')
                                      ? Image.network(
                                          p.image,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              },
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.error),
                                        )
                                      : Image.asset(
                                          p.image,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                if (p.stock <= 0)
                                  Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.black54,
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Sold',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.5,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'UGX ${_priceFormat.format(p.price)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            Icons.star,
                                            size: 13,
                                            color: i < p.rating.floor()
                                                ? Colors.amber
                                                : Colors.grey[350],
                                          ),
                                        ),
                                      ),
                                      Text(
                                        ' ${p.rating}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: p.stock > 0
                                            ? () => _addToCart(p)
                                            : null,
                                        child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: p.stock > 0
                                              ? const Color(0xFF2E7D32)
                                              : Colors.grey,
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _toggleWishlist(p),
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: Icon(
                              p.isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: p.isInWishlist ? Colors.red : Colors.grey,
                            ),
                          ),
                        ),
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
