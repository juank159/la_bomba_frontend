// lib/features/credits/data/repositories/payment_method_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_method_repository.dart';
import '../datasources/payment_method_remote_datasource.dart';

class PaymentMethodRepositoryImpl implements PaymentMethodRepository {
  final PaymentMethodRemoteDataSource remoteDataSource;

  PaymentMethodRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PaymentMethod>>> getAllPaymentMethods() async {
    try {
      final methodModels = await remoteDataSource.getAllPaymentMethods();
      final methods = methodModels.map((model) => model.toEntity()).toList();
      return Right(methods);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener métodos de pago: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, PaymentMethod>> getPaymentMethodById(String id) async {
    try {
      final methodModel = await remoteDataSource.getPaymentMethodById(id);
      return Right(methodModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener método de pago: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, PaymentMethod>> createPaymentMethod({
    required String name,
    String? description,
    String? icon,
  }) async {
    try {
      final methodModel = await remoteDataSource.createPaymentMethod(
        name: name,
        description: description,
        icon: icon,
      );
      return Right(methodModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al crear método de pago: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, PaymentMethod>> updatePaymentMethod({
    required String id,
    String? name,
    String? description,
    String? icon,
  }) async {
    try {
      final methodModel = await remoteDataSource.updatePaymentMethod(
        id: id,
        name: name,
        description: description,
        icon: icon,
      );
      return Right(methodModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al actualizar método de pago: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deletePaymentMethod(String id) async {
    try {
      await remoteDataSource.deletePaymentMethod(id);
      return const Right(null);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al eliminar método de pago: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, PaymentMethod>> activatePaymentMethod({
    required String id,
    required bool isActive,
  }) async {
    try {
      final methodModel = await remoteDataSource.activatePaymentMethod(
        id: id,
        isActive: isActive,
      );
      return Right(methodModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al cambiar estado del método de pago: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
