import 'package:equatable/equatable.dart';

/// Sort options supported by the backend `sort` query param.
enum ProductSort {
  none(null, 'Default'),
  priceAsc('price', 'Price: Low to High'),
  priceDesc('-price', 'Price: High to Low'),
  newest('-createdAt', 'Newest'),
  topRated('-averageRating', 'Top Rated');

  final String? value;
  final String label;
  const ProductSort(this.value, this.label);
}

/// Represents the currently selected filters.
///
/// This is the heart of the filter feature: the data layer turns an instance
/// of this into the query params for `GET /products`
/// (search, category, minPrice, maxPrice, sort, page, limit).
class ProductFilter extends Equatable {
  final String? search;
  final String? categoryId;
  final num? minPrice;
  final num? maxPrice;
  final ProductSort sort;
  final int page;
  final int limit;

  const ProductFilter({
    this.search,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.sort = ProductSort.none,
    this.page = 1,
    this.limit = 10,
  });

  /// Convert to query params, omitting empty/null values so the backend
  /// receives a clean query string.
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null && search!.trim().isNotEmpty) {
      params['search'] = search!.trim();
    }
    if (categoryId != null && categoryId!.isNotEmpty) {
      params['category'] = categoryId;
    }
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (sort.value != null) params['sort'] = sort.value;

    return params;
  }

  /// Returns true when at least one filter (other than pagination) is active.
  bool get hasActiveFilters =>
      (search != null && search!.trim().isNotEmpty) ||
      (categoryId != null && categoryId!.isNotEmpty) ||
      minPrice != null ||
      maxPrice != null ||
      sort != ProductSort.none;

  ProductFilter copyWith({
    String? search,
    bool clearSearch = false,
    String? categoryId,
    bool clearCategory = false,
    num? minPrice,
    bool clearMinPrice = false,
    num? maxPrice,
    bool clearMaxPrice = false,
    ProductSort? sort,
    int? page,
    int? limit,
  }) {
    return ProductFilter(
      search: clearSearch ? null : (search ?? this.search),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props =>
      [search, categoryId, minPrice, maxPrice, sort, page, limit];
}
