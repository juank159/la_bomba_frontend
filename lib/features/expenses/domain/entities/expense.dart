// lib/features/expenses/domain/entities/expense.dart

import 'package:equatable/equatable.dart';
import 'package:pedidos_frontend/features/auth/domain/entities/user.dart';

/// Expense entity - Domain layer
/// Represents an expense in the system
class Expense extends Equatable {
  final String id;
  final String description;
  final double amount;
  final String createdById;
  final String? createdBy; // Username who created
  final String? updatedBy; // Username who last updated
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.createdById,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get user name for display
  String get userName => createdBy ?? 'Usuario desconocido';

  /// Get formatted creation date
  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );

    if (expenseDate == today) {
      return 'Hoy';
    } else if (expenseDate == yesterday) {
      return 'Ayer';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  List<Object?> get props => [
    id,
    description,
    amount,
    createdById,
    createdBy,
    updatedBy,
    createdAt,
    updatedAt,
  ];

  /// Copy with method for immutability
  Expense copyWith({
    String? id,
    String? description,
    double? amount,
    String? createdById,
    String? createdBy,
    String? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      createdById: createdById ?? this.createdById,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
