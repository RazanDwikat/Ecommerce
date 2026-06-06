import 'package:ecommerce_app/features/products/domain/entities/product_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductFilter.toQueryParameters', () {
    test('only sends pagination by default', () {
      const filter = ProductFilter();
      expect(filter.toQueryParameters(), {'page': 1, 'limit': 10});
      expect(filter.hasActiveFilters, isFalse);
    });

    test('maps all active filters to backend query params', () {
      const filter = ProductFilter(
        search: 'shoe',
        categoryId: 'cat123',
        minPrice: 10,
        maxPrice: 99,
        sort: ProductSort.priceDesc,
        page: 2,
        limit: 20,
      );

      expect(filter.toQueryParameters(), {
        'page': 2,
        'limit': 20,
        'search': 'shoe',
        'category': 'cat123',
        'minPrice': 10,
        'maxPrice': 99,
        'sort': '-price',
      });
      expect(filter.hasActiveFilters, isTrue);
    });

    test('trims and omits empty search', () {
      const filter = ProductFilter(search: '   ');
      expect(filter.toQueryParameters().containsKey('search'), isFalse);
    });
  });
}
