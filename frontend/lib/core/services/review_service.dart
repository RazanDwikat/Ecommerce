import 'dart:convert';
import 'package:http/http.dart' as http;

class Review {
  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.userId,
    required this.userName,
    required this.productId,
    this.createdAt,
  });

  final String id;
  final int rating;
  final String comment;
  final String userId;
  final String userName;
  final String productId;
  final DateTime? createdAt;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      rating: json['rating'] is int ? json['rating'] as int : (json['rating'] as num).toInt(),
      comment: json['comment']?.toString() ?? '',
      userId: json['user']?['_id']?.toString() ?? json['userId']?.toString() ?? '',
      userName: json['user']?['name']?.toString() ?? json['userName']?.toString() ?? 'Anonymous',
      productId: json['product']?['_id']?.toString() ?? json['productId']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
    );
  }
}

class ReviewService {
  static const String baseUrl = 'http://localhost:3000';

  static Future<List<Review>> getProductReviews(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/products/$productId'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final items = body['reviews'] as List<dynamic>? ?? [];
        return items.map((item) => Review.fromJson(item)).toList();
      }
    } catch (_) {
      // Fallback to empty list if backend is unavailable
    }

    return [];
  }
}
