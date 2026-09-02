import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_order.dart';
import '../repositories/vegetables_repository.dart';

class GetVegetableOrdersUseCase {
  final VegetablesRepository repository;

  GetVegetableOrdersUseCase(this.repository);

  Future<Either<Failure, List<VegetableOrder>>> call() async {
    try {
      return await repository.getOrders();
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener los pedidos: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}

class GetVegetableOrderByIdUseCase {
  final VegetablesRepository repository;

  GetVegetableOrderByIdUseCase(this.repository);

  Future<Either<Failure, VegetableOrder>> call(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID del pedido es requerido'));
      }
      return await repository.getOrderById(id.trim());
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener el pedido: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
