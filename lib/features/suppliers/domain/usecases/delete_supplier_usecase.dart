import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../repositories/suppliers_repository.dart';

/// Parameters for deleting a supplier
class DeleteSupplierParams {
  final String id;

  const DeleteSupplierParams({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeleteSupplierParams && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeleteSupplierParams(id: $id)';
  }
}

/// Use case for deleting a supplier (soft delete)
class DeleteSupplierUseCase {
  final SuppliersRepository repository;

  DeleteSupplierUseCase(this.repository);

  /// Execute the use case to delete a supplier
  ///
  /// [params] - Parameters containing the supplier ID
  ///
  /// Returns void or a failure
  Future<Either<Failure, void>> call(DeleteSupplierParams params) async {
    try {
      // Validate ID is not empty
      if (params.id.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'ID', 'El ID del proveedor es requerido'));
      }

      return await repository.deleteSupplier(params.id.trim());
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al eliminar el proveedor: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}
