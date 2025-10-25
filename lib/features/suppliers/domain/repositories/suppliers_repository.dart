import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/supplier.dart';

/// Suppliers repository interface defining the contract for suppliers data operations
abstract class SuppliersRepository {
  /// Get all suppliers with optional pagination
  ///
  /// [page] - The page number (0-based)
  /// [limit] - The number of items per page
  /// [search] - Optional search query to filter suppliers by name, phone, email or address
  ///
  /// Returns a list of suppliers or a failure
  Future<Either<Failure, List<Supplier>>> getAllSuppliers({
    int page = 0,
    int limit = 20,
    String? search,
  });

  /// Get a specific supplier by its ID
  ///
  /// [id] - The unique identifier of the supplier
  ///
  /// Returns the supplier or a failure
  Future<Either<Failure, Supplier>> getSupplierById(String id);

  /// Search suppliers by name, phone, email or address
  ///
  /// [query] - The search query to filter suppliers
  /// [page] - The page number (0-based)
  /// [limit] - The number of items per page
  ///
  /// Returns a list of matching suppliers or a failure
  Future<Either<Failure, List<Supplier>>> searchSuppliers(
    String query, {
    int page = 0,
    int limit = 20,
  });

  /// Get total count of suppliers (for pagination)
  ///
  /// [search] - Optional search query to count filtered results
  ///
  /// Returns the total count or a failure
  Future<Either<Failure, int>> getSuppliersCount({String? search});

  /// Create a new supplier
  ///
  /// [supplierData] - Map containing the supplier information (nombre is required)
  ///
  /// Returns the created supplier or a failure
  Future<Either<Failure, Supplier>> createSupplier(Map<String, dynamic> supplierData);

  /// Update a supplier's information
  ///
  /// [id] - The unique identifier of the supplier to update
  /// [updatedData] - Map containing the fields to update
  ///
  /// Returns the updated supplier or a failure
  Future<Either<Failure, Supplier>> updateSupplier(
      String id, Map<String, dynamic> updatedData);

  /// Delete a supplier (soft delete - sets isActive to false)
  ///
  /// [id] - The unique identifier of the supplier to delete
  ///
  /// Returns void or a failure
  Future<Either<Failure, void>> deleteSupplier(String id);
}
