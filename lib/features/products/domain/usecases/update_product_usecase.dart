// lib/features/products/domain/usecases/update_product_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/product.dart';
import '../repositories/products_repository.dart';

/// Use case for updating a product's information
class UpdateProductUseCase {
  final ProductsRepository repository;

  UpdateProductUseCase(this.repository);

  /// Execute the use case to update a product
  /// 
  /// [params] - Parameters containing the product ID and updated data
  /// 
  /// Returns the updated product or a failure
  Future<Either<Failure, Product>> call(UpdateProductParams params) async {
    // Validate parameters
    if (params.id.trim().isEmpty) {
      return Left(
        ValidationFailure.required('ID', 'El ID del producto es requerido'),
      );
    }

    if (params.updatedData.isEmpty) {
      return Left(
        ValidationFailure.required(
          'datos',
          'Los datos de actualización son requeridos',
        ),
      );
    }

    // Validate price fields if they are being updated
    final Map<String, dynamic> validatedData = Map.from(params.updatedData);

    // Validate precioA (required if being updated)
    if (validatedData.containsKey('precioA')) {
      final precioA = validatedData['precioA'];
      if (precioA == null || (precioA is num && precioA <= 0)) {
        return Left(
          ValidationFailure.required(
            'precio público',
            'El precio público debe ser mayor a cero',
          ),
        );
      }
    }

    // Validate precioB (optional)
    if (validatedData.containsKey('precioB')) {
      final precioB = validatedData['precioB'];
      if (precioB != null && precioB is num && precioB < 0) {
        return Left(
          ValidationFailure('El precio mayorista no puede ser negativo'),
        );
      }
    }

    // Validate precioC (optional)
    if (validatedData.containsKey('precioC')) {
      final precioC = validatedData['precioC'];
      if (precioC != null && precioC is num && precioC < 0) {
        return Left(
          ValidationFailure('El precio super mayorista no puede ser negativo'),
        );
      }
    }

    // Validate costo (optional)
    if (validatedData.containsKey('costo')) {
      final costo = validatedData['costo'];
      if (costo != null && costo is num && costo < 0) {
        return Left(ValidationFailure('El costo no puede ser negativo'));
      }
    }

    // Validate IVA (optional)
    if (validatedData.containsKey('iva')) {
      final iva = validatedData['iva'];
      if (iva != null && iva is num && (iva < 0 || iva > 100)) {
        return Left(ValidationFailure('El IVA debe estar entre 0 y 100'));
      }
    }

    // TypeORM handles updatedAt automatically, no need to add it manually

    return await repository.updateProduct(params.id, validatedData);
  }
}

/// Parameters for UpdateProductUseCase
class UpdateProductParams {
  final String id;
  final Map<String, dynamic> updatedData;

  const UpdateProductParams({
    required this.id, 
    required this.updatedData,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateProductParams &&
        other.id == id &&
        _mapEquals(other.updatedData, updatedData);
  }

  @override
  int get hashCode => id.hashCode ^ updatedData.hashCode;

  @override
  String toString() {
    return 'UpdateProductParams(id: $id, updatedData: $updatedData)';
  }

  /// Helper method to compare maps
  bool _mapEquals(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (var key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) return false;
    }
    return true;
  }
}
