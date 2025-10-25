// lib/features/credits/domain/repositories/credits_repository.dart

import 'package:dartz/dartz.dart';

import '../../../../app/core/errors/failures.dart';
import '../entities/credit.dart';

/// Credits repository interface defining the contract for credits data operations
abstract class CreditsRepository {
  /// Get all credits
  ///
  /// Returns a list of credits or a failure
  Future<Either<Failure, List<Credit>>> getAllCredits();

  /// Get a specific credit by its ID with all payments
  ///
  /// [id] - The unique identifier of the credit
  ///
  /// Returns the credit with payment history or a failure
  Future<Either<Failure, Credit>> getCreditById(String id);

  /// Create a new credit
  ///
  /// [creditData] - Map containing the credit information
  /// Required fields: clientName, description, totalAmount
  ///
  /// Returns the created credit or a failure
  Future<Either<Failure, Credit>> createCredit(Map<String, dynamic> creditData);

  /// Update a credit's information
  ///
  /// [id] - The unique identifier of the credit to update
  /// [updatedData] - Map containing the fields to update
  ///
  /// Returns the updated credit or a failure
  Future<Either<Failure, Credit>> updateCredit(
    String id,
    Map<String, dynamic> updatedData,
  );

  /// Add a payment to a credit
  ///
  /// [creditId] - The unique identifier of the credit
  /// [paymentData] - Map containing the payment information (amount is required)
  ///
  /// Returns the updated credit with new payment or a failure
  Future<Either<Failure, Credit>> addPayment(
    String creditId,
    Map<String, dynamic> paymentData,
  );

  /// Remove a payment from a credit
  ///
  /// [creditId] - The unique identifier of the credit
  /// [paymentId] - The unique identifier of the payment to remove
  ///
  /// Returns the updated credit without the payment or a failure
  Future<Either<Failure, Credit>> removePayment(
    String creditId,
    String paymentId,
  );

  /// Delete a credit
  ///
  /// [id] - The unique identifier of the credit to delete
  ///
  /// Returns void or a failure
  Future<Either<Failure, void>> deleteCredit(String id);

  /// Get pending credit for a client
  ///
  /// [clientId] - The unique identifier of the client
  ///
  /// Returns the pending credit or null if no pending credit exists
  Future<Either<Failure, Credit?>> getPendingCreditByClient(String clientId);

  /// Add amount to an existing credit
  ///
  /// [creditId] - The unique identifier of the credit
  /// [amount] - The amount to add to the credit total
  /// [description] - Description of what the client is taking
  ///
  /// Returns the updated credit or a failure
  Future<Either<Failure, Credit>> addAmountToCredit(
    String creditId,
    double amount,
    String description,
  );
}
