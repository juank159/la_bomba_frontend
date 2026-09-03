// lib/features/vegetable_cash_sessions/domain/usecases/vegetable_cash_sessions_usecases.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_cash_session.dart';
import '../repositories/vegetable_cash_sessions_repository.dart';

class OpenCashSessionUseCase {
  final VegetableCashSessionsRepository repository;

  OpenCashSessionUseCase(this.repository);

  Future<Either<Failure, VegetableCashSession>> call({required double openingAmount, String? notes}) async {
    try {
      if (openingAmount < 0) {
        return Left(ValidationFailure.required('Fondo inicial', 'El fondo inicial no puede ser negativo'));
      }
      return await repository.open(openingAmount: openingAmount, notes: notes);
    } catch (e) {
      return Left(UnexpectedFailure('Error inesperado al abrir la caja: ${e.toString()}', exception: e is Exception ? e : Exception(e.toString())));
    }
  }
}

class CloseCashSessionUseCase {
  final VegetableCashSessionsRepository repository;

  CloseCashSessionUseCase(this.repository);

  Future<Either<Failure, VegetableCashSession>> call({required double closingAmount, String? notes}) async {
    try {
      if (closingAmount < 0) {
        return Left(ValidationFailure.required('Conteo final', 'El conteo no puede ser negativo'));
      }
      return await repository.close(closingAmount: closingAmount, notes: notes);
    } catch (e) {
      return Left(UnexpectedFailure('Error inesperado al cerrar la caja: ${e.toString()}', exception: e is Exception ? e : Exception(e.toString())));
    }
  }
}

class GetCurrentCashSessionUseCase {
  final VegetableCashSessionsRepository repository;

  GetCurrentCashSessionUseCase(this.repository);

  Future<Either<Failure, VegetableCashSessionSummary>> call() async {
    try {
      return await repository.getCurrent();
    } catch (e) {
      return Left(UnexpectedFailure('Error inesperado al consultar la caja: ${e.toString()}', exception: e is Exception ? e : Exception(e.toString())));
    }
  }
}

class GetCashSessionsHistoryUseCase {
  final VegetableCashSessionsRepository repository;

  GetCashSessionsHistoryUseCase(this.repository);

  Future<Either<Failure, List<VegetableCashSession>>> call() async {
    try {
      return await repository.getHistory();
    } catch (e) {
      return Left(UnexpectedFailure('Error inesperado al obtener el historial de caja: ${e.toString()}', exception: e is Exception ? e : Exception(e.toString())));
    }
  }
}

class GetCashSessionByIdUseCase {
  final VegetableCashSessionsRepository repository;

  GetCashSessionByIdUseCase(this.repository);

  Future<Either<Failure, VegetableCashSession>> call(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID del turno es requerido'));
      }
      return await repository.getById(id.trim());
    } catch (e) {
      return Left(UnexpectedFailure('Error inesperado al obtener el turno: ${e.toString()}', exception: e is Exception ? e : Exception(e.toString())));
    }
  }
}

class GetCashSessionBreakdownUseCase {
  final VegetableCashSessionsRepository repository;

  GetCashSessionBreakdownUseCase(this.repository);

  Future<Either<Failure, List<CashSessionPaymentBreakdown>>> call(String sessionId) async {
    try {
      if (sessionId.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID del turno es requerido'));
      }
      return await repository.getBreakdown(sessionId.trim());
    } catch (e) {
      return Left(UnexpectedFailure('Error inesperado al obtener el desglose: ${e.toString()}', exception: e is Exception ? e : Exception(e.toString())));
    }
  }
}
