import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/category.dart';
import '../entities/paginated_products.dart';
import '../entities/product_filter.dart';

/// Contract the presentation layer depends on. The data layer provides the
/// concrete implementation.
abstract class ProductRepository {
  Future<Either<Failure, PaginatedProducts>> getProducts(ProductFilter filter);

  Future<Either<Failure, List<Category>>> getCategories();
}
