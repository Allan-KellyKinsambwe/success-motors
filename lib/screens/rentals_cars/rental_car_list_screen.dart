// lib/screens/rental_cars/rental_car_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'rental_booking_screen.dart';
import 'package:success_motors/constants/constants.dart';

class RentalCarListScreen extends StatefulWidget {
  const RentalCarListScreen({super.key});

  @override
  State<RentalCarListScreen> createState() => _RentalCarListScreenState();
}

class _RentalCarListScreenState extends State<RentalCarListScreen> {
  List<Map<String, dynamic>> _rentalCars = [];
  bool _isLoading = true;

  // Hardcoded fallback cars (same as before)
  final List<Map<String, dynamic>> _hardcodedRentalCars = [
    {
      'make': 'Toyota',
      'model': 'Corolla 2023',
      'image': 'assets/products/toyota_corolla.jpeg',
      'rentalPricePerDay': 250000,
      'category': 'Sedan',
    },
    {
      'make': 'Honda',
      'model': 'CR-V 2024',
      'image': 'assets/products/honda_crv.jpeg',
      'rentalPricePerDay': 380000,
      'category': 'SUV',
    },
    {
      'make': 'Nissan',
      'model': 'Patrol 2022',
      'image': 'assets/products/nissan_patrol.jpg',
      'rentalPricePerDay': 600000,
      'category': 'SUV',
    },
    {
      'make': 'Mazda',
      'model': 'CX-5 2023',
      'image': 'assets/products/mazda_cx5.jpg',
      'rentalPricePerDay': 350000,
      'category': 'SUV',
    },
    {
      'make': 'Toyota',
      'model': 'Hilux 2024',
      'image': 'assets/products/toyota_hilux.jpg',
      'rentalPricePerDay': 450000,
      'category': 'Pickup',
    },
    {
      'make': 'Subaru',
      'model': 'Forester 2023',
      'image': 'assets/products/subaru_forester.jpeg',
      'rentalPricePerDay': 400000,
      'category': 'SUV',
    },
    {
      'make': 'Hyundai',
      'model': 'Tucson 2024',
      'image': 'assets/products/hyundai_tucson.jpeg',
      'rentalPricePerDay': 360000,
      'category': 'SUV',
    },
    {
      'make': 'Mitsubishi',
      'model': 'Pajero 2022',
      'image': 'assets/products/mitsubishi_pajero.jpeg',
      'rentalPricePerDay': 500000,
      'category': 'SUV',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRentalCars();
  }

  Future<void> _loadRentalCars() async {
    setState(() => _isLoading = true);

    try {
      // Start with hardcoded fallback
      _rentalCars = List.from(_hardcodedRentalCars);

      // Fetch ONLY from rental_cars collection
      final snapshot = await FirebaseFirestore.instance
          .collection('rental_cars')
          .orderBy('rentalPricePerDay')
          .get();

      if (snapshot.docs.isEmpty) {
        print('No documents found in rental_cars collection');
      } else {
        print('Found ${snapshot.docs.length} rental cars in Firestore');
      }

      final firestoreCars = snapshot.docs.map((doc) {
        final data = doc.data();
        print('Rental car ${doc.id}: ${data['make']} ${data['model']}');

        return {
          'id': doc.id,
          'make': data['make'] ?? 'Unknown',
          'model': data['model'] ?? '',
          'image': data['image'] ?? 'assets/images/default_car.png',
          'rentalPricePerDay':
              (data['rentalPricePerDay'] as num?)?.toInt() ?? 300000,
          'category': data['category'] ?? 'Other',
        };
      }).toList();

      // Combine + remove duplicates by make-model
      final combined = [..._rentalCars, ...firestoreCars];
      final uniqueMap = <String, Map<String, dynamic>>{};

      for (var car in combined) {
        final key = '${car['make']}-${car['model']}';
        if (!uniqueMap.containsKey(key)) {
          uniqueMap[key] = car;
        }
      }

      setState(() {
        _rentalCars = uniqueMap.values.toList();
        _isLoading = false;
      });
    } catch (e, stack) {
      print('Error loading rental cars from Firestore: $e');
      print('Stack: $stack');

      setState(() {
        _rentalCars = List.from(_hardcodedRentalCars);
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load rental fleet. Showing demo cars.'),
            action: SnackBarAction(label: 'Retry', onPressed: _loadRentalCars),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Choose a Rental Car'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _rentalCars.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_car_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No rental cars available right now',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: AppStyles.orangeButtonStyle,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _rentalCars.length,
              itemBuilder: (context, index) {
                final car = _rentalCars[index];
                final carName = '${car['make']} ${car['model']}';
                final pricePerDay = car['rentalPricePerDay'] as int;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RentalBookingScreen(car: car),
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
                            // Image
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: car['image'].startsWith('http')
                                      ? Image.network(
                                          car['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _placeholderImage(),
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
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                );
                                              },
                                        )
                                      : Image.asset(
                                          car['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _placeholderImage(),
                                        ),
                                ),
                              ),
                            ),
                            // Details
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
                                      carName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'UGX ${NumberFormat('#,##0').format(pricePerDay)} / day',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2E7D32),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          car['category'] ?? 'Other',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  '$carName added to inquiry!',
                                                ),
                                                backgroundColor: const Color(
                                                  0xFF2E7D32,
                                                ),
                                              ),
                                            );
                                          },
                                          child: CircleAvatar(
                                            radius: 14,
                                            backgroundColor: const Color(
                                              0xFF2E7D32,
                                            ),
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

                        // Favorite / wishlist button (optional for rentals)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              List<String> wishlist =
                                  prefs.getStringList('wishlist_rental') ?? [];

                              final carJson = jsonEncode(car);

                              if (wishlist.contains(carJson)) {
                                wishlist.remove(carJson);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$carName removed from wishlist',
                                    ),
                                    backgroundColor: Colors.grey,
                                  ),
                                );
                              } else {
                                wishlist.add(carJson);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$carName added to wishlist'),
                                    backgroundColor: const Color(0xFF2E7D32),
                                  ),
                                );
                              }

                              await prefs.setStringList(
                                'wishlist_rental',
                                wishlist,
                              );
                              setState(() {});
                            },
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.white.withOpacity(0.9),
                              child: const Icon(
                                Icons.favorite_border,
                                size: 18,
                                color: Colors.grey,
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
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.directions_car, size: 60, color: Colors.grey),
    );
  }
}
