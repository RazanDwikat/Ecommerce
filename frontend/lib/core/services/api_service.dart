import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  final String baseUrl = 'http://localhost:3000';

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> addToCart(String token, String productId, int quantity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'productId': productId,
        'quantity': quantity,
      }),
    );

    return _handleResponse(response, 'Failed to add product to cart');
  }

  Future<Map<String, dynamic>> getCart(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/cart'),
      headers: _authHeaders(token),
    );

    return _handleResponse(response, 'Failed to fetch cart');
  }

  Future<Map<String, dynamic>> updateQuantity(String token, String productId, int quantity) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/cart/$productId'),
      headers: _authHeaders(token),
      body: jsonEncode({'quantity': quantity}),
    );

    return _handleResponse(response, 'Failed to update quantity');
  }

  Future<Map<String, dynamic>> removeFromCart(String token, String productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/$productId'),
      headers: _authHeaders(token),
    );

    return _handleResponse(response, 'Failed to remove item');
  }

  Future<Map<String, dynamic>> clearCart(String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart'),
      headers: _authHeaders(token),
    );

    return _handleResponse(response, 'Failed to clear cart');
  }

  

Future<Map<String, dynamic>> createOrder(String token) async {
  final response = await http.post(
    Uri.parse('$baseUrl/orders'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  final data = jsonDecode(response.body);
  if (response.statusCode != 201) {
    throw Exception(data['message'] ?? 'Failed to create order');
  }
  return data;
}

Future<Map<String, dynamic>> createPayment(
  String token,
  String orderId,
  String method,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/payments'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'orderId': orderId, 'method': method}),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode != 201) {
    throw Exception(data['message'] ?? 'Failed to create payment');
  }
  return data;
}

Future<Map<String, dynamic>> simulatePayment(
  String token,
  String paymentIntentId, {
  String paymentMethod = 'pm_card_visa',
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/payments/simulate'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'paymentIntentId': paymentIntentId,
      'paymentMethod': paymentMethod,
    }),
  );
  final data = jsonDecode(response.body);
  if (response.statusCode != 200) {
    throw Exception(data['message'] ?? 'Simulation failed');
  }
  return data;
}

Future<Map<String, dynamic>> getMyOrders(String token) async {
  final response = await http.get(
    Uri.parse('$baseUrl/orders/my-orders'),
    headers: _authHeaders(token),
  );
  return _handleResponse(response, 'Failed to fetch orders');
}

Future<Map<String, dynamic>> getOrderById(String token, String orderId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/orders/$orderId'),
    headers: _authHeaders(token),
  );
  return _handleResponse(response, 'Failed to fetch order');
}


  Map<String, dynamic> _handleResponse(http.Response response, String fallbackMessage) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message'] ?? fallbackMessage);
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> getProductReviews(String productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reviews/products/$productId'),
    );
    return _handleResponse(response, 'Failed to fetch reviews');
  }

  Future<Map<String, dynamic>> createReview(String token, String productId, int rating, String comment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reviews/products/$productId'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    );
    return _handleResponse(response, 'Failed to create review');
  }

  Future<Map<String, dynamic>> updateReview(String token, String reviewId, int? rating, String? comment) async {
    final body = <String, dynamic>{};
    if (rating != null) body['rating'] = rating;
    if (comment != null) body['comment'] = comment;

    final response = await http.patch(
      Uri.parse('$baseUrl/reviews/$reviewId'),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
    return _handleResponse(response, 'Failed to update review');
  }

  Future<Map<String, dynamic>> deleteReview(String token, String reviewId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/reviews/$reviewId'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response, 'Failed to delete review');
  }

  Future<bool> hasUserPurchasedProduct(String token, String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/orders/my-orders'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final orders = body['orders'] as List<dynamic>? ?? [];

        for (var order in orders) {
          final items = order['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            final itemProductId = item['product']?['_id']?.toString() ?? item['productId']?.toString();
            if (itemProductId == productId) {
              return true;
            }
          }
        }
      }
    } catch (_) {
      return false;
    }

    return false;
  }

  // ── Admin: Categories ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createCategory(String token, String name, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );
    return _handleResponse(response, 'Failed to create category');
  }

  Future<Map<String, dynamic>> getAllCategoriesAdmin(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response, 'Failed to fetch categories');
  }

  Future<Map<String, dynamic>> getCategoryByIdAdmin(String token, String categoryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories/$categoryId'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response, 'Failed to fetch category');
  }

  Future<Map<String, dynamic>> updateCategory(String token, String categoryId, String? name, String? description) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;

    final response = await http.patch(
      Uri.parse('$baseUrl/categories/$categoryId'),
      headers: _authHeaders(token),
      body: jsonEncode(body),
    );
    return _handleResponse(response, 'Failed to update category');
  }

  Future<Map<String, dynamic>> deleteCategory(String token, String categoryId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$categoryId'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response, 'Failed to delete category');
  }

  Future<Map<String, dynamic>> restoreCategory(String token, String categoryId) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/categories/restore/$categoryId'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response, 'Failed to restore category');
  }

  // ── Admin: Products ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createProduct(String token, Map<String, dynamic> productData, List<String> imagePaths, List<Uint8List> imageBytes) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/products'));
    request.headers.addAll(_authHeaders(token));
    
    request.fields['name'] = productData['name'];
    request.fields['description'] = productData['description'];
    request.fields['price'] = productData['price'].toString();
    request.fields['category'] = productData['category'];
    request.fields['stock'] = productData['stock'].toString();
    
    for (final imagePath in imagePaths) {
      final file = await http.MultipartFile.fromPath('images', imagePath);
      request.files.add(file);
    }
    
    for (int i = 0; i < imageBytes.length; i++) {
      final file = http.MultipartFile.fromBytes(
        'images',
        imageBytes[i],
        filename: 'image_$i.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(file);
    }
    
    final response = await http.Response.fromStream(await request.send());
    return _handleResponse(response, 'Failed to create product');
  }

  Future<Map<String, dynamic>> getAllProductsAdmin(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response, 'Failed to fetch products');
  }

  Future<Map<String, dynamic>> getProductByIdAdmin(String token, String productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$productId'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response, 'Failed to fetch product');
  }

  Future<Map<String, dynamic>> updateProduct(String token, String productId, Map<String, dynamic> productData, List<String> imagePaths, List<Uint8List> imageBytes) async {
    if (imagePaths.isEmpty && imageBytes.isEmpty) {
      final response = await http.patch(
        Uri.parse('$baseUrl/products/$productId'),
        headers: _authHeaders(token),
        body: jsonEncode(productData),
      );
      return _handleResponse(response, 'Failed to update product');
    }

    final request = http.MultipartRequest('PATCH', Uri.parse('$baseUrl/products/$productId'));
    request.headers.addAll(_authHeaders(token));
    
    request.fields['name'] = productData['name'];
    request.fields['description'] = productData['description'];
    request.fields['price'] = productData['price'].toString();
    request.fields['category'] = productData['category'];
    request.fields['stock'] = productData['stock'].toString();
    
    for (final imagePath in imagePaths) {
      final file = await http.MultipartFile.fromPath('images', imagePath);
      request.files.add(file);
    }
    
    for (int i = 0; i < imageBytes.length; i++) {
      final file = http.MultipartFile.fromBytes(
        'images',
        imageBytes[i],
        filename: 'image_$i.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(file);
    }
    
    final response = await http.Response.fromStream(await request.send());
    return _handleResponse(response, 'Failed to update product');
  }

  Future<Map<String, dynamic>> deleteProduct(String token, String productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$productId'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response, 'Failed to delete product');
  }

  // ── Admin: Orders ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAllOrdersAdmin(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/admin/orders'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response, 'Failed to fetch orders');
  }

  Future<Map<String, dynamic>> updateOrderStatus(String token, String orderId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/admin/orders/$orderId/status'),
      headers: _authHeaders(token),
      body: jsonEncode({'status': status}),
    );
    return _handleResponse(response, 'Failed to update order status');
  }

  // ── Admin: Reviews ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> deleteReviewAdmin(String token, String reviewId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/reviews/$reviewId'),
      headers: _authHeaders(token),
    );
    return _handleResponse(response, 'Failed to delete review');
  }
}
