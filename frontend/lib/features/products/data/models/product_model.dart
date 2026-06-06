import '../../domain/entities/product.dart';
import 'category_model.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.stock,
    required super.images,
    required super.category,
    required super.averageRating,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // `category` may be populated (object) or just an id (string).
    CategoryModel? category;
    final rawCategory = json['category'];
    if (rawCategory is Map<String, dynamic>) {
      category = CategoryModel.fromJson(rawCategory);
    } else if (rawCategory is String && rawCategory.isNotEmpty) {
      category = CategoryModel(id: rawCategory, name: '');
    }

    return ProductModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] as num?) ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      category: category,
      averageRating: (json['averageRating'] as num?) ?? 0,
    );
  }
}
