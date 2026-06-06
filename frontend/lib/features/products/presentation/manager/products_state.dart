part of 'products_cubit.dart';

enum ProductsStatus { initial, loading, success, failure }

class ProductsState extends Equatable {
  final ProductsStatus status;
  final PaginatedProducts? data;
  final List<Category> categories;
  final String? errorMessage;

  const ProductsState({
    this.status = ProductsStatus.initial,
    this.data,
    this.categories = const [],
    this.errorMessage,
  });

  ProductsState copyWith({
    ProductsStatus? status,
    PaginatedProducts? data,
    List<Category>? categories,
    String? errorMessage,
  }) {
    return ProductsState(
      status: status ?? this.status,
      data: data ?? this.data,
      categories: categories ?? this.categories,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, categories, errorMessage];
}
