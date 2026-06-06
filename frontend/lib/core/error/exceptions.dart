/// Thrown by data sources when the server returns an error response.
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

/// Thrown when there is no network connectivity.
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => 'NetworkException: $message';
}
