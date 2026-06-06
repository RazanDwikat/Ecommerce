/// Central place for all backend endpoints.
///
/// The Node.js backend exposes:
///   GET /products    (supports: search, category, minPrice, maxPrice, sort, page, limit)
///   GET /categories
class ApiEndpoints {
  ApiEndpoints._();

  /// Base URL of the backend.
  ///
  /// - Android emulator reaches the host machine via 10.0.2.2
  /// - iOS simulator / web use localhost
  /// Override with --dart-define=BASE_URL=... when running on a real device.
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const String products = '/products';
  static const String categories = '/categories';
}
