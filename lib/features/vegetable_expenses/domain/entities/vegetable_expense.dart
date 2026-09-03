// lib/features/vegetable_expenses/domain/entities/vegetable_expense.dart

import 'package:equatable/equatable.dart';

/// Where the money for the expense came from: CAJA deducts it from the
/// currently open cash session's expected cash (there must be one open);
/// EXTERNAL is money that never passed through the register's cash.
enum ExpenseFundingSource {
  caja('caja'),
  external('external');

  const ExpenseFundingSource(this.value);
  final String value;

  static ExpenseFundingSource fromString(String value) {
    return value == 'caja' ? ExpenseFundingSource.caja : ExpenseFundingSource.external;
  }

  String get label => this == ExpenseFundingSource.caja ? 'Caja' : 'Dinero externo';
}

/// Operating expense for the vegetables stand (bags, ice, transport,
/// etc.) - deliberately separate from the app's general Expense entity,
/// with its own backend table, so the two accountings never mix. Buying
/// produce to resell is NOT an expense: that's a VegetablePurchase, which
/// also moves inventory.
class VegetableExpense extends Equatable {
  final String id;
  final String description;
  final double amount;
  final ExpenseFundingSource fundingSource;
  final String? cashSessionId;
  final String createdById;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VegetableExpense({
    required this.id,
    required this.description,
    required this.amount,
    required this.fundingSource,
    this.cashSessionId,
    required this.createdById,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  String get userName => createdBy ?? 'Usuario desconocido';

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (expenseDate == today) return 'Hoy';
    if (expenseDate == yesterday) return 'Ayer';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  @override
  List<Object?> get props => [
        id,
        description,
        amount,
        fundingSource,
        cashSessionId,
        createdById,
        createdBy,
        createdAt,
        updatedAt,
      ];

  VegetableExpense copyWith({
    String? id,
    String? description,
    double? amount,
    ExpenseFundingSource? fundingSource,
    String? cashSessionId,
    String? createdById,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VegetableExpense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      fundingSource: fundingSource ?? this.fundingSource,
      cashSessionId: cashSessionId ?? this.cashSessionId,
      createdById: createdById ?? this.createdById,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
