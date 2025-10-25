import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/product.dart';
import '../repositories/products_repository.dart';

/// Parameters for the get products use case
class GetProductsParams {
  final int page;
  final int limit;
  final String? search;

  const GetProductsParams({
    this.page = 0,
    this.limit = 20,
    this.search,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetProductsParams &&
        other.page == page &&
        other.limit == limit &&
        other.search == search;
  }

  @override
  int get hashCode => page.hashCode ^ limit.hashCode ^ search.hashCode;

  @override
  String toString() {
    return 'GetProductsParams(page: $page, limit: $limit, search: $search)';
  }

  GetProductsParams copyWith({
    int? page,
    int? limit,
    String? search,
  }) {
    return GetProductsParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
    );
  }
}

/// Use case for getting products with pagination and search functionality
class GetProductsUseCase {
  final ProductsRepository repository;

  GetProductsUseCase(this.repository);

  /// Execute the use case to get products
  /// 
  /// [params] - Optional parameters for pagination and search
  /// 
  /// Returns a list of products or a failure
  Future<Either<Failure, List<Product>>> call([GetProductsParams? params]) async {
    final parameters = params ?? const GetProductsParams();
    
    try {
      if (parameters.search != null && parameters.search!.trim().isNotEmpty) {
        // Use search functionality if search query is provided
        return await repository.searchProducts(
          parameters.search!.trim(),
          page: parameters.page,
          limit: parameters.limit,
        );
      } else {
        // Get all products with pagination
        return await repository.getAllProducts(
          page: parameters.page,
          limit: parameters.limit,
        );
      }
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener productos: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Get products count for pagination
  Future<Either<Failure, int>> getCount([String? search]) async {
    try {
      return await repository.getProductsCount(search: search);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener el conteo de productos: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

/// Parameters for getting a single product by ID
class GetProductByIdParams {
  final String id;

  const GetProductByIdParams({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetProductByIdParams && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GetProductByIdParams(id: $id)';
  }
}

/// Use case for getting a single product by ID
class GetProductByIdUseCase {
  final ProductsRepository repository;

  GetProductByIdUseCase(this.repository);

  /// Execute the use case to get a product by ID
  /// 
  /// [params] - Parameters containing the product ID
  /// 
  /// Returns the product or a failure
  Future<Either<Failure, Product>> call(GetProductByIdParams params) async {
    try {
      if (params.id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID del producto es requerido'));
      }

      return await repository.getProductById(params.id.trim());
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener el producto: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}