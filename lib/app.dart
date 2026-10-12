import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'domain/product_repository.dart';
import 'presentation/catalog_cubit.dart';
import 'presentation/catalog_page.dart';
import 'theme.dart';

class ApiExplorerApp extends StatelessWidget {
  const ApiExplorerApp({
    super.key,
    required this.repository,
    this.pageSize = 20,
  });

  final ProductRepository repository;
  final int pageSize;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: repository,
      child: BlocProvider(
        create: (_) =>
            CatalogCubit(repository: repository, pageSize: pageSize)..load(),
        child: MaterialApp(
          title: 'API Explorer',
          debugShowCheckedModeBanner: false,
          theme: buildApiExplorerTheme(Brightness.light),
          darkTheme: buildApiExplorerTheme(Brightness.dark),
          home: const CatalogPage(),
        ),
      ),
    );
  }
}
