import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/paginated_products.dart';
import '../entities/product_filter.dart';
import '../repositories/product_repository.dart';

/// Fetches a filtered, paginated list of products.
class GetProducts implements UseCase<PaginatedProducts, ProductFilter> {
  final ProductRepository repository;

  GetProducts(this.repository);

  @override
  Future<Either<Failure, PaginatedProducts>> call(ProductFilter params) {
    return repository.getProducts(params);
  }
}
