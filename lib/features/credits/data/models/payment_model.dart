// lib/features/credits/data/models/payment_model.dart

import '../../domain/entities/payment.dart';

/// Payment model for data layer, extends Payment entity
class PaymentModel extends Payment {
  const PaymentModel({
    required super.id,
    required super.creditId,
    required super.amount,
    super.description,
    super.createdBy,
    super.deletedBy,
    required super.createdAt,
    super.deletedAt,
  });

  /// Create PaymentModel from JSON
  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    // Parse amount - handle both string and num
    double amount;
    if (json['amount'] is String) {
      amount = double.parse(json['amount'] as String);
    } else {
      amount = (json['amount'] as num).toDouble();
    }

    return PaymentModel(
      id: json['id'] as String,
      creditId: json['creditId'] as String? ?? json['credit_id'] as String,
      amount: amount,
      description: json['description'] as String?,
      createdBy: json['createdBy'] as String?,
      deletedBy: json['deletedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }

  /// Convert PaymentModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creditId': creditId,
      'amount': amount,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Convert PaymentModel to Payment entity
  Payment toEntity() {
    return Payment(
      id: id,
      creditId: creditId,
      amount: amount,
      description: description,
      createdBy: createdBy,
      deletedBy: deletedBy,
      createdAt: createdAt,
      deletedAt: deletedAt,
    );
  }

  /// Create PaymentModel from Payment entity
  factory PaymentModel.fromEntity(Payment payment) {
    return PaymentModel(
      id: payment.id,
      creditId: payment.creditId,
      amount: payment.amount,
      description: payment.description,
      createdBy: payment.createdBy,
      deletedBy: payment.deletedBy,
      createdAt: payment.createdAt,
      deletedAt: payment.deletedAt,
    );
  }
}
