import '../../domain/entities/income.dart';

class IncomeModel extends Income {
  const IncomeModel({
    required super.id,
    required super.description,
    required super.amount,
    required super.createdById,
    super.createdBy,
    super.updatedBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory IncomeModel.fromJson(Map<String, dynamic> json) {
    try {
      double amount;
      if (json['amount'] is String) {
        amount = double.parse(json['amount'] as String);
      } else {
        amount = (json['amount'] as num).toDouble();
      }

      String? createdBy;
      if (json['createdBy'] != null) {
        if (json['createdBy'] is String) {
          createdBy = json['createdBy'] as String;
        } else if (json['createdBy'] is Map<String, dynamic>) {
          createdBy = (json['createdBy'] as Map<String, dynamic>)['username'] as String?;
        }
      }

      String? updatedBy;
      if (json['updatedBy'] != null) {
        if (json['updatedBy'] is String) {
          updatedBy = json['updatedBy'] as String;
        } else if (json['updatedBy'] is Map<String, dynamic>) {
          updatedBy = (json['updatedBy'] as Map<String, dynamic>)['username'] as String?;
        }
      }

      return IncomeModel(
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
      throw FormatException('Error parsing IncomeModel from JSON: $e\nJSON: $json');
    }
  }

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

  Income toEntity() {
    return Income(
      id: id, description: description, amount: amount,
      createdById: createdById, createdBy: createdBy, updatedBy: updatedBy,
      createdAt: createdAt, updatedAt: updatedAt,
    );
  }

  factory IncomeModel.fromEntity(Income income) {
    return IncomeModel(
      id: income.id, description: income.description, amount: income.amount,
      createdById: income.createdById, createdBy: income.createdBy, updatedBy: income.updatedBy,
      createdAt: income.createdAt, updatedAt: income.updatedAt,
    );
  }
}
