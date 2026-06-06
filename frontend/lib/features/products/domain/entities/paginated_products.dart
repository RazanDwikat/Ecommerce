import 'package:equatable/equatable.dart';

import 'product.dart';

/// Mirrors the backend response shape of `GET /products`:
/// { products, total, page, totalPages }
class PaginatedProducts extends Equatable {
  final List<Product> products;
  final int total;
  final int page;
  final int totalPages;

  const PaginatedProducts({
    required this.products,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  @override
  List<Object?> get props => [products, total, page, totalPages];
}
