import 'product.dart';

abstract class ProductRepository {
  Future<ProductPage> fetch({
    required int skip,
    required int limit,
    required String query,
  });

  Future<Product> fetchById(int id);
}

enum ApiFailureKind { timeout, offline, server, notFound, malformed, unknown }

class ApiFailure implements Exception {
  const ApiFailure(this.kind, this.message);

  final ApiFailureKind kind;
  final String message;

  @override
  String toString() => message;
}
