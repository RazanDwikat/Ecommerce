import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/product_filter.dart';
import '../models/category_model.dart';
import '../models/paginated_products_model.dart';

abstract class ProductRemoteDataSource {
  Future<PaginatedProductsModel> getProducts(ProductFilter filter);
  Future<List<CategoryModel>> getCategories();
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient client;

  ProductRemoteDataSourceImpl(this.client);

  @override
  Future<PaginatedProductsModel> getProducts(ProductFilter filter) async {
    try {
      // The filter entity knows how to express itself as query params,
      // which map 1:1 to what `GET /products` expects.
      final response = await client.get(
        ApiEndpoints.products,
        queryParameters: filter.toQueryParameters(),
      );
      return PaginatedProductsModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ServerException(_messageFromDio(e));
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await client.get(ApiEndpoints.categories);
      final data = response.data;
      // Backend may return a bare list or { categories: [...] }.
      final list = data is List
          ? data
          : (data is Map<String, dynamic>
              ? (data['categories'] ?? data['data'] ?? const [])
              : const []);
      return (list as List<dynamic>)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(_messageFromDio(e));
    }
  }

  String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? 'Unexpected server error';
  }
}
