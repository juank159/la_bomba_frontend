// lib/features/credits/data/repositories/credits_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/credit.dart';
import '../../domain/repositories/credits_repository.dart';
import '../datasources/credits_remote_datasource.dart';

/// Implementation of CreditsRepository that uses remote data source
class CreditsRepositoryImpl implements CreditsRepository {
  final CreditsRemoteDataSource remoteDataSource;

  const CreditsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Credit>>> getAllCredits() async {
    try {
      final credits = await remoteDataSource.getAllCredits();
      return Right(credits);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Credit>> getCreditById(String id) async {
    try {
      final credit = await remoteDataSource.getCreditById(id);
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Credit>> createCredit(
    Map<String, dynamic> creditData,
  ) async {
    try {
      final credit = await remoteDataSource.createCredit(creditData);
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ConflictException catch (e) {
      return Left(ServerFailure.conflict(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Credit>> updateCredit(
    String id,
    Map<String, dynamic> updatedData,
  ) async {
    try {
      final credit = await remoteDataSource.updateCredit(id, updatedData);
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ConflictException catch (e) {
      return Left(ServerFailure.conflict(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Credit>> addPayment(
    String creditId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final credit = await remoteDataSource.addPayment(creditId, paymentData);
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on BadRequestException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Credit>> removePayment(
    String creditId,
    String paymentId,
  ) async {
    try {
      final credit = await remoteDataSource.removePayment(creditId, paymentId);
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCredit(String id) async {
    try {
      await remoteDataSource.deleteCredit(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Credit?>> getPendingCreditByClient(
    String clientId,
  ) async {
    try {
      final credit = await remoteDataSource.getPendingCreditByClient(clientId);
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Credit>> addAmountToCredit(
    String creditId,
    double amount,
    String description,
  ) async {
    try {
      final credit = await remoteDataSource.addAmountToCredit(
        creditId,
        amount,
        description,
      );
      return Right(credit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on UnauthorizedException catch (e) {
      return Left(AuthFailure(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on BadRequestException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Error inesperado: ${e.toString()}'));
    }
  }
}
