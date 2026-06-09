import 'dart:convert';

import 'package:http/http.dart' as http;

class CategoryItem {
  CategoryItem({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'General',
      description: json['description']?.toString() ?? 'Browse products in this category.',
    );
  }
}

class CategoryService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<List<CategoryItem>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['categories'] as List<dynamic>? ?? [];
        return items.map((item) => CategoryItem.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Fallback to demo categories when the backend is unavailable.
    }

    return _demoCategories;
  }

  static List<CategoryItem> get _demoCategories => [
    CategoryItem(id: 'demo-1', name: 'Furniture', description: 'Comfortable seating and home essentials.'),
    CategoryItem(id: 'demo-2', name: 'Home Decor', description: 'Decor pieces to brighten your space.'),
    CategoryItem(id: 'demo-3', name: 'Electronics', description: 'Modern gadgets and smart devices.'),
    CategoryItem(id: 'demo-4', name: 'Sports', description: 'Quality gear for active lifestyles.'),
  ];
}
