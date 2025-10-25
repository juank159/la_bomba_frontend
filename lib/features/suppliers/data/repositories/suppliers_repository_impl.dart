import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/repositories/suppliers_repository.dart';
import '../datasources/suppliers_remote_datasource.dart';

/// Implementation of SuppliersRepository interface
/// Handles mapping between data layer and domain layer
class SuppliersRepositoryImpl implements SuppliersRepository {
  final SuppliersRemoteDataSource remoteDataSource;

  SuppliersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Supplier>>> getAllSuppliers({
    int page = 0,
    int limit = 20,
    String? search,
  }) async {
    try {
      final supplierModels = await remoteDataSource.getAllSuppliers(
        page: page,
        limit: limit,
        search: search,
      );

      final suppliers = supplierModels.map((model) => model.toEntity()).toList();
      return Right(suppliers);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure.unauthorized(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on BadRequestException catch (e) {
      return Left(ServerFailure.badRequest(e.message));
    } on ConflictException catch (e) {
      return Left(ServerFailure.conflict(e.message));
    } on InternalServerException catch (e) {
      return Left(ServerFailure.internalServer(e.message));
    } on BadGatewayException catch (e) {
      return Left(ServerFailure.badGateway(e.message));
    } on ServiceUnavailableException catch (e) {
      return Left(ServerFailure.serviceUnavailable(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionTimeoutException catch (e) {
      return Left(NetworkFailure.connectionTimeout(e.message));
    } on ConnectionException catch (e) {
      return Left(NetworkFailure.connectionError(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure.json(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(
          'Error inesperado al obtener proveedores: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Supplier>> getSupplierById(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'ID', 'El ID del proveedor es requerido'));
      }

      final supplierModel = await remoteDataSource.getSupplierById(id.trim());
      return Right(supplierModel.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure.unauthorized(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on BadRequestException catch (e) {
      return Left(ServerFailure.badRequest(e.message));
    } on ConflictException catch (e) {
      return Left(ServerFailure.conflict(e.message));
    } on InternalServerException catch (e) {
      return Left(ServerFailure.internalServer(e.message));
    } on BadGatewayException catch (e) {
      return Left(ServerFailure.badGateway(e.message));
    } on ServiceUnavailableException catch (e) {
      return Left(ServerFailure.serviceUnavailable(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionTimeoutException catch (e) {
      return Left(NetworkFailure.connectionTimeout(e.message));
    } on ConnectionException catch (e) {
      return Left(NetworkFailure.connectionError(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure.json(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(
          'Error inesperado al obtener proveedor: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Supplier>>> searchSuppliers(
    String query, {
    int page = 0,
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'búsqueda', 'El término de búsqueda es requerido'));
      }

      final supplierModels = await remoteDataSource.searchSuppliers(
        query.trim(),
        page: page,
        limit: limit,
      );

      final suppliers = supplierModels.map((model) => model.toEntity()).toList();
      return Right(suppliers);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure.unauthorized(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on BadRequestException catch (e) {
      return Left(ServerFailure.badRequest(e.message));
    } on ConflictException catch (e) {
      return Left(ServerFailure.conflict(e.message));
    } on InternalServerException catch (e) {
      return Left(ServerFailure.internalServer(e.message));
    } on BadGatewayException catch (e) {
      return Left(ServerFailure.badGateway(e.message));
    } on ServiceUnavailableException catch (e) {
      return Left(ServerFailure.serviceUnavailable(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionTimeoutException catch (e) {
      return Left(NetworkFailure.connectionTimeout(e.message));
    } on ConnectionException catch (e) {
      return Left(NetworkFailure.connectionError(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure.json(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(
          'Error inesperado al buscar proveedores: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getSuppliersCount({String? search}) async {
    try {
      final count = await remoteDataSource.getSuppliersCount(search: search);
      return Right(count);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure.unauthorized(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on BadRequestException catch (e) {
      return Left(ServerFailure.badRequest(e.message));
    } on ConflictException catch (e) {
      return Left(ServerFailure.conflict(e.message));
    } on InternalServerException catch (e) {
      return Left(ServerFailure.internalServer(e.message));
    } on BadGatewayException catch (e) {
      return Left(ServerFailure.badGateway(e.message));
    } on ServiceUnavailableException catch (e) {
      return Left(ServerFailure.serviceUnavailable(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionTimeoutException catch (e) {
      return Left(NetworkFailure.connectionTimeout(e.message));
    } on ConnectionException catch (e) {
      return Left(NetworkFailure.connectionError(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure.json(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(
          'Error inesperado al obtener conteo de proveedores: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Supplier>> createSupplier(
      Map<String, dynamic> supplierData) async {
    try {
      if (supplierData.isEmpty) {
        return Left(ValidationFailure.required(
            'datos', 'Los datos del proveedor son requeridos'));
      }

      if (!supplierData.containsKey('nombre') ||
          (supplierData['nombre'] as String).trim().isEmpty) {
        return Left(ValidationFailure.required(
            'nombre', 'El nombre del proveedor es obligatorio'));
      }

      final supplierModel = await remoteDataSource.createSupplier(supplierData);
      return Right(supplierModel.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure.unauthorized(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on BadRequestException catch (e) {
      return Left(ServerFailure.badRequest(e.message));
    } on ConflictException catch (e) {
      return Left(ServerFailure.conflict(e.message));
    } on InternalServerException catch (e) {
      return Left(ServerFailure.internalServer(e.message));
    } on BadGatewayException catch (e) {
      return Left(ServerFailure.badGateway(e.message));
    } on ServiceUnavailableException catch (e) {
      return Left(ServerFailure.serviceUnavailable(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionTimeoutException catch (e) {
      return Left(NetworkFailure.connectionTimeout(e.message));
    } on ConnectionException catch (e) {
      return Left(NetworkFailure.connectionError(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure.json(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(
          'Error inesperado al crear proveedor: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Supplier>> updateSupplier(
      String id, Map<String, dynamic> updatedData) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'ID', 'El ID del proveedor es requerido'));
      }

      if (updatedData.isEmpty) {
        return Left(ValidationFailure.required('datos',
            'Los datos de actualización son requeridos'));
      }

      final supplierModel =
          await remoteDataSource.updateSupplier(id.trim(), updatedData);
      return Right(supplierModel.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure.unauthorized(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on BadRequestException catch (e) {
      return Left(ServerFailure.badRequest(e.message));
    } on ConflictException catch (e) {
      return Left(ServerFailure.conflict(e.message));
    } on InternalServerException catch (e) {
      return Left(ServerFailure.internalServer(e.message));
    } on BadGatewayException catch (e) {
      return Left(ServerFailure.badGateway(e.message));
    } on ServiceUnavailableException catch (e) {
      return Left(ServerFailure.serviceUnavailable(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionTimeoutException catch (e) {
      return Left(NetworkFailure.connectionTimeout(e.message));
    } on ConnectionException catch (e) {
      return Left(NetworkFailure.connectionError(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure.json(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(
          'Error inesperado al actualizar proveedor: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSupplier(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'ID', 'El ID del proveedor es requerido'));
      }

      await remoteDataSource.deleteSupplier(id.trim());
      return const Right(null);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on UnauthorizedException catch (e) {
      return Left(ServerFailure.unauthorized(e.message));
    } on ForbiddenException catch (e) {
      return Left(ServerFailure.forbidden(e.message));
    } on BadRequestException catch (e) {
      return Left(ServerFailure.badRequest(e.message));
    } on ConflictException catch (e) {
      return Left(ServerFailure.conflict(e.message));
    } on InternalServerException catch (e) {
      return Left(ServerFailure.internalServer(e.message));
    } on BadGatewayException catch (e) {
      return Left(ServerFailure.badGateway(e.message));
    } on ServiceUnavailableException catch (e) {
      return Left(ServerFailure.serviceUnavailable(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on ConnectionTimeoutException catch (e) {
      return Left(NetworkFailure.connectionTimeout(e.message));
    } on ConnectionException catch (e) {
      return Left(NetworkFailure.connectionError(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ParseException catch (e) {
      return Left(ParseFailure.json(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(
          'Error inesperado al eliminar proveedor: ${e.toString()}'));
    }
  }
}
