// lib/features/credits/domain/usecases/credits_usecases.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/credit.dart';
import '../repositories/credits_repository.dart';

// ====================== GET CREDITS USE CASE ======================

/// Use case for getting all credits
class GetCreditsUseCase {
  final CreditsRepository repository;

  GetCreditsUseCase(this.repository);

  /// Execute the use case to get all credits
  ///
  /// Returns a list of credits or a failure
  Future<Either<Failure, List<Credit>>> call() async {
    try {
      return await repository.getAllCredits();
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener créditos: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

// ====================== GET CREDIT BY ID USE CASE ======================

/// Parameters for getting a single credit by ID
class GetCreditByIdParams {
  final String id;

  const GetCreditByIdParams({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetCreditByIdParams && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GetCreditByIdParams(id: $id)';
}

/// Use case for getting a specific credit by ID with payment history
class GetCreditByIdUseCase {
  final CreditsRepository repository;

  GetCreditByIdUseCase(this.repository);

  /// Execute the use case to get a credit by ID
  ///
  /// [params] - Parameters containing the credit ID
  ///
  /// Returns the credit with payment history or a failure
  Future<Either<Failure, Credit>> call(GetCreditByIdParams params) async {
    try {
      if (params.id.trim().isEmpty) {
        return const Left(ValidationFailure('El ID del crédito es requerido'));
      }

      return await repository.getCreditById(params.id);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener crédito: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

// ====================== CREATE CREDIT USE CASE ======================

/// Parameters for creating a new credit
class CreateCreditParams {
  final String clientId;
  final String description;
  final double totalAmount;

  const CreateCreditParams({
    required this.clientId,
    required this.description,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'description': description,
      'totalAmount': totalAmount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateCreditParams &&
        other.clientId == clientId &&
        other.description == description &&
        other.totalAmount == totalAmount;
  }

  @override
  int get hashCode =>
      clientId.hashCode ^ description.hashCode ^ totalAmount.hashCode;

  @override
  String toString() {
    return 'CreateCreditParams(clientId: $clientId, description: $description, totalAmount: $totalAmount)';
  }
}

/// Use case for creating a new credit
class CreateCreditUseCase {
  final CreditsRepository repository;

  CreateCreditUseCase(this.repository);

  /// Execute the use case to create a new credit
  ///
  /// [params] - Parameters containing the credit information
  ///
  /// Returns the created credit or a failure
  Future<Either<Failure, Credit>> call(CreateCreditParams params) async {
    try {
      // Validate parameters
      if (params.clientId.trim().isEmpty) {
        return const Left(ValidationFailure('El ID del cliente es obligatorio'));
      }

      if (params.description.trim().isEmpty) {
        return const Left(ValidationFailure('La descripción es obligatoria'));
      }

      if (params.totalAmount <= 0) {
        return const Left(ValidationFailure('El monto total debe ser mayor a cero'));
      }

      return await repository.createCredit(params.toMap());
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al crear crédito: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

// ====================== UPDATE CREDIT USE CASE ======================

/// Parameters for updating a credit
class UpdateCreditParams {
  final String id;
  final String? clientId;
  final String? description;
  final double? totalAmount;

  const UpdateCreditParams({
    required this.id,
    this.clientId,
    this.description,
    this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (clientId != null) map['clientId'] = clientId;
    if (description != null) map['description'] = description;
    if (totalAmount != null) map['totalAmount'] = totalAmount;
    return map;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UpdateCreditParams &&
        other.id == id &&
        other.clientId == clientId &&
        other.description == description &&
        other.totalAmount == totalAmount;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      clientId.hashCode ^
      description.hashCode ^
      totalAmount.hashCode;

  @override
  String toString() {
    return 'UpdateCreditParams(id: $id, clientId: $clientId, description: $description, totalAmount: $totalAmount)';
  }
}

/// Use case for updating a credit
class UpdateCreditUseCase {
  final CreditsRepository repository;

  UpdateCreditUseCase(this.repository);

  /// Execute the use case to update a credit
  ///
  /// [params] - Parameters containing the credit ID and updated information
  ///
  /// Returns the updated credit or a failure
  Future<Either<Failure, Credit>> call(UpdateCreditParams params) async {
    try {
      if (params.id.trim().isEmpty) {
        return const Left(ValidationFailure('El ID del crédito es requerido'));
      }

      final updateMap = params.toMap();
      if (updateMap.isEmpty) {
        return const Left(
            ValidationFailure('Debe proporcionar al menos un campo para actualizar'));
      }

      // Validate fields if provided
      if (params.clientId != null && params.clientId!.trim().isEmpty) {
        return const Left(
            ValidationFailure('El ID del cliente no puede estar vacío'));
      }

      if (params.description != null && params.description!.trim().isEmpty) {
        return const Left(ValidationFailure('La descripción no puede estar vacía'));
      }

      if (params.totalAmount != null && params.totalAmount! <= 0) {
        return const Left(
            ValidationFailure('El monto total debe ser mayor a cero'));
      }

      return await repository.updateCredit(params.id, updateMap);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al actualizar crédito: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

// ====================== ADD PAYMENT USE CASE ======================

/// Parameters for adding a payment to a credit
class AddPaymentParams {
  final String creditId;
  final double amount;
  final String? description;

  const AddPaymentParams({
    required this.creditId,
    required this.amount,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      if (description != null && description!.isNotEmpty)
        'description': description,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddPaymentParams &&
        other.creditId == creditId &&
        other.amount == amount &&
        other.description == description;
  }

  @override
  int get hashCode =>
      creditId.hashCode ^ amount.hashCode ^ description.hashCode;

  @override
  String toString() {
    return 'AddPaymentParams(creditId: $creditId, amount: $amount, description: $description)';
  }
}

/// Use case for adding a payment to a credit
class AddPaymentUseCase {
  final CreditsRepository repository;

  AddPaymentUseCase(this.repository);

  /// Execute the use case to add a payment to a credit
  ///
  /// [params] - Parameters containing the credit ID and payment information
  ///
  /// Returns the updated credit with new payment or a failure
  Future<Either<Failure, Credit>> call(AddPaymentParams params) async {
    try {
      if (params.creditId.trim().isEmpty) {
        return const Left(ValidationFailure('El ID del crédito es requerido'));
      }

      if (params.amount <= 0) {
        return const Left(ValidationFailure('El monto del pago debe ser mayor a cero'));
      }

      return await repository.addPayment(params.creditId, params.toMap());
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al agregar pago: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

// ====================== REMOVE PAYMENT USE CASE ======================

/// Parameters for removing a payment from a credit
class RemovePaymentParams {
  final String creditId;
  final String paymentId;

  const RemovePaymentParams({
    required this.creditId,
    required this.paymentId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RemovePaymentParams &&
        other.creditId == creditId &&
        other.paymentId == paymentId;
  }

  @override
  int get hashCode => creditId.hashCode ^ paymentId.hashCode;

  @override
  String toString() {
    return 'RemovePaymentParams(creditId: $creditId, paymentId: $paymentId)';
  }
}

/// Use case for removing a payment from a credit
class RemovePaymentUseCase {
  final CreditsRepository repository;

  RemovePaymentUseCase(this.repository);

  /// Execute the use case to remove a payment from a credit
  ///
  /// [params] - Parameters containing the credit ID and payment ID
  ///
  /// Returns the updated credit without the payment or a failure
  Future<Either<Failure, Credit>> call(RemovePaymentParams params) async {
    try {
      if (params.creditId.trim().isEmpty) {
        return const Left(ValidationFailure('El ID del crédito es requerido'));
      }

      if (params.paymentId.trim().isEmpty) {
        return const Left(ValidationFailure('El ID del pago es requerido'));
      }

      return await repository.removePayment(params.creditId, params.paymentId);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al eliminar pago: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

// ====================== DELETE CREDIT USE CASE ======================

/// Parameters for deleting a credit
class DeleteCreditParams {
  final String id;

  const DeleteCreditParams({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeleteCreditParams && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'DeleteCreditParams(id: $id)';
}

/// Use case for deleting a credit
class DeleteCreditUseCase {
  final CreditsRepository repository;

  DeleteCreditUseCase(this.repository);

  /// Execute the use case to delete a credit
  ///
  /// [params] - Parameters containing the credit ID
  ///
  /// Returns void or a failure
  Future<Either<Failure, void>> call(DeleteCreditParams params) async {
    try {
      if (params.id.trim().isEmpty) {
        return const Left(ValidationFailure('El ID del crédito es requerido'));
      }

      return await repository.deleteCredit(params.id);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al eliminar crédito: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

/// Parameters for getting pending credit by client
class GetPendingCreditByClientParams {
  final String clientId;

  const GetPendingCreditByClientParams({required this.clientId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetPendingCreditByClientParams && other.clientId == clientId;
  }

  @override
  int get hashCode => clientId.hashCode;

  @override
  String toString() => 'GetPendingCreditByClientParams(clientId: $clientId)';
}

/// Use case for getting pending credit by client
class GetPendingCreditByClientUseCase {
  final CreditsRepository repository;

  GetPendingCreditByClientUseCase(this.repository);

  /// Execute the use case to get pending credit by client
  ///
  /// [params] - Parameters containing the client ID
  ///
  /// Returns the pending credit or null if no pending credit exists
  Future<Either<Failure, Credit?>> call(
    GetPendingCreditByClientParams params,
  ) async {
    try {
      if (params.clientId.trim().isEmpty) {
        return const Left(
          ValidationFailure('El ID del cliente es requerido'),
        );
      }

      return await repository.getPendingCreditByClient(params.clientId);
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al obtener crédito pendiente: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}

/// Parameters for adding amount to credit
class AddAmountToCreditParams {
  final String creditId;
  final double amount;
  final String description;

  const AddAmountToCreditParams({
    required this.creditId,
    required this.amount,
    required this.description,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddAmountToCreditParams &&
        other.creditId == creditId &&
        other.amount == amount &&
        other.description == description;
  }

  @override
  int get hashCode =>
      creditId.hashCode ^ amount.hashCode ^ description.hashCode;

  @override
  String toString() =>
      'AddAmountToCreditParams(creditId: $creditId, amount: $amount, description: $description)';
}

/// Use case for adding amount to an existing credit
class AddAmountToCreditUseCase {
  final CreditsRepository repository;

  AddAmountToCreditUseCase(this.repository);

  /// Execute the use case to add amount to a credit
  ///
  /// [params] - Parameters containing the credit ID, amount, and description
  ///
  /// Returns the updated credit or a failure
  Future<Either<Failure, Credit>> call(AddAmountToCreditParams params) async {
    try {
      if (params.creditId.trim().isEmpty) {
        return const Left(ValidationFailure('El ID del crédito es requerido'));
      }

      if (params.amount <= 0) {
        return const Left(
          ValidationFailure('El monto debe ser mayor a cero'),
        );
      }

      if (params.description.trim().isEmpty) {
        return const Left(ValidationFailure('La descripción es requerida'));
      }

      return await repository.addAmountToCredit(
        params.creditId,
        params.amount,
        params.description,
      );
    } catch (e) {
      return Left(UnexpectedFailure(
        'Error inesperado al agregar monto: ${e.toString()}',
        exception: e is Exception ? e : Exception(e.toString()),
      ));
    }
  }
}
