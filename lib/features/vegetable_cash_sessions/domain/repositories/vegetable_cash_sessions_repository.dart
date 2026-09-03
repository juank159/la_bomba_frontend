// lib/features/vegetable_cash_sessions/domain/repositories/vegetable_cash_sessions_repository.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/vegetable_cash_session.dart';

abstract class VegetableCashSessionsRepository {
  Future<Either<Failure, VegetableCashSession>> open({required double openingAmount, String? notes});
  Future<Either<Failure, VegetableCashSession>> close({required double closingAmount, String? notes});
  Future<Either<Failure, VegetableCashSessionSummary>> getCurrent();
  Future<Either<Failure, List<VegetableCashSession>>> getHistory();
  Future<Either<Failure, VegetableCashSession>> getById(String id);
  Future<Either<Failure, List<CashSessionPaymentBreakdown>>> getBreakdown(String sessionId);
}
