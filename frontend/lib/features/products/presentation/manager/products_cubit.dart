import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/paginated_products.dart';
import '../../domain/entities/product_filter.dart';
import '../../domain/usecases/get_categories.dart';
import '../../domain/usecases/get_products.dart';

part 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final GetProducts getProducts;
  final GetCategories getCategories;

  ProductsCubit({
    required this.getProducts,
    required this.getCategories,
  }) : super(const ProductsState());

  /// Loads the categories for the filter dropdown.
  Future<void> loadCategories() async {
    final result = await getCategories(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(categories: const [])),
      (categories) => emit(state.copyWith(categories: categories)),
    );
  }

  /// Fetches products for the given [filter].
  Future<void> fetchProducts(ProductFilter filter) async {
    emit(state.copyWith(status: ProductsStatus.loading));

    final result = await getProducts(filter);

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProductsStatus.failure,
        errorMessage: failure.message,
      )),
      (data) => emit(state.copyWith(
        status: ProductsStatus.success,
        data: data,
      )),
    );
  }
}
