// lib/constants/category_logos.dart

/// Centralized mapping of category / brand names → logo asset paths
///
/// All paths point to files inside: assets/logos/
/// File names should be lowercase with underscores
/// Add new entries here when you add more logos to the project.

class CategoryLogos {
  static const Map<String, String> _logoMap = {
    // Brands (must match exactly what appears in Firestore categories / product.category)
    'Audi': 'assets/car_logos/audi-logo.png',
    'Alfa Romeo': 'assets/car_logos/alfa-romeo-logo.png',
    'Acura': 'assets/car_logos/acura-logo.png',
    'Aston Martin': 'assets/car_logos/aston-martin-logo.png',
    'BMW': 'assets/car_logos/bmw-logo.png',
    'Bentley': 'assets/car_logos/bentley-logo.png',
    'Bugatti': 'assets/car_logos/bugatti-logo.png',
    'Buick': 'assets/car_logos/buick-logo.png',
    'Benz':
        'assets/car_logos/mercedes-benz-logo.png', // or mercedes.png — choose one
    //NEW
    'Cadillac': 'assets/car_logos/cadillac-logo.png',
    'Chevrolet': 'assets/car_logos/chevrolet-logo.png',
    'Chrysler': 'assets/car_logos/chrysler-logo.png',
    'Corvette': 'assets/car_logos/corvette-logo.png',

    'Dodge Viper': 'assets/car_logos/dodge-viper-logo.png',

    'Ferrari': 'assets/car_logos/ferrari-logo.png',
    'Ford': 'assets/car_logos/ford.png',

    'Genesis': 'assets/car_logos/genesis-logo.png',

    'Honda': 'assets/car_logos/honda-logo.png',
    'Hatch Back': 'assets/car_logos/hatchback.jpeg',
    'Hyundai': 'assets/car_logos/hyundai-logo.png',

    'Jaguar': 'assets/car_logos/jaguar-logo.png',
    'Jeep': 'assets/car_logos/jeep-logo.png',
    'Kia': 'assets/car_logos/kia-logo.png',
    'Isuzu': 'assets/car_logos/isuzu-logo.png',
    'Lexus': 'assets/car_logos/lexus-logo.png',
    'Lotus': 'assets/car_logos/lotus-logo.png',
    'Lamborghini': 'assets/car_logos/lamborghini-logo.png',
    'Mitsubishi': 'assets/car_logos/mitsubishi-logo.png',
    'Maserati': 'assets/car_logos/maserati-logo.png',
    'Mazda': 'assets/car_logos/mazda-logo.png',
    'Mercedes': 'assets/car_logos/mercedes-benz-logo.png',
    'Mini': 'assets/car_logos/mini-logo.png',
    'Nissan': 'assets/car_logos/nissan-logo.png',
    'Porsche': 'assets/car_logos/porsche-logo.png',
    'Rolls Royce': 'assets/car_logos/rolls-royce-logo.png',
    'Subaru': 'assets/car_logos/subaru-logo.png',
    'Suzuki': 'assets/car_logos/suzuki-logo.png',
    'Saleen': 'assets/car_logos/saleen-logo.png',
    'Toyota': 'assets/car_logos/toyota.png',
    'Volvo': 'assets/car_logos/volvo-logo.png',
    'Volkswagen': 'assets/car_logos/volkswagen-logo.png',
    'Tesla': 'assets/car_logos/tesla-logo.png',
    'Tata': 'assets/car_logos/tata-logo.png',

    // Body types & special categories
    'Sedan': 'assets/car_logos/saleen.png',
    'SUV': 'assets/car_logos/suv-logo.png',
    'Pickup': 'assets/car_logos/pickup.png',
    'Hatchback': 'assets/car_logos/hatchback.jpeg',
    'Luxury': 'assets/car_logos/luxury.png',
    'Electric': 'assets/car_logos/electric.jpeg',
    'Commercial': 'assets/logos/commercial.jpg',

    //LOGOS TO CORRECT SUV,PICKUP,luxury,electric,commercial

    // Additional / premium models
    'Range Rover': 'assets/car_logos/range_rover.png',
    // 'Land Rover': 'assets/logos/land_rover.png',   // if you ever use this spelling
  };

  /// Returns asset path or null if no logo is defined for this name
  static String? getPath(String categoryName) {
    return _logoMap[categoryName];
  }

  /// Returns true if a logo path exists for this category/brand
  static bool hasLogo(String categoryName) {
    final path = getPath(categoryName);
    return path != null && path.isNotEmpty;
  }

  /// All category/brand names that currently have a logo defined
  static List<String> get supportedCategories => _logoMap.keys.toList();
}
