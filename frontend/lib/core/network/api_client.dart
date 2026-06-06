import 'package:dio/dio.dart';

import 'api_endpoints.dart';

/// Thin wrapper around [Dio] configured for the e-commerce backend.
class ApiClient {
  final Dio dio;

  ApiClient([Dio? dio])
      : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.get(path, queryParameters: queryParameters);
  }
}
