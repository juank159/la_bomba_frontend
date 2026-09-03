// lib/features/vegetable_cash_sessions/data/repositories/vegetable_cash_sessions_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/vegetable_cash_session.dart';
import '../../domain/repositories/vegetable_cash_sessions_repository.dart';
import '../datasources/vegetable_cash_sessions_remote_datasource.dart';

class VegetableCashSessionsRepositoryImpl implements VegetableCashSessionsRepository {
  final VegetableCashSessionsRemoteDataSource remoteDataSource;

  VegetableCashSessionsRepositoryImpl({required this.remoteDataSource});

  Failure _mapException(Object e, String fallbackMessage) {
    if (e is NetworkException) return NetworkFailure(e.message);
    if (e is ValidationException) return ValidationFailure(e.message, code: 'VALIDATION_ERROR');
    if (e is AuthException) return AuthFailure(e.message);
    if (e is NotFoundException) return ServerFailure.notFound(e.message);
    if (e is ConflictException) return ServerFailure.conflict(e.message);
    if (e is ServerException) return ServerFailure(e.message);
    return UnexpectedFailure('$fallbackMessage: ${e.toString()}', exception: e is Exception ? e : Exception(e.toString()));
  }

  @override
  Future<Either<Failure, VegetableCashSession>> open({required double openingAmount, String? notes}) async {
    try {
      final model = await remoteDataSource.open(openingAmount: openingAmount, notes: notes);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al abrir la caja'));
    }
  }

  @override
  Future<Either<Failure, VegetableCashSession>> close({required double closingAmount, String? notes}) async {
    try {
      final model = await remoteDataSource.close(closingAmount: closingAmount, notes: notes);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al cerrar la caja'));
    }
  }

  @override
  Future<Either<Failure, VegetableCashSessionSummary>> getCurrent() async {
    try {
      final model = await remoteDataSource.getCurrent();
      return Right(model);
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al consultar la caja'));
    }
  }

  @override
  Future<Either<Failure, List<VegetableCashSession>>> getHistory() async {
    try {
      final models = await remoteDataSource.getHistory();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener el historial de caja'));
    }
  }

  @override
  Future<Either<Failure, VegetableCashSession>> getById(String id) async {
    try {
      final model = await remoteDataSource.getById(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener el turno de caja'));
    }
  }

  @override
  Future<Either<Failure, List<CashSessionPaymentBreakdown>>> getBreakdown(String sessionId) async {
    try {
      final breakdown = await remoteDataSource.getBreakdown(sessionId);
      return Right(breakdown);
    } catch (e) {
      return Left(_mapException(e, 'Error inesperado al obtener el desglose de pagos'));
    }
  }
}
