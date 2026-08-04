import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/repositories/invoices_repository.dart';
import '../datasources/invoices_remote_datasource.dart';

/// Implementation of InvoicesRepository that uses remote data source
class InvoicesRepositoryImpl implements InvoicesRepository {
  final InvoicesRemoteDataSource remoteDataSource;

  InvoicesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Invoice>>> getAllInvoices() async {
    try {
      final invoiceModels = await remoteDataSource.getAllInvoices();
      final invoices = invoiceModels.map((model) => model.toEntity()).toList();
      return Right(invoices);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener facturas: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Invoice>> getInvoiceById(String id) async {
    try {
      final invoiceModel = await remoteDataSource.getInvoiceById(id);
      return Right(invoiceModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al obtener la factura: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Invoice>> createInvoice(
    CreateInvoiceParams params,
  ) async {
    try {
      final invoiceModel = await remoteDataSource.createInvoice(params);
      return Right(invoiceModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al crear la factura: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Invoice>> cancelInvoice(String id) async {
    try {
      final invoiceModel = await remoteDataSource.cancelInvoice(id);
      return Right(invoiceModel.toEntity());
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ValidationException catch (e) {
      return Left(
        ValidationFailure(
          'Error de validación: ${e.message}',
          code: 'VALIDATION_ERROR',
        ),
      );
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al anular la factura: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }
}
