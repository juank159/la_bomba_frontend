import 'package:dartz/dartz.dart';
import 'package:pedidos_frontend/app/core/errors/failures.dart';
import '../entities/income.dart';

abstract class IncomesRepository {
  Future<Either<Failure, List<Income>>> getIncomes();
  Future<Either<Failure, Income>> getIncomeById(String id);
  Future<Either<Failure, Income>> createIncome({required String description, required double amount});
  Future<Either<Failure, Income>> updateIncome({required String id, String? description, double? amount});
  Future<Either<Failure, void>> deleteIncome(String id);
}
