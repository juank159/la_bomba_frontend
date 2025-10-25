import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/client.dart';
import '../../domain/repositories/clients_repository.dart';
import '../datasources/clients_remote_datasource.dart';

/// Implementation of ClientsRepository interface
/// Handles mapping between data layer and domain layer
class ClientsRepositoryImpl implements ClientsRepository {
  final ClientsRemoteDataSource remoteDataSource;

  ClientsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Client>>> getAllClients({
    int page = 0,
    int limit = 20,
    String? search,
  }) async {
    try {
      final clientModels = await remoteDataSource.getAllClients(
        page: page,
        limit: limit,
        search: search,
      );

      final clients = clientModels.map((model) => model.toEntity()).toList();
      return Right(clients);
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
          'Error inesperado al obtener clientes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Client>> getClientById(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'ID', 'El ID del cliente es requerido'));
      }

      final clientModel = await remoteDataSource.getClientById(id.trim());
      return Right(clientModel.toEntity());
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
          'Error inesperado al obtener cliente: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Client>>> searchClients(
    String query, {
    int page = 0,
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'búsqueda', 'El término de búsqueda es requerido'));
      }

      final clientModels = await remoteDataSource.searchClients(
        query.trim(),
        page: page,
        limit: limit,
      );

      final clients = clientModels.map((model) => model.toEntity()).toList();
      return Right(clients);
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
          'Error inesperado al buscar clientes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getClientsCount({String? search}) async {
    try {
      final count = await remoteDataSource.getClientsCount(search: search);
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
          'Error inesperado al obtener conteo de clientes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Client>> createClient(
      Map<String, dynamic> clientData) async {
    try {
      if (clientData.isEmpty) {
        return Left(ValidationFailure.required(
            'datos', 'Los datos del cliente son requeridos'));
      }

      if (!clientData.containsKey('nombre') ||
          (clientData['nombre'] as String).trim().isEmpty) {
        return Left(ValidationFailure.required(
            'nombre', 'El nombre del cliente es obligatorio'));
      }

      final clientModel = await remoteDataSource.createClient(clientData);
      return Right(clientModel.toEntity());
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
          'Error inesperado al crear cliente: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Client>> updateClient(
      String id, Map<String, dynamic> updatedData) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'ID', 'El ID del cliente es requerido'));
      }

      if (updatedData.isEmpty) {
        return Left(ValidationFailure.required('datos',
            'Los datos de actualización son requeridos'));
      }

      final clientModel =
          await remoteDataSource.updateClient(id.trim(), updatedData);
      return Right(clientModel.toEntity());
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
          'Error inesperado al actualizar cliente: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteClient(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required(
            'ID', 'El ID del cliente es requerido'));
      }

      await remoteDataSource.deleteClient(id.trim());
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
          'Error inesperado al eliminar cliente: ${e.toString()}'));
    }
  }
}
