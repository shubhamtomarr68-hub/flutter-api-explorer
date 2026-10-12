import 'package:dio/dio.dart';

import '../domain/product_repository.dart';

ApiFailure mapDioException(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const ApiFailure(ApiFailureKind.timeout, 'The request timed out.');
    case DioExceptionType.connectionError:
      return const ApiFailure(
        ApiFailureKind.offline,
        'You appear to be offline.',
      );
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode ?? 0;
      if (code == 404) {
        return const ApiFailure(
          ApiFailureKind.notFound,
          'That product was not found.',
        );
      }
      if (code >= 500) {
        return const ApiFailure(
          ApiFailureKind.server,
          'The product service returned an error.',
        );
      }
      return ApiFailure(
        ApiFailureKind.unknown,
        'The product service rejected the request ($code).',
      );
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.unknown:
      return const ApiFailure(
        ApiFailureKind.unknown,
        'The request could not be completed.',
      );
  }
}

ApiFailure mapParseError(Object error) {
  return const ApiFailure(
    ApiFailureKind.malformed,
    'The product service returned data this app could not read.',
  );
}
