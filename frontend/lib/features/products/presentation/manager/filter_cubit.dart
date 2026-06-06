import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/product_filter.dart';

/// Holds the currently selected filter values.
///
/// The UI (filter bottom sheet, search field, etc.) updates this cubit, and the
/// products page listens to it to re-fetch products.
class FilterCubit extends Cubit<ProductFilter> {
  FilterCubit() : super(const ProductFilter());

  void setSearch(String? value) {
    emit(state.copyWith(
      search: value,
      clearSearch: value == null || value.isEmpty,
      page: 1,
    ));
  }

  void setCategory(String? categoryId) {
    emit(state.copyWith(
      categoryId: categoryId,
      clearCategory: categoryId == null,
      page: 1,
    ));
  }

  void setPriceRange(num? min, num? max) {
    emit(state.copyWith(
      minPrice: min,
      clearMinPrice: min == null,
      maxPrice: max,
      clearMaxPrice: max == null,
      page: 1,
    ));
  }

  void setSort(ProductSort sort) {
    emit(state.copyWith(sort: sort, page: 1));
  }

  void setPage(int page) {
    emit(state.copyWith(page: page));
  }

  void reset() {
    emit(const ProductFilter());
  }
}
