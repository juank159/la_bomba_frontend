// lib/features/credits/domain/usecases/payment_method_usecases.dart

import 'package:dartz/dartz.dart';
import '../../../../app/core/errors/failures.dart';
import '../entities/payment_method.dart';
import '../repositories/payment_method_repository.dart';

// ====================== GET ALL PAYMENT METHODS USE CASE ======================

/// Use case for getting all payment methods
class GetAllPaymentMethodsUseCase {
  final PaymentMethodRepository repository;

  GetAllPaymentMethodsUseCase(this.repository);

  /// Execute the use case to get all payment methods
  ///
  /// Returns a list of payment methods or a failure
  Future<Either<Failure, List<PaymentMethod>>> call() async {
    try {
      return await repository.getAllPaymentMethods();
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener métodos de pago: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

// ====================== GET PAYMENT METHOD BY ID USE CASE ======================

/// Parameters for getting a single payment method by ID
class GetPaymentMethodByIdParams {
  final String id;

  const GetPaymentMethodByIdParams({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetPaymentMethodByIdParams && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GetPaymentMethodByIdParams(id: $id)';
}

/// Use case for getting a payment method by ID
class GetPaymentMethodByIdUseCase {
  final PaymentMethodRepository repository;

  GetPaymentMethodByIdUseCase(this.repository);

  /// Execute the use case to get a payment method by ID
  ///
  /// Returns a payment method or a failure
  Future<Either<Failure, PaymentMethod>> call(
    GetPaymentMethodByIdParams params,
  ) async {
    try {
      return await repository.getPaymentMethodById(params.id);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener método de pago: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

// ====================== CREATE PAYMENT METHOD USE CASE ======================

/// Parameters for creating a payment method
class CreatePaymentMethodParams {
  final String name;
  final String? description;
  final String? icon;

  const CreatePaymentMethodParams({
    required this.name,
    this.description,
    this.icon,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreatePaymentMethodParams &&
        other.name == name &&
        other.description == description &&
        other.icon == icon;
  }

  @override
  int get hashCode => Object.hash(name, description, icon);

  @override
  String toString() =>
      'CreatePaymentMethodParams(name: $name, description: $description, icon: $icon)';
}

/// Use case for creating a payment method
class CreatePaymentMethodUseCase {
  final PaymentMethodRepository repository;

  CreatePaymentMethodUseCase(this.repository);

  /// Execute the use case to create a payment method
  ///
  /// Returns the created payment method or a failure
  Future<Either<Failure, PaymentMethod>> call(
    CreatePaymentMethodParams params,
  ) async {
    try {
      return await repository.createPaymentMethod(
        name: params.name,
        description: params.description,
        icon: params.icon,
      );
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al crear método de pago: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

// ====================== UPDATE PAYMENT METHOD USE CASE ======================

/// Parameters for updating a payment method
class UpdatePaymentMethodParams {
  final String id;
  final String? name;
  final String? description;
  final String? icon;

  const UpdatePaymentMethodParams({
    required this.id,
    this.name,
    this.description,
    this.icon,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdatePaymentMethodParams &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.icon == icon;
  }

  @override
  int get hashCode => Object.hash(id, name, description, icon);

  @override
  String toString() =>
      'UpdatePaymentMethodParams(id: $id, name: $name, description: $description, icon: $icon)';
}

/// Use case for updating a payment method
class UpdatePaymentMethodUseCase {
  final PaymentMethodRepository repository;

  UpdatePaymentMethodUseCase(this.repository);

  /// Execute the use case to update a payment method
  ///
  /// Returns the updated payment method or a failure
  Future<Either<Failure, PaymentMethod>> call(
    UpdatePaymentMethodParams params,
  ) async {
    try {
      return await repository.updatePaymentMethod(
        id: params.id,
        name: params.name,
        description: params.description,
        icon: params.icon,
      );
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al actualizar método de pago: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

// ====================== DELETE PAYMENT METHOD USE CASE ======================

/// Parameters for deleting a payment method
class DeletePaymentMethodParams {
  final String id;

  const DeletePaymentMethodParams({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeletePaymentMethodParams && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DeletePaymentMethodParams(id: $id)';
}

/// Use case for deleting a payment method
class DeletePaymentMethodUseCase {
  final PaymentMethodRepository repository;

  DeletePaymentMethodUseCase(this.repository);

  /// Execute the use case to delete a payment method
  ///
  /// Returns success or a failure
  Future<Either<Failure, void>> call(DeletePaymentMethodParams params) async {
    try {
      return await repository.deletePaymentMethod(params.id);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al eliminar método de pago: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

// ====================== ACTIVATE PAYMENT METHOD USE CASE ======================

/// Parameters for activating/deactivating a payment method
class ActivatePaymentMethodParams {
  final String id;
  final bool isActive;

  const ActivatePaymentMethodParams({
    required this.id,
    required this.isActive,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivatePaymentMethodParams &&
        other.id == id &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(id, isActive);

  @override
  String toString() =>
      'ActivatePaymentMethodParams(id: $id, isActive: $isActive)';
}

/// Use case for activating/deactivating a payment method
class ActivatePaymentMethodUseCase {
  final PaymentMethodRepository repository;

  ActivatePaymentMethodUseCase(this.repository);

  /// Execute the use case to activate or deactivate a payment method
  ///
  /// Returns the updated payment method or a failure
  Future<Either<Failure, PaymentMethod>> call(
    ActivatePaymentMethodParams params,
  ) async {
    try {
      return await repository.activatePaymentMethod(
        id: params.id,
        isActive: params.isActive,
      );
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al cambiar estado del método de pago: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}
