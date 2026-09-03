// lib/features/corresponsal/data/repositories/corresponsal_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/corresponsal_entry.dart';
import '../../domain/repositories/corresponsal_repository.dart';
import '../datasources/corresponsal_remote_datasource.dart';

class CorresponsalRepositoryImpl implements CorresponsalRepository {
  final CorresponsalRemoteDataSource remoteDataSource;

  CorresponsalRepositoryImpl({required this.remoteDataSource});

  Failure _mapException(Object e, String fallbackMessage) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ValidationException) return ValidationFailure(e.message, code: 'VALIDATION_ERROR');
    if (e is AuthException) return AuthFailure(e.message);
    if (e is NotFoundException) return ServerFailure.notFound(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    return UnexpectedFailure(
      '$fallbackMessage: ${e.toString()}',
      exception: e is Exception ? e : Exception(e.toString()),
    );
  }

  @override
  Future<Either<Failure, List<CorresponsalEntry>>> getEntries() async {
    try {
      final models = await remoteDataSource.getEntries();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener los registros'));
    }
  }

  @override
  Future<Either<Failure, CorresponsalEntry>> createEntry({required double amount, String? note}) async {
    try {
      final model = await remoteDataSource.createEntry(amount: amount, note: note);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al registrar el ingreso'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEntry(String id) async {
    try {
      await remoteDataSource.deleteEntry(id);
      return const Right(null);
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al eliminar el registro'));
    }
  }
}
