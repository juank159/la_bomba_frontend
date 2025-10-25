import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/product.dart';

/// Products repository interface defining the contract for products data operations
abstract class ProductsRepository {
  /// Get all products with optional pagination
  /// 
  /// [page] - The page number (0-based)
  /// [limit] - The number of items per page
  /// [search] - Optional search query to filter products by description or barcode
  /// 
  /// Returns a list of products or a failure
  Future<Either<Failure, List<Product>>> getAllProducts({
    int page = 0,
    int limit = 20,
    String? search,
  });

  /// Get a specific product by its ID
  /// 
  /// [id] - The unique identifier of the product
  /// 
  /// Returns the product or a failure
  Future<Either<Failure, Product>> getProductById(String id);

  /// Search products by description or barcode
  /// 
  /// [query] - The search query to filter products
  /// [page] - The page number (0-based)  
  /// [limit] - The number of items per page
  /// 
  /// Returns a list of matching products or a failure
  Future<Either<Failure, List<Product>>> searchProducts(
    String query, {
    int page = 0,
    int limit = 20,
  });

  /// Get total count of products (for pagination)
  /// 
  /// [search] - Optional search query to count filtered results
  /// 
  /// Returns the total count or a failure
  Future<Either<Failure, int>> getProductsCount({String? search});

  /// Check if a product with the given barcode exists
  /// 
  /// [barcode] - The barcode to check
  /// 
  /// Returns true if exists, false otherwise, or a failure
  Future<Either<Failure, bool>> productExistsByBarcode(String barcode);

  /// Update a product's information
  ///
  /// [id] - The unique identifier of the product to update
  /// [updatedData] - Map containing the fields to update
  ///
  /// Returns the updated product or a failure
  Future<Either<Failure, Product>> updateProduct(String id, Map<String, dynamic> updatedData);

  /// Create a new product
  ///
  /// [productData] - Map containing the product data (description, barcode, precioA, etc.)
  ///
  /// Returns the created product or a failure
  Future<Either<Failure, Product>> createProduct(Map<String, dynamic> productData);

  /// Create a temporary product (not yet registered)
  ///
  /// [temporaryProductData] - Map containing temporary product data (name, notes, createdBy)
  ///
  /// Returns the created temporary product data or a failure
  Future<Either<Failure, Map<String, dynamic>>> createTemporaryProduct(Map<String, dynamic> temporaryProductData);

  /// Get all temporary products
  ///
  /// Returns a list of temporary products or a failure
  Future<Either<Failure, List<Map<String, dynamic>>>> getAllTemporaryProducts();

  /// Get a specific temporary product by ID
  ///
  /// [id] - The unique identifier of the temporary product
  ///
  /// Returns the temporary product or a failure
  Future<Either<Failure, Map<String, dynamic>>> getTemporaryProductById(String id);

  /// Update a temporary product (add prices/IVA)
  ///
  /// [id] - The unique identifier of the temporary product
  /// [updateData] - Map containing the fields to update (precioA, iva, etc.)
  ///
  /// Returns the updated temporary product or a failure
  Future<Either<Failure, Map<String, dynamic>>> updateTemporaryProduct(String id, Map<String, dynamic> updateData);

  /// Cancel a temporary product (mark as "did not arrive")
  ///
  /// [id] - The unique identifier of the temporary product
  /// [reason] - Optional reason for cancellation
  ///
  /// Returns the cancelled temporary product or a failure
  Future<Either<Failure, Map<String, dynamic>>> cancelTemporaryProduct(String id, {String? reason});

  /// Complete a temporary product by supervisor (mark as applied in external system)
  ///
  /// [id] - The unique identifier of the temporary product
  /// [notes] - Optional notes from supervisor
  ///
  /// Returns the completed temporary product or a failure
  Future<Either<Failure, Map<String, dynamic>>> completeTemporaryProductBySupervisor(String id, {String? notes});
}