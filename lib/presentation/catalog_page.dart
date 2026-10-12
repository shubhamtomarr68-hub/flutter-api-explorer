import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/product.dart';
import '../domain/product_repository.dart';
import 'catalog_cubit.dart';
import 'detail_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Explorer')),
      body: BlocBuilder<CatalogCubit, CatalogState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  'Public DummyJSON products. No account and no API key.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('product-search'),
                        controller: _query,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText: 'Search products',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onSubmitted: (value) =>
                            context.read<CatalogCubit>().load(query: value),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Search',
                      onPressed: () =>
                          context.read<CatalogCubit>().load(query: _query.text),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
              Expanded(child: _CatalogBody(state: state)),
            ],
          );
        },
      ),
    );
  }
}

class _CatalogBody extends StatelessWidget {
  const _CatalogBody({required this.state});

  final CatalogState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CatalogStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case CatalogStatus.failure:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.errorMessage ?? 'Could not load products.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('retry-load'),
                  onPressed: () => context.read<CatalogCubit>().load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      case CatalogStatus.ready:
        if (state.products.isEmpty) {
          return const Center(child: Text('No products match this search.'));
        }
        return RefreshIndicator(
          onRefresh: () => context.read<CatalogCubit>().load(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 240) {
                context.read<CatalogCubit>().loadMore();
              }
              return false;
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: state.products.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index >= state.products.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return _ProductTile(product: state.products[index]);
              },
            ),
          ),
        );
    }
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: _Thumb(url: product.thumbnail),
        title: Text(product.title),
        subtitle: Text(
          '${product.category} · ${product.rating.toStringAsFixed(1)} ★',
        ),
        trailing: Text(
          '\$${product.price.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onTap: () {
          final repository = context.read<ProductRepository>();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => RepositoryProvider.value(
                value: repository,
                child: ProductDetailPage(productId: product.id),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const Icon(Icons.image_not_supported_outlined);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_not_supported_outlined),
      ),
    );
  }
}
