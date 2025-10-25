// lib/features/orders/domain/usecases/create_order_usecase.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/order.dart' as order_entity;
import '../repositories/orders_repository.dart';

/// Use case for creating a new order
class CreateOrderUseCase {
  final OrdersRepository repository;

  CreateOrderUseCase(this.repository);

  /// Execute the use case to create an order
  ///
  /// [params] - Parameters containing order details and items
  ///
  /// Returns the created order or a failure
  Future<Either<Failure, order_entity.Order>> call(
    CreateOrderParams params,
  ) async {
    try {
      // Validate input parameters
      final validationFailure = _validateParams(params);
      if (validationFailure != null) {
        return Left(validationFailure);
      }

      return await repository.createOrder(params);
    } catch (e) {
      return Left(
        UnexpectedFailure(
          'Error inesperado al crear el pedido: ${e.toString()}',
          exception: e is Exception ? e : Exception(e.toString()),
        ),
      );
    }
  }

  /// Validate create order parameters
  ValidationFailure? _validateParams(CreateOrderParams params) {
    if (params.description.trim().isEmpty) {
      return ValidationFailure.required(
        'Descripción',
        'La descripción del pedido es requerida',
      );
    }

    if (params.description.trim().length < 3) {
      return ValidationFailure.minLength(
        'Descripción',
        3,
        'La descripción debe tener al menos 3 caracteres',
      );
    }

    if (params.description.trim().length > 255) {
      return ValidationFailure.maxLength(
        'Descripción',
        255,
        'La descripción no puede superar los 255 caracteres',
      );
    }

    if (params.items.isEmpty) {
      return ValidationFailure.required(
        'Artículos',
        'El pedido debe tener al menos un artículo',
      );
    }

    // Validate each item
    for (int i = 0; i < params.items.length; i++) {
      final item = params.items[i];

      // At least one product ID must be present (either productId or temporaryProductId)
      if ((item.productId == null || item.productId!.trim().isEmpty) &&
          (item.temporaryProductId == null || item.temporaryProductId!.trim().isEmpty)) {
        return ValidationFailure.required(
          'Producto ${i + 1}',
          'El ID del producto o producto temporal es requerido',
        );
      }

      if (item.existingQuantity < 0) {
        return ValidationFailure(
          'La cantidad existente ${i + 1} debe ser mayor o igual a 0',
          code: 'INVALID_EXISTING_QUANTITY',
        );
      }

      if (item.requestedQuantity != null && item.requestedQuantity! < 0) {
        return ValidationFailure(
          'La cantidad solicitada ${i + 1} debe ser mayor o igual a 0',
          code: 'INVALID_REQUESTED_QUANTITY',
        );
      }

      if (item.measurementUnit.trim().isEmpty) {
        return ValidationFailure.required(
          'Unidad de medida ${i + 1}',
          'La unidad de medida es requerida',
        );
      }
    }

    // Check for duplicate products (considering both regular and temporary products)
    final productIdentifiers = params.items.map((item) {
      // Use temporaryProductId if present, otherwise productId
      return item.temporaryProductId ?? item.productId ?? '';
    }).toList();

    final uniqueIdentifiers = productIdentifiers.toSet();
    if (productIdentifiers.length != uniqueIdentifiers.length) {
      return const ValidationFailure(
        'No se pueden agregar productos duplicados al pedido',
        code: 'DUPLICATE_PRODUCTS',
      );
    }

    return null;
  }
}
