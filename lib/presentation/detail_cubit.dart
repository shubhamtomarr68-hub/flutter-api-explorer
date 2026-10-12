import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/product.dart';
import '../domain/product_repository.dart';

enum DetailStatus { loading, ready, failure }

class DetailState extends Equatable {
  const DetailState({required this.status, this.product, this.errorMessage});

  final DetailStatus status;
  final Product? product;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, product, errorMessage];
}

class ProductDetailCubit extends Cubit<DetailState> {
  ProductDetailCubit({required this.repository, required this.id})
    : super(const DetailState(status: DetailStatus.loading));

  final ProductRepository repository;
  final int id;

  Future<void> load() async {
    emit(const DetailState(status: DetailStatus.loading));
    try {
      final product = await repository.fetchById(id);
      emit(DetailState(status: DetailStatus.ready, product: product));
    } on ApiFailure catch (failure) {
      emit(
        DetailState(
          status: DetailStatus.failure,
          errorMessage: failure.message,
        ),
      );
    }
  }
}
