import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../domain/product.dart';
import '../domain/product_repository.dart';
import 'api_failure_mapper.dart';

const dummyJsonBaseUrl = 'https://dummyjson.com';

Dio createCatalogDio({HttpClientAdapter? adapter}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: dummyJsonBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
    ),
  );
  if (adapter != null) {
    dio.httpClientAdapter = adapter;
  }
  dio.interceptors.add(_SafeLogInterceptor());
  return dio;
}

class _SafeLogInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final code = err.response?.statusCode;
    developer.log(
      '${err.requestOptions.method} ${err.requestOptions.uri.path} '
      '${code ?? err.type.name}',
      name: 'api_explorer',
    );
    handler.next(err);
  }
}

class DioProductRepository implements ProductRepository {
  DioProductRepository({required this.dio});

  final Dio dio;

  @override
  Future<ProductPage> fetch({
    required int skip,
    required int limit,
    required String query,
  }) async {
    final trimmed = query.trim();
    final path = trimmed.isEmpty ? '/products' : '/products/search';
    final response = await _send(
      () => dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          'limit': limit,
          'skip': skip,
          if (trimmed.isNotEmpty) 'q': trimmed,
        },
      ),
    );
    return _parse(response, ProductPage.fromJson);
  }

  @override
  Future<Product> fetchById(int id) async {
    final response = await _send(
      () => dio.get<Map<String, dynamic>>('/products/$id'),
    );
    return _parse(response, Product.fromJson);
  }

  Future<Response<Map<String, dynamic>>> _send(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  T _parse<T>(
    Response<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>) decode,
  ) {
    final data = response.data;
    if (data == null) {
      throw mapParseError(const FormatException('Empty body'));
    }
    try {
      return decode(data);
    } on FormatException catch (error) {
      throw mapParseError(error);
    } on TypeError catch (error) {
      throw mapParseError(error);
    }
  }
}
