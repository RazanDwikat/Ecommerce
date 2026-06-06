import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/category.dart';
import '../repositories/product_repository.dart';

/// Fetches the list of categories used to populate the filter dropdown.
class GetCategories implements UseCase<List<Category>, NoParams> {
  final ProductRepository repository;

  GetCategories(this.repository);

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) {
    return repository.getCategories();
  }
}
