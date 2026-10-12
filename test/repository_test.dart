import 'dart:convert';
import 'dart:typed_data';

import 'package:api_explorer/data/dio_product_repository.dart';
import 'package:api_explorer/domain/product.dart';
import 'package:api_explorer/domain/product_repository.dart';
import 'package:api_explorer/presentation/catalog_cubit.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('repository maps a 500 and a malformed body', () async {
    final server = _adapter(status: 500, body: '{"message":"nope"}');
    final repository = DioProductRepository(
      dio: createCatalogDio(adapter: server),
    );
    expect(
      () => repository.fetch(skip: 0, limit: 20, query: ''),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.kind,
          'kind',
          ApiFailureKind.server,
        ),
      ),
    );

    final malformed = DioProductRepository(
      dio: createCatalogDio(
        adapter: _adapter(status: 200, body: '{"products": {}}'),
      ),
    );
    expect(
      () => malformed.fetch(skip: 0, limit: 20, query: ''),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.kind,
          'kind',
          ApiFailureKind.malformed,
        ),
      ),
    );
  });

  test('repository reads a product page and a search path', () async {
    final adapter = _ScriptedAdapter((options) async {
      expect(options.path, '/products/search');
      expect(options.queryParameters['q'], 'phone');
      return _body(
        200,
        jsonEncode({
          'products': [
            {'id': 7, 'title': 'Phone', 'price': 499},
          ],
          'total': 1,
          'skip': 0,
          'limit': 20,
        }),
      );
    });
    final repository = DioProductRepository(
      dio: createCatalogDio(adapter: adapter),
    );
    final page = await repository.fetch(skip: 0, limit: 20, query: ' phone ');
    expect(page.products.single.title, 'Phone');
  });

  test('load more keeps products when the next page fails', () async {
    final repository = _PagingRepository();
    final cubit = CatalogCubit(repository: repository, pageSize: 1);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.products.single.title, 'One');
    repository.failNext = true;
    expect(await cubit.loadMore(), 'The product service returned an error.');
    expect(cubit.state.products.single.title, 'One');
    expect(cubit.state.status, CatalogStatus.ready);
  });
}

class _PagingRepository implements ProductRepository {
  bool failNext = false;

  @override
  Future<ProductPage> fetch({
    required int skip,
    required int limit,
    required String query,
  }) async {
    if (failNext) {
      throw const ApiFailure(
        ApiFailureKind.server,
        'The product service returned an error.',
      );
    }
    if (skip == 0) {
      return ProductPage(
        products: [
          Product(
            id: 1,
            title: 'One',
            description: '',
            category: 'test',
            price: 1,
            rating: 1,
            stock: 1,
            thumbnail: '',
          ),
        ],
        total: 2,
        skip: 0,
        limit: limit,
      );
    }
    return ProductPage(
      products: [
        Product(
          id: 2,
          title: 'Two',
          description: '',
          category: 'test',
          price: 2,
          rating: 1,
          stock: 1,
          thumbnail: '',
        ),
      ],
      total: 2,
      skip: skip,
      limit: limit,
    );
  }

  @override
  Future<Product> fetchById(int id) async {
    throw UnimplementedError();
  }
}

HttpClientAdapter _adapter({required int status, required String body}) {
  return _ScriptedAdapter((options) async => _body(status, body));
}

ResponseBody _body(int status, String body) {
  return ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this._handle);

  final Future<ResponseBody> Function(RequestOptions options) _handle;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handle(options);
  }

  @override
  void close({bool force = false}) {}
}
