import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/products_repository.dart';
import '../datasources/products_remote_datasource.dart';

/// Implementation of ProductsRepository interface
/// Handles mapping between data layer and domain layer
class ProductsRepositoryImpl implements ProductsRepository {
  final ProductsRemoteDataSource remoteDataSource;

  ProductsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Product>>> getAllProducts({
    int page = 0,
    int limit = 20,
    String? search,
  }) async {
    try {
      final productModels = await remoteDataSource.getAllProducts(
        page: page,
        limit: limit,
        search: search,
      );
      
      final products = productModels.map((model) => model.toEntity()).toList();
      return Right(products);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      print('❌ Repository: NotFoundException caught - ${e.message}');
      return Left(ServerFailure.notFound('❌ REPOSITORY: ${e.message}'));
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
      return Left(UnexpectedFailure('Error inesperado al obtener productos: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID del producto es requerido'));
      }

      final productModel = await remoteDataSource.getProductById(id.trim());
      return Right(productModel.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      print('❌ Repository: NotFoundException caught - ${e.message}');
      return Left(ServerFailure.notFound('❌ REPOSITORY: ${e.message}'));
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
      return Left(UnexpectedFailure('Error inesperado al obtener producto: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Product>>> searchProducts(
    String query, {
    int page = 0,
    int limit = 20,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return Left(ValidationFailure.required('consulta', 'La consulta de búsqueda es requerida'));
      }

      final productModels = await remoteDataSource.searchProducts(
        query.trim(),
        page: page,
        limit: limit,
      );
      
      final products = productModels.map((model) => model.toEntity()).toList();
      return Right(products);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      print('❌ Repository: NotFoundException caught - ${e.message}');
      return Left(ServerFailure.notFound('❌ REPOSITORY: ${e.message}'));
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
      return Left(UnexpectedFailure('Error inesperado en la búsqueda: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getProductsCount({String? search}) async {
    try {
      final count = await remoteDataSource.getProductsCount(search: search);
      return Right(count);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      print('❌ Repository: NotFoundException caught - ${e.message}');
      return Left(ServerFailure.notFound('❌ REPOSITORY: ${e.message}'));
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
      return Left(UnexpectedFailure('Error inesperado al obtener conteo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> productExistsByBarcode(String barcode) async {
    try {
      if (barcode.trim().isEmpty) {
        return Left(ValidationFailure.required('código de barras', 'El código de barras es requerido'));
      }

      final exists = await remoteDataSource.productExistsByBarcode(barcode.trim());
      return Right(exists);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      print('❌ Repository: NotFoundException caught - ${e.message}');
      return Left(ServerFailure.notFound('❌ REPOSITORY: ${e.message}'));
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
      return Left(UnexpectedFailure('Error inesperado al verificar código de barras: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct(String id, Map<String, dynamic> updatedData) async {
    try {
      if (id.trim().isEmpty) {
        return Left(ValidationFailure.required('ID', 'El ID del producto es requerido'));
      }

      if (updatedData.isEmpty) {
        return Left(ValidationFailure.required('datos', 'Los datos de actualización son requeridos'));
      }

      final productModel = await remoteDataSource.updateProduct(id.trim(), updatedData);
      return Right(productModel.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      print('❌ Repository: NotFoundException caught - ${e.message}');
      return Left(ServerFailure.notFound('❌ REPOSITORY: ${e.message}'));
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
      return Left(UnexpectedFailure('Error inesperado al actualizar producto: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Product>> createProduct(Map<String, dynamic> productData) async {
    try {
      if (productData.isEmpty) {
        return Left(ValidationFailure.required('datos', 'Los datos del producto son requeridos'));
      }

      if (!productData.containsKey('description') || (productData['description'] as String).trim().isEmpty) {
        return Left(ValidationFailure.required('descripción', 'La descripción del producto es requerida'));
      }

      if (!productData.containsKey('barcode')) {
        return Left(ValidationFailure.required('código de barras', 'El código de barras es requerido'));
      }

      if (!productData.containsKey('precioA')) {
        return Left(ValidationFailure.required('precio', 'El precio del producto es requerido'));
      }

      final productModel = await remoteDataSource.createProduct(productData);
      return Right(productModel.toEntity());
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      print('❌ Repository: NotFoundException caught - ${e.message}');
      return Left(ServerFailure.notFound('❌ REPOSITORY: ${e.message}'));
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
      return Left(UnexpectedFailure('Error inesperado al crear producto: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createTemporaryProduct(Map<String, dynamic> temporaryProductData) async {
    try {
      if (temporaryProductData.isEmpty) {
        return Left(ValidationFailure.required('datos', 'Los datos del producto temporal son requeridos'));
      }

      if (!temporaryProductData.containsKey('name') || (temporaryProductData['name'] as String).trim().isEmpty) {
        return Left(ValidationFailure.required('nombre', 'El nombre del producto es requerido'));
      }

      if (!temporaryProductData.containsKey('createdBy')) {
        return Left(ValidationFailure.required('usuario', 'El ID del usuario es requerido'));
      }

      final response = await remoteDataSource.createTemporaryProduct(temporaryProductData);
      return Right(response);
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
      return Left(UnexpectedFailure('Error inesperado al crear producto temporal: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAllTemporaryProducts() async {
    try {
      final response = await remoteDataSource.getAllTemporaryProducts();
      return Right(response);
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
      return Left(UnexpectedFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getTemporaryProductById(String id) async {
    try {
      final response = await remoteDataSource.getTemporaryProductById(id);
      return Right(response);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateTemporaryProduct(String id, Map<String, dynamic> updateData) async {
    try {
      final response = await remoteDataSource.updateTemporaryProduct(id, updateData);
      return Right(response);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> cancelTemporaryProduct(String id, {String? reason}) async {
    try {
      final response = await remoteDataSource.cancelTemporaryProduct(id, reason: reason);
      return Right(response);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Error inesperado: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> completeTemporaryProductBySupervisor(String id, {String? notes}) async {
    try {
      final response = await remoteDataSource.completeTemporaryProductBySupervisor(id, notes: notes);
      return Right(response);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(ServerFailure.notFound(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Error inesperado: ${e.toString()}'));
    }
  }
}