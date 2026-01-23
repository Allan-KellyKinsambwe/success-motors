// lib/screens/category_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:success_motors/constants/category_logos.dart';
import 'package:success_motors/screens/models/product_model.dart';

import 'cart_screen.dart';
import 'home_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String selectedCategory = 'All';
  List<Map<String, dynamic>> categories = [];
  List<Product> allProducts = [];

  bool _isLoadingCategories = true;
  bool _isLoadingProducts = true;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadProducts();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .get()
          .timeout(const Duration(seconds: 10));

      final List<Map<String, dynamic>> loadedCats = [];

      // 'All' is always first
      loadedCats.add({
        'title': 'All',
        'icon': Icons.apps,
        'color': const Color(0xFF2E7D32),
      });

      // Fallback icons & colors when no logo exists
      final Map<String, Map<String, dynamic>> fallbackIcons = {
        'Sedan': {'icon': Icons.directions_car, 'color': Colors.blue[700]},
        'SUV': {'icon': Icons.directions_car_filled, 'color': Colors.teal[700]},
        'Pickup': {'icon': Icons.local_shipping, 'color': Colors.brown[700]},
        'Hatchback': {
          'icon': Icons.directions_car,
          'color': Colors.indigo[600],
        },
        'Luxury': {'icon': Icons.star, 'color': Colors.amber[800]},
        'Electric': {
          'icon': Icons.electric_bolt,
          'color': Colors.lightGreen[700],
        },
        'Commercial': {
          'icon': Icons.business_center,
          'color': Colors.grey[800],
        },
      };

      final Set<String> seen = {'All'};

      for (var doc in snapshot.docs) {
        final name = doc.data()['name'] as String?;
        if (name != null && name.isNotEmpty && !seen.contains(name)) {
          seen.add(name);
          final fallback =
              fallbackIcons[name] ??
              {
                'icon': Icons.category,
                'color': const Color(0xFF2E7D32).withOpacity(0.7),
              };
          loadedCats.add({
            'title': name,
            'icon': fallback['icon'],
            'color': fallback['color'],
          });
        }
      }

      if (mounted) {
        setState(() {
          categories = loadedCats;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Categories load error: $e');
      setState(() {
        _isLoadingCategories = false;
        _categoryError = 'Could not load categories • Using defaults';
        categories = [
          {
            'title': 'All',
            'icon': Icons.apps,
            'color': const Color(0xFF2E7D32),
          },
          {
            'title': 'Sedan',
            'icon': Icons.directions_car,
            'color': Colors.blue[700],
          },
          {
            'title': 'SUV',
            'icon': Icons.directions_car_filled,
            'color': Colors.teal[700],
          },
          {
            'title': 'Pickup',
            'icon': Icons.local_shipping,
            'color': Colors.brown[700],
          },
          {'title': 'Luxury', 'icon': Icons.star, 'color': Colors.amber[800]},
          {
            'title': 'Electric',
            'icon': Icons.electric_bolt,
            'color': Colors.lightGreen[700],
          },
        ];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load categories • Showing defaults'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);

    try {
      // Hardcoded fallback / demo products
      final List<Product> hardcodedCars = [
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

      // Load real products from Firestore
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

      if (mounted) {
        setState(() {
          allProducts = [...hardcodedCars, ...firestoreProducts];
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Products load error: $e');
      setState(() {
        allProducts = [];
        _isLoadingProducts = false;
      });
    }
  }

  List<Product> get filteredProducts {
    if (selectedCategory == 'All') return allProducts;
    return allProducts.where((p) => p.category == selectedCategory).toList();
  }

  void _navigateTo(int index) {
    final screens = [
      const HomeScreen(),
      const WishlistScreen(),
      const CategoryScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
    if (index == 2) return; // already here
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
          'Categories',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Horizontal scrollable category chips with logos
          SizedBox(
            height: 110,
            child: _isLoadingCategories
                ? const Center(child: CircularProgressIndicator())
                : _categoryError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _categoryError!,
                        style: const TextStyle(color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      final title = cat['title'] as String;
                      final isSelected = selectedCategory == title;
                      final color = cat['color'] as Color;
                      final hasLogo = CategoryLogos.hasLogo(title);
                      final logoPath = CategoryLogos.getPath(title);

                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: GestureDetector(
                          onTap: () => setState(() => selectedCategory = title),
                          child: SizedBox(
                            width: 80,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: isSelected
                                      ? color
                                      : color.withOpacity(0.2),
                                  child: hasLogo && logoPath != null
                                      ? Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: Image.asset(
                                            logoPath,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                                      cat['icon'] as IconData,
                                                      size: 32,
                                                      color: isSelected
                                                          ? Colors.white
                                                          : color,
                                                    ),
                                          ),
                                        )
                                      : Icon(
                                          cat['icon'] as IconData,
                                          size: 32,
                                          color: isSelected
                                              ? Colors.white
                                              : color,
                                        ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? color
                                        : Colors.grey[700],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Products grid
          Expanded(
            child: _isLoadingProducts
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No vehicles found in $selectedCategory',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (_, i) {
                      final p = filteredProducts[i];
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
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
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
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    );
                                                  },
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(Icons.error),
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
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'UGX ${p.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          Row(
                                            children: List.generate(
                                              5,
                                              (i) => Icon(
                                                Icons.star,
                                                size: 14,
                                                color: i < p.rating.floor()
                                                    ? Colors.amber
                                                    : Colors.grey[350],
                                              ),
                                            ),
                                          ),
                                          Text(
                                            ' ${p.rating}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          const Spacer(),
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: p.stock > 0
                                                ? () {
                                                    // TODO: add to cart / inquiry logic if needed
                                                  }
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
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: _navigateTo,
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
            icon: Icon(Icons.category),
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
    );
  }
}
