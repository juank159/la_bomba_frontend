import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../repositories/clients_repository.dart';

/// Parameters for deleting a client
class DeleteClientParams {
  final String id;

  const DeleteClientParams({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeleteClientParams && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DeleteClientParams(id: $id)';
  }
}

/// Use case for deleting a client (soft delete)
class DeleteClientUseCase {
  final ClientsRepository repository;

  DeleteClientUseCase(this.repository);

  /// Execute the use case to delete a client
  ///
  /// [params] - Parameters containing the client ID
  ///
  /// Returns void or a failure
  Future<Either<Failure, void>> call(DeleteClientParams params) async {
    try {
      // Validate ID is not empty
      if (params.id.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'ID', 'El ID del cliente es requerido'));
      }

      return await repository.deleteClient(params.id.trim());
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al eliminar el cliente: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}
