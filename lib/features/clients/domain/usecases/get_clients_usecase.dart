import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/client.dart';
import '../repositories/clients_repository.dart';

/// Parameters for the get clients use case
class GetClientsParams {
  final int page;
  final int limit;
  final String? search;

  const GetClientsParams({
    this.page = 0,
    this.limit = 20,
    this.search,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetClientsParams &&
        other.page == page &&
        other.limit == limit &&
        other.search == search;
  }

  @override
  int get hashCode => page.hashCode ^ limit.hashCode ^ search.hashCode;

  @override
  String toString() {
    return 'GetClientsParams(page: $page, limit: $limit, search: $search)';
  }

  GetClientsParams copyWith({
    int? page,
    int? limit,
    String? search,
  }) {
    return GetClientsParams(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
    );
  }
}

/// Use case for getting clients with pagination and search functionality
class GetClientsUseCase {
  final ClientsRepository repository;

  GetClientsUseCase(this.repository);

  /// Execute the use case to get clients
  ///
  /// [params] - Optional parameters for pagination and search
  ///
  /// Returns a list of clients or a failure
  Future<Either<Failure, List<Client>>> call([GetClientsParams? params]) async {
    final parameters = params ?? const GetClientsParams();

    try {
      if (parameters.search != null && parameters.search!.trim().isNotEmpty) {
        // Use search functionality if search query is provided
        return await repository.searchClients(
          parameters.search!.trim(),
          page: parameters.page,
          limit: parameters.limit,
        );
      } else {
        // Get all clients with pagination
        return await repository.getAllClients(
          page: parameters.page,
          limit: parameters.limit,
        );
      }
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener clientes: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }

  /// Get clients count for pagination
  Future<Either<Failure, int>> getCount([String? search]) async {
    try {
      return await repository.getClientsCount(search: search);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener el conteo de clientes: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

/// Parameters for getting a single client by ID
class GetClientByIdParams {
  final String id;

  const GetClientByIdParams({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetClientByIdParams && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GetClientByIdParams(id: $id)';
  }
}

/// Use case for getting a single client by ID
class GetClientByIdUseCase {
  final ClientsRepository repository;

  GetClientByIdUseCase(this.repository);

  /// Execute the use case to get a client by ID
  ///
  /// [params] - Parameters containing the client ID
  ///
  /// Returns the client or a failure
  Future<Either<Failure, Client>> call(GetClientByIdParams params) async {
    try {
      if (params.id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID del cliente es requerido'));
      }

      return await repository.getClientById(params.id.trim());
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener el cliente: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}
