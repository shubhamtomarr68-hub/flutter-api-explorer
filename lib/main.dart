import 'package:flutter/material.dart';

import 'app.dart';
import 'domain/product_repository.dart';
import 'injection.dart';

void main() {
  configureDependencies();
  runApp(ApiExplorerApp(repository: getIt<ProductRepository>()));
}
