import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/supplier.dart';
import '../repositories/suppliers_repository.dart';

/// Parameters for the get suppliers use case
class GetSuppliersParams {
  final int page;
  final int limit;
  final String? search;

  const GetSuppliersParams({
    this.page = 0,
    this.limit = 20,
    this.search,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetSuppliersParams &&
        other.page == page &&
        other.limit == limit &&
        other.search == search;
  }

  @override
  int get hashCode => page.hashCode ^ limit.hashCode ^ search.hashCode;

  @override
  String toString() {
    return 'GetSuppliersParams(page: $page, limit: $limit, search: $search)';
  }

  GetSuppliersParams copyWith({
    int? page,
    int? limit,
    String? search,
  }) {
    return GetSuppliersParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
    );
  }
}

/// Use case for getting suppliers with pagination and search functionality
class GetSuppliersUseCase {
  final SuppliersRepository repository;

  GetSuppliersUseCase(this.repository);

  /// Execute the use case to get suppliers
  ///
  /// [params] - Optional parameters for pagination and search
  ///
  /// Returns a list of suppliers or a failure
  Future<Either<Failure, List<Supplier>>> call([GetSuppliersParams? params]) async {
    final parameters = params ?? const GetSuppliersParams();

    try {
      if (parameters.search != null && parameters.search!.trim().isNotEmpty) {
        // Use search functionality if search query is provided
        return await repository.searchSuppliers(
          parameters.search!.trim(),
          page: parameters.page,
          limit: parameters.limit,
        );
      } else {
        // Get all suppliers with pagination
        return await repository.getAllSuppliers(
          page: parameters.page,
          limit: parameters.limit,
        );
      }
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener proveedores: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Get suppliers count for pagination
  Future<Either<Failure, int>> getCount([String? search]) async {
    try {
      return await repository.getSuppliersCount(search: search);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener el conteo de proveedores: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

/// Parameters for getting a single supplier by ID
class GetSupplierByIdParams {
  final String id;

  const GetSupplierByIdParams({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetSupplierByIdParams && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GetSupplierByIdParams(id: $id)';
  }
}

/// Use case for getting a single supplier by ID
class GetSupplierByIdUseCase {
  final SuppliersRepository repository;

  GetSupplierByIdUseCase(this.repository);

  /// Execute the use case to get a supplier by ID
  ///
  /// [params] - Parameters containing the supplier ID
  ///
  /// Returns the supplier or a failure
  Future<Either<Failure, Supplier>> call(GetSupplierByIdParams params) async {
    try {
      if (params.id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID del proveedor es requerido'));
      }

      return await repository.getSupplierById(params.id.trim());
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener el proveedor: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}
