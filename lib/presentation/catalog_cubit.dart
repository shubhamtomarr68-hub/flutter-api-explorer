import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/product.dart';
import '../domain/product_repository.dart';

enum CatalogStatus { loading, ready, failure }

class CatalogState extends Equatable {
  const CatalogState({
    required this.status,
    required this.products,
    required this.query,
    required this.total,
    required this.isLoadingMore,
    required this.errorMessage,
  });

  const CatalogState.initial()
    : status = CatalogStatus.loading,
      products = const [],
      query = '',
      total = 0,
      isLoadingMore = false,
      errorMessage = null;

  final CatalogStatus status;
  final List<Product> products;
  final String query;
  final int total;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get hasMore => products.length < total;

  CatalogState copyWith({
    CatalogStatus? status,
    List<Product>? products,
    String? query,
    int? total,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CatalogState(
      status: status ?? this.status,
      products: products ?? this.products,
      query: query ?? this.query,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    products,
    query,
    total,
    isLoadingMore,
    errorMessage,
  ];
}

class CatalogCubit extends Cubit<CatalogState> {
  CatalogCubit({required this.repository, this.pageSize = 20})
    : super(const CatalogState.initial());

  final ProductRepository repository;
  final int pageSize;
  int _generation = 0;

  Future<void> load({String? query}) async {
    final nextQuery = query ?? state.query;
    final generation = ++_generation;
    emit(
      state.copyWith(
        status: CatalogStatus.loading,
        query: nextQuery,
        products: const [],
        total: 0,
        isLoadingMore: false,
        clearError: true,
      ),
    );
    try {
      final page = await repository.fetch(
        skip: 0,
        limit: pageSize,
        query: nextQuery,
      );
      if (generation != _generation) {
        return;
      }
      emit(
        state.copyWith(
          status: CatalogStatus.ready,
          products: page.products,
          total: page.total,
          clearError: true,
        ),
      );
    } on ApiFailure catch (failure) {
      if (generation != _generation) {
        return;
      }
      emit(
        state.copyWith(
          status: CatalogStatus.failure,
          errorMessage: failure.message,
        ),
      );
    }
  }

  Future<String?> loadMore() async {
    if (state.status != CatalogStatus.ready ||
        state.isLoadingMore ||
        !state.hasMore) {
      return null;
    }
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final page = await repository.fetch(
        skip: state.products.length,
        limit: pageSize,
        query: state.query,
      );
      if (generation != _generation) {
        return null;
      }
      emit(
        state.copyWith(
          products: [...state.products, ...page.products],
          total: page.total,
          isLoadingMore: false,
        ),
      );
      return null;
    } on ApiFailure catch (failure) {
      if (generation != _generation) {
        return null;
      }
      emit(state.copyWith(isLoadingMore: false));
      return failure.message;
    }
  }
}
