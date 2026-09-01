import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_sale.dart';
import '../repositories/vegetables_repository.dart';

class GetVegetableSalesUseCase {
  final VegetablesRepository repository;

  GetVegetableSalesUseCase(this.repository);

  Future<Either<Failure, List<VegetableSale>>> call() async {
    try {
      return await repository.getSales();
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener las ventas: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}

class GetVegetableSaleByIdUseCase {
  final VegetablesRepository repository;

  GetVegetableSaleByIdUseCase(this.repository);

  Future<Either<Failure, VegetableSale>> call(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID de la venta es requerido'));
      }
      return await repository.getSaleById(id.trim());
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener la venta: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
