import 'package:api_explorer/app.dart';
import 'package:api_explorer/domain/product.dart';
import 'package:api_explorer/domain/product_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a product and an empty search', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final repository = _FakeRepository();
    await tester.pumpWidget(
      ApiExplorerApp(repository: repository, pageSize: 20),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pencil'), findsOneWidget);
    expect(find.textContaining('No account'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('product-search')), 'missing');
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    expect(find.text('No products match this search.'), findsOneWidget);
    expect(repository.lastQuery, 'missing');
  });

  testWidgets('failed load offers retry', (tester) async {
    final repository = _FakeRepository()..fail = true;
    await tester.pumpWidget(ApiExplorerApp(repository: repository));
    await tester.pumpAndSettle();
    expect(find.text('You appear to be offline.'), findsOneWidget);

    repository.fail = false;
    await tester.tap(find.byKey(const Key('retry-load')));
    await tester.pumpAndSettle();
    expect(find.text('Pencil'), findsOneWidget);
  });

  testWidgets('opens the detail screen', (tester) async {
    await tester.pumpWidget(ApiExplorerApp(repository: _FakeRepository()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pencil'));
    await tester.pumpAndSettle();
    expect(find.text('A wooden pencil.'), findsOneWidget);
  });
}

class _FakeRepository implements ProductRepository {
  bool fail = false;
  String lastQuery = '';

  Product get _pencil => const Product(
    id: 1,
    title: 'Pencil',
    description: 'A wooden pencil.',
    category: 'office',
    price: 1.5,
    rating: 4,
    stock: 8,
    thumbnail: '',
  );

  @override
  Future<ProductPage> fetch({
    required int skip,
    required int limit,
    required String query,
  }) async {
    lastQuery = query;
    if (fail) {
      throw const ApiFailure(
        ApiFailureKind.offline,
        'You appear to be offline.',
      );
    }
    if (query == 'missing') {
      return const ProductPage(products: [], total: 0, skip: 0, limit: 20);
    }
    return ProductPage(products: [_pencil], total: 1, skip: 0, limit: limit);
  }

  @override
  Future<Product> fetchById(int id) async => _pencil;
}
