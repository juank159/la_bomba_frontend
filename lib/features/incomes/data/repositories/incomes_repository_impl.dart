import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/core/errors/failures.dart';
import '../../domain/entities/income.dart';
import '../../domain/repositories/incomes_repository.dart';
import '../datasources/incomes_remote_datasource.dart';

class IncomesRepositoryImpl implements IncomesRepository {
  final IncomesRemoteDataSource remoteDataSource;
  IncomesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Income>>> getIncomes() async {
    try {
      final incomes = await remoteDataSource.getIncomes();
      return Right(incomes);
    } on UnauthorizedException {
      return Left(ServerFailure.unauthorized());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Income>> getIncomeById(String id) async {
    try {
      final income = await remoteDataSource.getIncomeById(id);
      return Right(income);
    } on UnauthorizedException {
      return Left(ServerFailure.unauthorized());
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Income>> createIncome({required String description, required double amount}) async {
    try {
      final income = await remoteDataSource.createIncome(description: description, amount: amount);
      return Right(income);
    } on UnauthorizedException {
      return Left(ServerFailure.unauthorized());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Income>> updateIncome({required String id, String? description, double? amount}) async {
    try {
      final income = await remoteDataSource.updateIncome(id: id, description: description, amount: amount);
      return Right(income);
    } on UnauthorizedException {
      return Left(ServerFailure.unauthorized());
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteIncome(String id) async {
    try {
      await remoteDataSource.deleteIncome(id);
      return const Right(null);
    } on UnauthorizedException {
      return Left(ServerFailure.unauthorized());
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }
}
