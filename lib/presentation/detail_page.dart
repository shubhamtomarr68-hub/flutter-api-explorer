import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/product_repository.dart';
import 'detail_cubit.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});

  final int productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductDetailCubit(
        repository: context.read<ProductRepository>(),
        id: productId,
      )..load(),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: BlocBuilder<ProductDetailCubit, DetailState>(
        builder: (context, state) {
          switch (state.status) {
            case DetailStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case DetailStatus.failure:
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.errorMessage ?? 'Could not load this product.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            context.read<ProductDetailCubit>().load(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            case DetailStatus.ready:
              final product = state.product!;
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (product.thumbnail.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        product.thumbnail,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(
                              height: 120,
                              child: Center(
                                child: Icon(Icons.image_not_supported_outlined),
                              ),
                            ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.category} · \$${product.price.toStringAsFixed(2)} · ${product.stock} in stock',
                  ),
                  const SizedBox(height: 12),
                  Text(product.description),
                ],
              );
          }
        },
      ),
    );
  }
}
