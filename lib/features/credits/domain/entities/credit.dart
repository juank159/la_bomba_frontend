// lib/features/credits/domain/entities/credit.dart

import 'package:equatable/equatable.dart';
import 'payment.dart';
import 'credit_transaction.dart';
import '../../../clients/domain/entities/client.dart';

/// Credit status enum
enum CreditStatus {
  pending,
  paid;

  String get displayName {
    switch (this) {
      case CreditStatus.pending:
        return 'Pendiente';
      case CreditStatus.paid:
        return 'Pagado';
    }
  }

  static CreditStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return CreditStatus.pending;
      case 'paid':
        return CreditStatus.paid;
      default:
        return CreditStatus.pending;
    }
  }
}

/// Credit entity representing a customer's credit/debt
class Credit extends Equatable {
  final String id;
  final String clientId;
  final Client client;
  final String description;
  final double totalAmount;
  final double paidAmount;
  final CreditStatus status;
  final List<Payment> payments;
  final List<CreditTransaction> transactions;
  final String? createdBy; // Username of admin who created this credit
  final String? updatedBy; // Username of admin who last updated
  final String? deletedBy; // Username of admin who deleted
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Credit({
    required this.id,
    required this.clientId,
    required this.client,
    required this.description,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    required this.payments,
    this.transactions = const [],
    this.createdBy,
    this.updatedBy,
    this.deletedBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  // Getter for convenience to access client name
  String get clientName => client.nombre;

  @override
  List<Object?> get props => [
        id,
        clientId,
        client,
        description,
        totalAmount,
        paidAmount,
        status,
        payments,
        transactions,
        createdBy,
        updatedBy,
        deletedBy,
        createdAt,
        updatedAt,
        deletedAt,
      ];

  /// Get remaining amount to be paid
  double get remainingAmount => totalAmount - paidAmount;

  /// Check if credit is fully paid
  bool get isPaid => status == CreditStatus.paid;

  /// Check if credit is still pending
  bool get isPending => status == CreditStatus.pending;

  /// Get payment progress as percentage (0.0 to 1.0)
  double get paymentProgress {
    if (totalAmount == 0) return 0.0;
    return paidAmount / totalAmount;
  }

  /// Get client initials for avatar
  String get clientInitials {
    final names = clientName.trim().split(' ');
    if (names.isEmpty) return '?';
    if (names.length == 1) {
      return names[0].substring(0, 1).toUpperCase();
    }
    return '${names[0].substring(0, 1)}${names[1].substring(0, 1)}'.toUpperCase();
  }

  /// Get formatted status text with color
  String get statusText => status.displayName;

  /// Create a copy of the credit with modified fields
  Credit copyWith({
    String? id,
    String? clientId,
    Client? client,
    String? description,
    double? totalAmount,
    double? paidAmount,
    CreditStatus? status,
    List<Payment>? payments,
    List<CreditTransaction>? transactions,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Credit(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      client: client ?? this.client,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      payments: payments ?? this.payments,
      transactions: transactions ?? this.transactions,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
