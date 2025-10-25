// lib/features/expenses/data/models/expense_model.dart

import '../../domain/entities/expense.dart';

/// Expense model for data layer, extends Expense entity
class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.createdById,
    super.createdBy,
    super.updatedBy,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create ExpenseModel from JSON
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    try {
      // Parse amount - handle both string and num
      double amount;
      if (json['amount'] is String) {
        amount = double.parse(json['amount'] as String);
      } else {
        amount = (json['amount'] as num).toDouble();
      }

      // Parse createdBy - can be either a string or an object with username
      String? createdBy;
      if (json['createdBy'] != null) {
        if (json['createdBy'] is String) {
          createdBy = json['createdBy'] as String;
        } else if (json['createdBy'] is Map<String, dynamic>) {
          createdBy = (json['createdBy'] as Map<String, dynamic>)['username'] as String?;
        }
      }

      // Parse updatedBy - can be either a string or an object with username
      String? updatedBy;
      if (json['updatedBy'] != null) {
        if (json['updatedBy'] is String) {
          updatedBy = json['updatedBy'] as String;
        } else if (json['updatedBy'] is Map<String, dynamic>) {
          updatedBy = (json['updatedBy'] as Map<String, dynamic>)['username'] as String?;
        }
      }

      return ExpenseModel(
        id: json['id'] as String,
        description: json['description'] as String,
        amount: amount,
        createdById: json['createdById'] as String,
        createdBy: createdBy,
        updatedBy: updatedBy,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
    } catch (e) {
      throw FormatException(
        'Error parsing ExpenseModel from JSON: $e\nJSON: $json',
      );
    }
  }

  /// Convert ExpenseModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'createdById': createdById,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Convert ExpenseModel to Expense entity
  Expense toEntity() {
    return Expense(
      id: id,
      description: description,
      amount: amount,
      createdById: createdById,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create ExpenseModel from Expense entity
  factory ExpenseModel.fromEntity(Expense expense) {
    return ExpenseModel(
      id: expense.id,
      description: expense.description,
      amount: expense.amount,
      createdById: expense.createdById,
      createdBy: expense.createdBy,
      updatedBy: expense.updatedBy,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
    );
  }
}
