import '../../domain/entities/paginated_products.dart';
import 'product_model.dart';

class PaginatedProductsModel extends PaginatedProducts {
  const PaginatedProductsModel({
    required super.products,
    required super.total,
    required super.page,
    required super.totalPages,
  });

  factory PaginatedProductsModel.fromJson(Map<String, dynamic> json) {
    return PaginatedProductsModel(
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
    );
  }
}
