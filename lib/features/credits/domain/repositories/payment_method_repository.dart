// lib/features/credits/domain/repositories/payment_method_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/payment_method.dart';

/// Repositorio para operaciones de métodos de pago
abstract class PaymentMethodRepository {
  /// Obtiene todos los métodos de pago
  Future<Either<Failure, List<PaymentMethod>>> getAllPaymentMethods();

  /// Obtiene un método de pago por ID
  Future<Either<Failure, PaymentMethod>> getPaymentMethodById(String id);

  /// Crea un nuevo método de pago
  Future<Either<Failure, PaymentMethod>> createPaymentMethod({
    required String name,
    String? description,
    String? icon,
  });

  /// Actualiza un método de pago
  Future<Either<Failure, PaymentMethod>> updatePaymentMethod({
    required String id,
    String? name,
    String? description,
    String? icon,
  });

  /// Elimina un método de pago
  Future<Either<Failure, void>> deletePaymentMethod(String id);

  /// Activa o desactiva un método de pago
  Future<Either<Failure, PaymentMethod>> activatePaymentMethod({
    required String id,
    required bool isActive,
  });
}
