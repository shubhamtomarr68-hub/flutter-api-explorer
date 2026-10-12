import 'package:api_explorer/data/api_failure_mapper.dart';
import 'package:api_explorer/domain/product.dart';
import 'package:api_explorer/domain/product_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps timeouts, offline, server, and not found', () {
    ApiFailure map(DioExceptionType type, {int? status}) {
      return mapDioException(
        DioException(
          requestOptions: RequestOptions(path: '/products'),
          type: type,
          response: status == null
              ? null
              : Response(
                  requestOptions: RequestOptions(path: '/products'),
                  statusCode: status,
                ),
        ),
      );
    }

    expect(map(DioExceptionType.receiveTimeout).kind, ApiFailureKind.timeout);
    expect(map(DioExceptionType.connectionError).kind, ApiFailureKind.offline);
    expect(
      map(DioExceptionType.badResponse, status: 500).kind,
      ApiFailureKind.server,
    );
    expect(
      map(DioExceptionType.badResponse, status: 404).kind,
      ApiFailureKind.notFound,
    );
  });

  test('product JSON rejects a missing title and accepts a page', () {
    expect(
      () => Product.fromJson({'id': 1, 'price': 2}),
      throwsFormatException,
    );
    final page = ProductPage.fromJson({
      'products': [
        {
          'id': 1,
          'title': 'Pencil',
          'price': 1.5,
          'description': 'Wood',
          'category': 'office',
          'rating': 4.2,
          'stock': 3,
          'thumbnail': '',
        },
      ],
      'total': 1,
      'skip': 0,
      'limit': 20,
    });
    expect(page.products.single.title, 'Pencil');
    expect(page.products.single.price, 1.5);
  });
}
