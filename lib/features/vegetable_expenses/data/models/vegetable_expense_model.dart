// lib/features/vegetable_expenses/data/models/vegetable_expense_model.dart

import '../../domain/entities/vegetable_expense.dart';

class VegetableExpenseModel extends VegetableExpense {
  const VegetableExpenseModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.fundingSource,
    super.cashSessionId,
    required super.createdById,
    super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory VegetableExpenseModel.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'] is String ? double.parse(json['amount'] as String) : (json['amount'] as num).toDouble();

    String? createdBy;
    final rawCreatedBy = json['createdBy'];
    if (rawCreatedBy is String) {
      createdBy = rawCreatedBy;
    } else if (rawCreatedBy is Map<String, dynamic>) {
      createdBy = rawCreatedBy['username'] as String?;
    }

    return VegetableExpenseModel(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: amount,
      fundingSource: ExpenseFundingSource.fromString(json['fundingSource'] as String? ?? 'external'),
      cashSessionId: json['cashSessionId'] as String?,
      createdById: json['createdById'] as String,
      createdBy: createdBy,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  VegetableExpense toEntity() {
    return VegetableExpense(
      id: id,
      description: description,
      amount: amount,
      fundingSource: fundingSource,
      cashSessionId: cashSessionId,
      createdById: createdById,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
