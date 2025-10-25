import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/client.dart';

/// Clients repository interface defining the contract for clients data operations
abstract class ClientsRepository {
  /// Get all clients with optional pagination
  ///
  /// [page] - The page number (0-based)
  /// [limit] - The number of items per page
  /// [search] - Optional search query to filter clients by name, phone, email or address
  ///
  /// Returns a list of clients or a failure
  Future<Either<Failure, List<Client>>> getAllClients({
    int page = 0,
    int limit = 20,
    String? search,
  });

  /// Get a specific client by its ID
  ///
  /// [id] - The unique identifier of the client
  ///
  /// Returns the client or a failure
  Future<Either<Failure, Client>> getClientById(String id);

  /// Search clients by name, phone, email or address
  ///
  /// [query] - The search query to filter clients
  /// [page] - The page number (0-based)
  /// [limit] - The number of items per page
  ///
  /// Returns a list of matching clients or a failure
  Future<Either<Failure, List<Client>>> searchClients(
    String query, {
    int page = 0,
    int limit = 20,
  });

  /// Get total count of clients (for pagination)
  ///
  /// [search] - Optional search query to count filtered results
  ///
  /// Returns the total count or a failure
  Future<Either<Failure, int>> getClientsCount({String? search});

  /// Create a new client
  ///
  /// [clientData] - Map containing the client information (nombre is required)
  ///
  /// Returns the created client or a failure
  Future<Either<Failure, Client>> createClient(Map<String, dynamic> clientData);

  /// Update a client's information
  ///
  /// [id] - The unique identifier of the client to update
  /// [updatedData] - Map containing the fields to update
  ///
  /// Returns the updated client or a failure
  Future<Either<Failure, Client>> updateClient(
      String id, Map<String, dynamic> updatedData);

  /// Delete a client (soft delete - sets isActive to false)
  ///
  /// [id] - The unique identifier of the client to delete
  ///
  /// Returns void or a failure
  Future<Either<Failure, void>> deleteClient(String id);
}
