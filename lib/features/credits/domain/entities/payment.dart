// lib/features/credits/domain/entities/payment.dart

import 'package:equatable/equatable.dart';

/// Payment entity representing a single payment made towards a credit
class Payment extends Equatable {
  final String id;
  final String creditId;
  final double amount;
  final String? description;
  final String? createdBy; // Username of admin who created this payment
  final String? deletedBy; // Username of admin who deleted this payment
  final DateTime createdAt;
  final DateTime? deletedAt;

  const Payment({
    required this.id,
    required this.creditId,
    required this.amount,
    this.description,
    this.createdBy,
    this.deletedBy,
    required this.createdAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props =>
      [id, creditId, amount, description, createdBy, deletedBy, createdAt, deletedAt];

  /// Create a copy of the payment with modified fields
  Payment copyWith({
    String? id,
    String? creditId,
    double? amount,
    String? description,
    String? createdBy,
    String? deletedBy,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      creditId: creditId ?? this.creditId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
