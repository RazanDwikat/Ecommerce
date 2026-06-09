import 'dart:convert';

import 'package:http/http.dart' as http;

class ProductItem {
  ProductItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? imageUrl;

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    final imagePath = (json['images'] is List && (json['images'] as List).isNotEmpty)
        ? (json['images'] as List).first?.toString()
        : null;

    return ProductItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Product',
      description: json['description']?.toString() ?? 'No description',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : 0.0,
      category: json['category'] is Map
          ? (json['category']['name']?.toString() ?? 'General')
          : json['category']?.toString() ?? 'General',
      imageUrl: imagePath == null
          ? null
          : (imagePath.startsWith('http') ? imagePath : '${ProductService.baseUrl}$imagePath'),
    );
  }
}

class ProductService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<List<ProductItem>> fetchProducts({String query = ''}) async {
    try {
      final uri = Uri.parse('$baseUrl/products').replace(queryParameters: {
        if (query.trim().isNotEmpty) 'search': query.trim(),
        'limit': '12',
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['products'] as List<dynamic>? ?? [];
        return items.map((item) => ProductItem.fromJson(item)).toList();
      }
    } catch (_) {
      // Fallback to local demo data if the backend is unavailable.
    }

    return _demoProducts;
  }

  static List<ProductItem> get _demoProducts => [
    ProductItem(
      id: 'demo-1',
      name: 'Classic Chair',
      description: 'Comfortable seat for your modern room.',
      price: 49.99,
      category: 'Furniture',
      imageUrl: 'https://images.unsplash.com/photo-1519947486511-46149fa0a254?auto=format&fit=crop&w=600&q=80',
    ),
    ProductItem(
      id: 'demo-2',
      name: 'Smart Lamp',
      description: 'Warm light with touch controls.',
      price: 29.50,
      category: 'Home Decor',
      imageUrl: 'https://images.unsplash.com/photo-1513506003901-1e6a229e2d15?auto=format&fit=crop&w=600&q=80',
    ),
    ProductItem(
      id: 'demo-3',
      name: 'Wireless Headphones',
      description: 'Immersive audio with long battery life.',
      price: 79.00,
      category: 'Electronics',
    ),
    ProductItem(
      id: 'demo-4',
      name: 'Running Shoes',
      description: 'Lightweight comfort for daily movement.',
      price: 59.99,
      category: 'Sports',
    ),
  ];
}
