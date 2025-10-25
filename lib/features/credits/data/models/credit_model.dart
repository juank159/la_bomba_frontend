// lib/features/credits/data/models/credit_model.dart

import '../../domain/entities/credit.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/credit_transaction.dart';
import '../../../clients/data/models/client_model.dart';
import 'payment_model.dart';
import 'credit_transaction_model.dart';

/// Credit model for data layer, extends Credit entity
class CreditModel extends Credit {
  const CreditModel({
    required super.id,
    required super.clientId,
    required super.client,
    required super.description,
    required super.totalAmount,
    required super.paidAmount,
    required super.status,
    required super.payments,
    super.transactions = const [],
    super.createdBy,
    super.updatedBy,
    super.deletedBy,
    required super.createdAt,
    required super.updatedAt,
    super.deletedAt,
  });

  /// Create CreditModel from JSON
  factory CreditModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse payments if available
      List<Payment> paymentsList = [];
      if (json['payments'] != null && json['payments'] is List) {
        paymentsList = (json['payments'] as List)
            .map((p) => PaymentModel.fromJson(p as Map<String, dynamic>))
            .toList();
      }

      // Parse transactions if available
      List<CreditTransaction> transactionsList = [];
      if (json['transactions'] != null && json['transactions'] is List) {
        transactionsList = (json['transactions'] as List)
            .map((t) => CreditTransactionModel.fromJson(t as Map<String, dynamic>))
            .toList();
      }

      // Parse client object - handle null case
      if (json['client'] == null) {
        throw FormatException('Client data is null for credit ${json['id']}');
      }

      final clientData = json['client'];
      if (clientData is! Map<String, dynamic>) {
        throw FormatException('Client data is not a valid Map for credit ${json['id']}');
      }

      final client = ClientModel.fromJson(clientData);

      // Parse totalAmount - handle both string and num
      double totalAmount;
      if (json['totalAmount'] is String) {
        totalAmount = double.parse(json['totalAmount'] as String);
      } else {
        totalAmount = (json['totalAmount'] as num).toDouble();
      }

      // Parse paidAmount - handle both string and num
      double paidAmount;
      if (json['paidAmount'] == null) {
        paidAmount = 0.0;
      } else if (json['paidAmount'] is String) {
        paidAmount = double.parse(json['paidAmount'] as String);
      } else {
        paidAmount = (json['paidAmount'] as num).toDouble();
      }

      return CreditModel(
        id: json['id'] as String,
        clientId: json['clientId'] as String,
        client: client,
        description: json['description'] as String,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        status: CreditStatus.fromString(json['status'] as String),
        payments: paymentsList,
        transactions: transactionsList,
        createdBy: json['createdBy'] as String?,
        updatedBy: json['updatedBy'] as String?,
        deletedBy: json['deletedBy'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'] as String)
            : null,
      );
    } catch (e) {
      throw FormatException('Error parsing CreditModel from JSON: $e\nJSON: $json');
    }
  }

  /// Convert CreditModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'description': description,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status.name,
      'payments': payments
          .map((p) => PaymentModel.fromEntity(p).toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert CreditModel to Credit entity
  Credit toEntity() {
    return Credit(
      id: id,
      clientId: clientId,
      client: client,
      description: description,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      status: status,
      payments: payments,
      createdBy: createdBy,
      updatedBy: updatedBy,
      deletedBy: deletedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }

  /// Create CreditModel from Credit entity
  factory CreditModel.fromEntity(Credit credit) {
    return CreditModel(
      id: credit.id,
      clientId: credit.clientId,
      client: credit.client,
      description: credit.description,
      totalAmount: credit.totalAmount,
      paidAmount: credit.paidAmount,
      status: credit.status,
      payments: credit.payments,
      createdBy: credit.createdBy,
      updatedBy: credit.updatedBy,
      deletedBy: credit.deletedBy,
      createdAt: credit.createdAt,
      updatedAt: credit.updatedAt,
      deletedAt: credit.deletedAt,
    );
  }
}
