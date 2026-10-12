import 'package:get_it/get_it.dart';

import 'data/dio_product_repository.dart';
import 'domain/product_repository.dart';

/// Composition root for the real DummyJSON client.
/// Widget tests construct [ApiExplorerApp] with a fake and skip GetIt.
final getIt = GetIt.instance;

void configureDependencies() {
  if (getIt.isRegistered<ProductRepository>()) {
    return;
  }
  getIt.registerSingleton<ProductRepository>(
    DioProductRepository(dio: createCatalogDio()),
  );
}
