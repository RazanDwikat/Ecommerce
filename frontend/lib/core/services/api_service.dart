import 'dart:convert';
import 'package:http/http.dart' as http;

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
}
