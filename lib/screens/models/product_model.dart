// lib/models/product_model.dart

import 'package:intl/intl.dart';

class Product {
  final String id;
  final String name;
  final int price; // in UGX
  final String category; // e.g., "Toyota", "SUV", etc.
  final String image; // main display image (first in gallery)
  final List<String>? images; // all photos: exterior, interior, engine, etc.
  final double rating;

  // Car-specific fields
  String? year; // e.g., "2023"
  String? mileage; // e.g., "45,000 km"
  String? transmission; // "Automatic" or "Manual"
  String? fuelType; // "Petrol", "Diesel", "Hybrid"
  String? color; // "White", "Silver", etc.

  String? description;
  String? unit; // kept for compatibility
  int stock; // 999 = available, 0 = sold

  bool isInCart;
  bool isInWishlist;

  // Add NumberFormat as a static member so it's available everywhere
  static final NumberFormat _priceFormat = NumberFormat('#,##0', 'en_US');

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.image,
    this.images,
    this.rating = 4.8,
    this.year,
    this.mileage,
    this.transmission,
    this.fuelType,
    this.color,
    this.description,
    this.unit,
    this.stock = 999,
    this.isInCart = false,
    this.isInWishlist = false,
  });

  // For saving to SharedPreferences (cart/wishlist)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'category': category,
    'image': image,
    'images': images,
    'rating': rating,
    'year': year,
    'mileage': mileage,
    'transmission': transmission,
    'fuelType': fuelType,
    'color': color,
    'description': description,
    'unit': unit,
    'stock': stock,
    'isInCart': isInCart,
    'isInWishlist': isInWishlist,
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    // Safe parsing for images array
    List<String>? imagesList;
    if (json['images'] != null) {
      final imagesFromJson = json['images'];
      if (imagesFromJson is List) {
        imagesList = imagesFromJson
            .map((item) => item.toString())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Car',
      price: (json['price'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString() ?? 'Others',
      image: json['image']?.toString() ?? 'assets/products/placeholder.jpg',
      images: imagesList,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      year: json['year']?.toString(),
      mileage: json['mileage']?.toString(),
      transmission: json['transmission']?.toString(),
      fuelType: json['fuelType']?.toString(),
      color: json['color']?.toString(),
      description: json['description']?.toString(),
      unit: json['unit']?.toString(),
      stock: (json['stock'] as num?)?.toInt() ?? 999,
      isInCart: json['isInCart'] as bool? ?? false,
      isInWishlist: json['isInWishlist'] as bool? ?? false,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    int? price,
    String? category,
    String? image,
    List<String>? images,
    double? rating,
    String? year,
    String? mileage,
    String? transmission,
    String? fuelType,
    String? color,
    String? description,
    String? unit,
    int? stock,
    bool? isInCart,
    bool? isInWishlist,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      image: image ?? this.image,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      color: color ?? this.color,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      isInCart: isInCart ?? this.isInCart,
      isInWishlist: isInWishlist ?? this.isInWishlist,
    );
  }

  // Helper getters
  bool get isAvailable => stock > 0;

  String get formattedPrice => 'UGX ${_priceFormat.format(price)}';

  int get imageCount => images?.length ?? 1;

  String get mainImage => image;
}
